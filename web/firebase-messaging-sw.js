/* Chỉ dùng khi đã cấu hình Firebase thật. Không đưa khóa Admin SDK vào đây. */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');
importScripts('./firebase-web-config.js');
if (self.BEEHOME_FIREBASE_CONFIG && self.BEEHOME_FIREBASE_CONFIG.projectId) {
 firebase.initializeApp(self.BEEHOME_FIREBASE_CONFIG);
 firebase.messaging();
}
