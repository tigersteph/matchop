const CACHE_NAME = 'matchop-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/assets/AssetManifest.json',
  '/assets/FontManifest.json',
  '/assets/NOTICES',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  '/assets/shaders/ink_sparkle.frag',
  '/assets/AssetManifest.bin',
  '/assets/kernel_blob.bin',
  '/assets/splash/style.css',
  '/assets/splash/img/light-2x.png',
  '/assets/splash/img/light.png',
  '/assets/splash/img/dark-2x.png',
  '/assets/splash/img/dark.png',
  '/manifest.json',
  '/icons/icon-192.png',
  '/icons/icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});

// Gestion des liens profonds
self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'deep_link') {
    // Traiter le lien profond ici
    console.log('Received deep link in service worker:', event.data.url);
    // Rediriger vers l'application
    event.waitUntil(
      clients.matchAll({ type: 'window' }).then(clients => {
        if (clients && clients.length > 0) {
          clients[0].navigate(event.data.url);
        }
      })
    );
  }
});
