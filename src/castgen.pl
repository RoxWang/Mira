#!/usr/bin/perl
#
# 生成 Mira 的播放页副本。
#
# 用法： castgen.pl <模板页 view.html> <当前视频路径> <输出文件>
#
# 干四件事：
#   1. 扫当前视频所在文件夹，把同目录所有视频按名字排序 → 播放列表
#   2. 给每个视频找同名字幕（.dual.srt / .zh-Hans.srt / .srt / .en.srt），
#      把内容直接嵌进页面 —— 因为 file:// 页面没有权限去读旁边的文件，
#      只有启动脚本读得到，所以在这里一次读好塞进去
#   3. 把「当前视频 + 列表」写进模板页的 <!--CAST--> 位置，输出副本
#
# 全程只读，不改任何原始文件。
#
# ⚠️ macOS 隐私权限（TCC）：Mira 是个有 bundle id 的 app，系统默认不让它列
#    Downloads / Documents / Desktop 里的东西 —— 实测同一个脚本在 ~/Movies 列得出
#    42 条，在 ~/Downloads 列得 0 条。这是苹果的规矩，不是 bug。
#    列不出来也不报错：退化成「只有这一部」，页面照样能直接播，
#    并且告诉用户去哪里点一下开关（见 Resources/Scripts/main.scpt）。

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);   # 给每部片的重封装产物算一个独立目录名

my ($page, $video, $out) = @ARGV;
die "usage: castgen.pl <page> <video> <out>\n" unless defined $page && defined $video && defined $out;

my $html = '';
if (open(my $fh, '<:raw', $page)) { local $/; $html = <$fh>; close $fh; }
die "cannot read page\n" unless length $html;

my $marker = '<!--CAST-->';
my $pos = index($html, $marker);
die "marker not found\n" if $pos < 0;

# ── 当前视频所在目录 ──
(my $dir = $video) =~ s{/[^/]+$}{};
$dir = '.' unless $dir ne '';

sub jesc {
    my $s = shift;
    return '' unless defined $s;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/</\\u003c/g;
    $s =~ s/>/\\u003e/g;
    $s =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f]//g;
    return $s;
}

sub uesc {
    my $s = shift;
    $s =~ s/([^A-Za-z0-9_.~\/])/sprintf('%%%02X', ord($1))/ge;
    return $s;
}

sub udec {
    my $s = shift;
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $s;
}

sub dstr {
    my $s = int(shift);
    return '' if $s <= 0;
    my $h = int($s / 3600);
    my $m = int(($s % 3600) / 60);
    return $h ? sprintf('%d:%02d:%02d', $h, $m, $s % 60)
              : sprintf('%d:%02d', $m, $s % 60);
}

my $VIDRE = qr/\.(?:mp4|m4v|mov|mkv|webm|avi|ts|m2ts|mts|flv|wmv|asf|mpg|mpeg|mpe|vob|rm|rmvb|3gp|3g2|ogv|ogg|divx|f4v|m4a|mp3|flac|wav|aac|ac3|opus)$/i;

# Chrome（也就是 Mira 底下那层）认的容器。不在名单里的就要重封装。
# 注意：这是**换盒子不是转码**，音画质 100% 不动，一个 47 分钟的片子一两秒就好。
my %OKCT = map { $_ => 1 } qw(mp4 m4v mov mkv webm ogv ogg 3gp 3g2 m4a mp3 flac wav aac opus);

# Chrome 认的视频编码。认不了的话换盒子也没用，那种只能真转码。
my %OKVC = map { lc($_) => 1 } qw(h264 avc avc1 vp8 vp9 av01 av1 hevc hvc1 hev1 mpeg4 mpeg4p2 theora);

# ── 1. 直接读目录：有权限时最快，几十毫秒 ──
sub listByOpendir {
    my ($d) = @_;
    my @f = ();
    if (opendir(my $dh, $d)) {
        @f = sort grep { /$VIDRE/ && -f "$d/$_" } readdir($dh);
        closedir($dh);
    }
    return @f;
}

my @files = listByOpendir($dir);
my $blocked = 0;
if (!@files) {
    # 目录列不出来：把这个视频自己放进去，页面起码能直接播，
    # 并打上 blocked 标记 —— 页面据此告诉用户去哪里开权限
    $blocked = 1;
    (my $n = $video) =~ s{.*/}{};
    @files = ($n) if $n =~ /$VIDRE/;
}
splice(@files, 400) if @files > 400;      # 文件夹再大也不做无限列表

# ── 每集时长 ──
# 走 Spotlight 的元数据（mdls），一次调用把整个文件夹问完，几十毫秒就回来。
# 拿不到（没索引 / 被隐私权限挡住）就留空，列表里那格不显示，不影响别的。
my @dur = ('') x scalar(@files);
if (!$blocked) {
    my @paths = map { "$dir/$_" } @files;
    my $raw = '';
    if (open(my $mh, '-|', '/usr/bin/mdls', '-name', 'kMDItemDurationSeconds', '-raw', @paths)) {
        local $/;
        $raw = <$mh>;
        close $mh;
    }
    if (defined $raw && length $raw) {
        my @vals = split /\x00/, $raw, -1;
        # 数量对不上就整体放弃 —— 错位比没有更糟（会把第 3 集的时长贴到第 4 集头上）
        @vals = () unless @vals == @files || @vals == @files + 1;
        for my $i (0 .. $#files) {
            my $s = defined $vals[$i] ? $vals[$i] : '';
            next unless $s =~ /^([0-9]+(?:\.[0-9]+)?)$/;
            $dur[$i] = dstr($1 + 0);
        }
    }
}

my $SUB_ONE  = 300 * 1024;               # 单个字幕上限 300 KB
my $SUB_ALL  = 6 * 1024 * 1024;          # 所有字幕加起来上限 6 MB
my $subTotal = 0;
my @items;

for my $i (0 .. $#files) {
    my $name = $files[$i];
    my $path = "$dir/$name";
    (my $base = $path) =~ s/\.[^.\/]+$//;

    # ── 字幕：每个视频最多挂两条 —— 主字幕 + 辅字幕（跟 IINA 一样的两条轨）──
    #    以前这里只取第一条就 last 了，于是辅字幕永远是空的，
    #    用户只能手动再载入一次 —— 那不叫"主辅双字幕"。
    #    顺序按中文用户的习惯排：双语 → 简中 → 同名 → 英文 → vtt/ass/ssa。
    #    取到第一条当主，第二条当辅。
    my (@subTxt, @subName);
    for my $cand ("$base.dual.srt", "$base.zh-Hans.srt", "$base.zh.srt", "$base.srt",
                  "$base.en.srt", "$base.eng.srt", "$base.vtt", "$base.ass", "$base.ssa") {
        last if @subTxt >= 2;
        next unless -f $cand;
        my $sz = -s $cand;
        next if !defined $sz || $sz <= 0 || $sz > $SUB_ONE || $subTotal + $sz > $SUB_ALL;
        my $txt = '';
        if (open(my $sh, '<:raw', $cand)) { local $/; $txt = <$sh>; close $sh; }
        next unless length $txt;
        $txt =~ s/\r//g;
        push @subTxt, jesc($txt);
        my $nm = $cand;
        $nm =~ s{.*/}{};                      # 字幕轨在列表里显示它自己的文件名
        $nm =~ s/\.(?:srt|vtt|ass|ssa)$//i;   # 只脱掉扩展名，语言标记留着（X.en / X.zh-Hans）
        push @subName, $nm;
        $subTotal += $sz;
    }
    my $sub  = defined $subTxt[0]  ? $subTxt[0]  : '';
    my $sn   = defined $subName[0] ? $subName[0] : '';
    my $sub2 = defined $subTxt[1]  ? $subTxt[1]  : '';
    my $sn2  = defined $subName[1] ? $subName[1] : '';

    push @items, '{"u":"file://' . uesc($path) . '","n":"' . jesc($name) . '","s":"' . $sub
               . '","sn":"' . jesc($sn) . '","s2":"' . $sub2
               . '","sn2":"' . jesc($sn2) . '","d":"' . (defined $dur[$i] ? $dur[$i] : '') . '"}';
}

my $json = '[' . join(',', @items) . ']';
my $cur  = 'file://' . uesc($video);

# ── 媒体信息（分辨率 / 编码 / 帧率 / 音轨 / 体积 / 时长）──
# ffmpeg 只解个文件头就退出，47 分钟的片子实测 0.05 秒，几乎白送。
# 读不到（ffmpeg 不在 / 格式不认 / 被隐私权限挡住）就给 null，那一栏显示一条横线。
my $INFO = 'null';
my $VCODEC = '';
{
    my $ff = '';
    for my $c ('/Users/roxwang/.local/bin/ffmpeg', '/opt/homebrew/bin/ffmpeg', '/usr/local/bin/ffmpeg') {
        if (-x $c) { $ff = $c; last; }
    }
    if ($ff ne '') {
        my $q = $video;
        $q =~ s/'/'\\''/g;                       # 路径里有单引号也不会把 shell 搞崩
        my $raw = '';
        if (open(my $ih, '-|', '/bin/sh', '-c', "$ff -hide_banner -i '$q' 2>&1 </dev/null")) {
            local $/;
            $raw = <$ih>;
            close $ih;
        }
        $raw = '' unless defined $raw;
        my ($vc, $w, $h, $fps, $ac, $sr, $ch) = ('', '', '', '', '', '', '');
        $vc  = $1 if $raw =~ /Video:\s*([A-Za-z0-9_]+)/;
        $VCODEC = lc($vc);
        ($w, $h) = ($1, $2) if $raw =~ /Video:.*?,\s*(\d{2,5})x(\d{2,5})/;
        $fps = $1 if $raw =~ /([\d.]+)\s*fps/;
        $ac  = $1 if $raw =~ /Audio:\s*([A-Za-z0-9_]+)/;
        $sr  = $1 if $raw =~ /Audio:.*?,\s*(\d+)\s*Hz/i;
        $ch  = $1 if $raw =~ /Audio:.*?Hz,\s*([A-Za-z0-9. ]+?)\s*,/i;

        my $durS = '';
        $durS = sprintf('%d:%02d', $2 + $1 * 60, $3) if $raw =~ /Duration:\s*(\d+):(\d+):(\d+)/;

        my $sz = -s $video;
        my $size = '';
        if (defined $sz && $sz > 0) {
            $size = ($sz >= 1073741824) ? sprintf('%.1f GB', $sz / 1073741824)
                                        : sprintf('%.0f MB', $sz / 1048576);
        }
        my $srF = ($sr =~ /^\d+$/ && $sr >= 1000) ? sprintf('%.1f kHz', $sr / 1000) : $sr;
        $ch = ucfirst(lc($ch)) if defined $ch && $ch =~ /^(mono|stereo)$/i;

        if ($w ne '' || $ac ne '' || $size ne '') {
            $INFO = '{"vc":"' . jesc($vc) . '","w":"' . jesc($w) . '","h":"' . jesc($h)
                  . '","fps":"' . jesc($fps) . '","ac":"' . jesc($ac) . '","sr":"' . jesc($srF)
                  . '","ch":"' . jesc($ch) . '","size":"' . jesc($size) . '","dur":"' . jesc($durS) . '"}';
        }
    }
}

# ── 重封装：Chrome 不认这个盒子（TS / AVI / WMV / FLV…）就换个 MP4 的盒子 ──
# -c copy = 音视频原样搬过去，**不重新编码**，画质音质一点不掉
# 产物放在 $TMPDIR 里，永远只有一个，重启自动清
sub ctOf { my $f = shift; return lc($1) if $f =~ /\.([^.\/]+)$/; return ''; }

sub remux {
    my ($src, $outdir) = @_;
    my $ff = '';
    for my $c ('/Users/roxwang/.local/bin/ffmpeg', '/opt/homebrew/bin/ffmpeg', '/usr/local/bin/ffmpeg') {
        if (-x $c) { $ff = $c; last; }
    }
    return '' unless $ff ne '';

    my $sz = -s $src;
    return '' if !defined $sz || $sz <= 0 || $sz > 3221225472;   # 超过 3 GB 就不折腾硬盘

    # 只清自己的产物，别把整个 remux 目录端掉：
    # 以前所有 TS 共用 $TMPDIR/Mira/remux/remux.mp4，先后开两部会互相覆盖，
    # 前一个窗口刷新就被拽到后一部 —— 每部片一个独立子目录就没这事了。
    system('/bin/mkdir', '-p', $outdir);
    system('/bin/rm', '-f', $outdir . '/remux.mp4');
    my $dst = $outdir . '/remux.mp4';

    my $q = $src;  $q =~ s/'/'\\''/g;
    my $d = $dst;  $d =~ s/'/'\\''/g;
    # 字幕搬不过 MP4 就丢掉，别让整条命令失败（画面声音才是主体）
    system('/bin/sh', '-c',
        "$ff -nostdin -hide_banner -loglevel error -y -i '$q' -map 0:v:0 -map 0:a:0? "
      . "-c:v copy -c:a copy -movflags +faststart '$d' </dev/null 2>/dev/null");
    return (-s $dst) ? $dst : '';
}

if (!$blocked) {
    my $ct = ctOf($video);
    # 编码本身 Chrome 也不认（MPEG-2 / VC-1 这类）→ 换盒子没意义，别浪费时间
    if ($ct ne '' && !$OKCT{$ct} && ($VCODEC eq '' || $OKVC{$VCODEC})) {
        # 路径做 hash：同一部片重复开复用同一份，不同片互不干扰。$TMPDIR 重启自动清。
        my $dirOut = ($ENV{TMPDIR} || '/tmp') . '/Mira/remux/' . substr(md5_hex($video), 0, 12);
        my $r = remux($video, $dirOut);
        if ($r ne '') { $cur = 'file://' . uesc($r); }
    }
}
# 换盒子也救不了的（比如 MPEG-2 / VC-1 这种 Chrome 根本没带解码器）：
# 就还是给它原始文件，页面会明确提示"这个格式放不了"，不装作能播。

# 抽屉表头上显示文件夹名
if ($blocked) { print "BLOCKED\n"; }

my $folder = $dir;
$folder =~ s{/+$}{};
$folder =~ s{.*/}{};

my $inject = '<script>window.__CAST__="' . $cur . '";window.__CAST_LIST__=' . $json
           . ';window.__CAST_BLOCKED__=' . $blocked . ';window.__CAST_FOLDER__="' . jesc($folder) . '";window.__CAST_INFO__=' . $INFO
           . ';window.CAST_BOOT&&window.CAST_BOOT();</'
           . 'script>';

substr($html, $pos, length($marker), $inject);

open(my $ofh, '>:raw', $out) or die "cannot write out\n";
print $ofh $html;
close $ofh;

exit 0;
