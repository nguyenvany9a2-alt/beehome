'use strict';
// Run from the Flutter project root after registering its web app with FCM.
const fs = require('node:fs');
const path = require('node:path');
const mapping = {
  apiKey:'FIREBASE_API_KEY', authDomain:'FIREBASE_AUTH_DOMAIN', projectId:'FIREBASE_PROJECT_ID',
  messagingSenderId:'FIREBASE_SENDER_ID', appId:'FIREBASE_APP_ID'
};
try {
  const config=JSON.parse(fs.readFileSync(process.argv[2] || 'firebase.local.json','utf8').replace(/^\uFEFF/,''));
  const web={};
  for (const [field,key] of Object.entries(mapping)) {
    if (typeof config[key] !== 'string' || !config[key].trim()) throw Error('Thiếu '+key);
    web[field]=config[key];
  }
  if (!config.FIREBASE_VAPID_KEY) throw Error('Thiếu FIREBASE_VAPID_KEY');
  fs.writeFileSync(path.join('web','firebase-web-config.js'),'self.BEEHOME_FIREBASE_CONFIG = '+JSON.stringify(web,null,2)+';\n');
  console.log('Đã tạo cấu hình web push cho '+web.projectId+'.');
} catch (e) {
  console.error('Chưa tạo cấu hình web push. '+e.message);
  process.exitCode=1;
}
