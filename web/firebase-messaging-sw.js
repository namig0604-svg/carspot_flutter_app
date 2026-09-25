// Service worker для фоновых push-уведомлений в веб-версии CarSpot.
// Обязателен для firebase_messaging на Flutter Web — без него браузер
// не сможет получать пуши, когда вкладка/сайт закрыты или свёрнуты.
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyASVEsHYn590RQichZ2-BSuHRtFWqWU4lo",
  authDomain: "carspot-35d67.firebaseapp.com",
  projectId: "carspot-35d67",
  storageBucket: "carspot-35d67.firebasestorage.app",
  messagingSenderId: "489726420615",
  appId: "1:489726420615:web:503749023aed4604f57a22",
});

const messaging = firebase.messaging();
