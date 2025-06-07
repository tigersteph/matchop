// Firebase configuration
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID",
  measurementId: "YOUR_MEASUREMENT_ID"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
// Initialize Analytics
firebase.analytics();

// Initialize Dynamic Links
firebase.dynamicLinks().createDynamicLink({
  link: 'https://matchop.page.link',
  domainUriPrefix: 'https://matchop.page.link'
}).then(function(dynamicLink) {
  console.log('Dynamic link created:', dynamicLink.url);
});
