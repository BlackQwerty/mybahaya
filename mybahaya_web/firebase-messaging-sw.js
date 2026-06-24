/* ============================================================
   firebase-messaging-sw.js — Service Worker for Web Push
   Must live at the ROOT of the web domain (same level as index/login.html).
   Handles background push notifications when the browser tab is closed.
   ============================================================ */

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'AIzaSyCw63F4hFRDHGAXhhAlZJ-cT8M643MSisw',
  authDomain:        'mybahaya-fyp.firebaseapp.com',
  projectId:         'mybahaya-fyp',
  storageBucket:     'mybahaya-fyp.firebasestorage.app',
  messagingSenderId: '491193659854',
  appId:             '1:491193659854:web:dfd34cbfb22ba66458bb9f',
});

const messaging = firebase.messaging();

// Called when push arrives and the browser tab is closed/in background.
// Firebase shows the notification automatically; we customise icon + badge.
messaging.onBackgroundMessage((payload) => {
  const { title = 'MyBahaya', body = '' } = payload.notification || {};
  self.registration.showNotification(title, {
    body,
    icon:  '/assets/images/logos/logo.png',
    badge: '/assets/images/logos/logo.png',
    data:  payload.data || {},
  });
});
