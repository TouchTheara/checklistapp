// Firebase Messaging service worker
// Generated to support web push notifications.

importScripts('https://www.gstatic.com/firebasejs/10.12.3/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.3/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBDfuTZF_LnkNUFZhUORM9XpX8IblFrhY4',
  appId: '1:902773632002:web:b3b28ff41997a79bdc0b1b',
  messagingSenderId: '902773632002',
  projectId: 'safelist-5b99d',
  authDomain: 'safelist-5b99d.firebaseapp.com',
  storageBucket: 'safelist-5b99d.firebasestorage.app',
  measurementId: 'G-4XJQ6KLHDT',
});

const messaging = firebase.messaging();

// Handle background messages.
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title ?? 'Notification';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
