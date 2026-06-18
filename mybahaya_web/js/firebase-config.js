/* ============================================================
   firebase-config.js — Firebase Initialization (Web SDK compat)
   ============================================================ */

const firebaseConfig = {
  apiKey:            'AIzaSyCw63F4hFRDHGAXhhAlZJ-cT8M643MSisw',
  authDomain:        'mybahaya-fyp.firebaseapp.com',
  projectId:         'mybahaya-fyp',
  storageBucket:     'mybahaya-fyp.firebasestorage.app',
  messagingSenderId: '491193659854',
  appId:             '1:491193659854:web:dfd34cbfb22ba66458bb9f'
};

firebase.initializeApp(firebaseConfig);

const db   = firebase.firestore();
const auth = firebase.auth();
