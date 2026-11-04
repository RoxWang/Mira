/* Mira 的离线缓存。
   它只干一件事：把这张页面本身存一份，断网也打得开。
   视频不缓存 —— 视频从来就在你硬盘上，没经过网络。
   设置和播放进度存在浏览器本地（localStorage），跟这里无关。

   ⚠️ 策略必须是「网络优先」，不能反过来。
      缓存优先会出现「我改好了，用户还看到旧版」—— 那是最难查的一类 bug。
      网络优先 = 有网永远拿线上最新那份，只有断网才回落到存下来的旧那份。 */

var CACHE = 'mira-shell-v1';
var SHELL = ['./', './index.html'];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE)
      .then(function (c) { return c.addAll(SHELL); })
      .then(function () { return self.skipWaiting(); })
      .catch(function () {})
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys()
      .then(function (keys) {
        return Promise.all(keys.filter(function (k) { return k !== CACHE; })
                               .map(function (k) { return caches.delete(k); }));
      })
      .then(function () { return self.clients.claim(); })
      .catch(function () {})
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url;
  try { url = new URL(req.url); } catch (err) { return; }
  if (url.origin !== self.location.origin) return;   /* 外站一律不管 */

  e.respondWith(
    fetch(req).then(function (res) {
      if (res && res.ok) {
        var copy = res.clone();
        caches.open(CACHE).then(function (c) { c.put(req, copy); }).catch(function () {});
      }
      return res;
    }).catch(function () {
      return caches.match(req).then(function (hit) {
        return hit || caches.match('./index.html');
      });
    })
  );
});
