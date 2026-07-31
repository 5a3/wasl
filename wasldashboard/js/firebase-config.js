// Firebase Web SDK v10 Modular Import Configuration
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import { 
  getFirestore, 
  collection, 
  doc, 
  getDocs, 
  getDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  query, 
  where, 
  orderBy, 
  limit,
  onSnapshot, 
  serverTimestamp,
  Timestamp 
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';
import { 
  getStorage, 
  ref, 
  uploadBytes, 
  getDownloadURL 
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-storage.js';

// Wasl Firebase Project Configuration
const firebaseConfig = {
  apiKey: "AIzaSyCBk4Tz6kWfgONBAHeYLQWlWfXqugLzvWY",
  authDomain: "wasl-cdcb6.firebaseapp.com",
  projectId: "wasl-cdcb6",
  storageBucket: "wasl-cdcb6.firebasestorage.app",
  messagingSenderId: "317958059758",
  appId: "1:317958059758:web:c5a1278921f05b92bca5ff",
  measurementId: "G-1GLZ07ETRY"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const storage = getStorage(app);

export { 
  app, 
  db, 
  storage, 
  collection, 
  doc, 
  getDocs, 
  getDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  query, 
  where, 
  orderBy, 
  limit,
  onSnapshot, 
  serverTimestamp,
  Timestamp,
  ref,
  uploadBytes,
  getDownloadURL
};
