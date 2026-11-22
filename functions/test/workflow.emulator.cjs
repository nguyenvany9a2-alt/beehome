'use strict';

const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const test = require('node:test');

// Integration contract: every workflow write below uses an end-user ID token.
// The Admin SDK is restricted to provisioning a test operator on the emulator.
const project = process.env.GCLOUD_PROJECT || 'demo-beehome-refit';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const dbHost = process.env.FIRESTORE_EMULATOR_HOST;
const local = host => /^127\.0\.0\.1:\d+$/.test(host || '');
const enabled = project.startsWith('demo-') && local(authHost) && local(dbHost);

test('BeeHome • quyền, địa chỉ, nhận việc đồng thời, COD và đánh giá', {skip: !enabled}, async t => {
  const { initializeApp, deleteApp } = require('firebase-admin/app');
  const { getAuth } = require('firebase-admin/auth');
  const app = initializeApp({projectId: project}, randomUUID());
  t.after(() => deleteApp(app));
  const root = 'projects/'+project+'/databases/(default)/documents';
  const api = 'http://'+dbHost+'/v1/'+root;
  const prefix = randomUUID().slice(0,8);
  const pass = randomUUID();
  async function callAuth(action, data) {
    const res = await fetch('http://'+authHost+'/identitytoolkit.googleapis.com/v1/accounts:'+action+'?key=test',
      {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...data,returnSecureToken:true})});
    const result = await res.json();
    assert.equal(res.status,200,JSON.stringify(result.error));
    return result;
  }
  async function signup(name) {
    const email = name+'-'+prefix+'@example.invalid';
    const res = await callAuth('signUp',{email,password:pass});
    return {name,email,uid:res.localId,token:res.idToken};
  }
  function value(v) {
    if(v===null) return {nullValue:null};
    if(v instanceof Date) return {timestampValue:v.toISOString()};
    if(Array.isArray(v)) return {arrayValue:{values:v.map(value)}};
    if(typeof v==='object') return {mapValue:{fields:fields(v)}};
    if(typeof v==='boolean') return {booleanValue:v};
    if(typeof v==='number') return Number.isInteger(v)?{integerValue:String(v)}:{doubleValue:v};
    return {stringValue:v};
  }
  function fields(d) {return Object.fromEntries(Object.entries(d).map(([k,v])=>[k,value(v)]));}
  function put(path,d,patch=false) {
    const w={update:{name:root+'/'+path,fields:fields(d)}};
    if(patch) w.updateMask={fieldPaths:Object.keys(d)};
    return w;
  }
  const del = path=>({delete:root+'/'+path});
  async function commit(person,writes,want=200) {
    const r=await fetch(api+':commit',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+person.token},body:JSON.stringify({writes})});
    const result=await r.json();
    if(want!==null) assert.equal(r.status,want, JSON.stringify(result.error));
    return r.status;
  }
  async function read(person,path,status) {
    const r=await fetch(api+'/'+path,{headers:person?{Authorization:'Bearer '+person.token}:{}});
    assert.equal(r.status,status,path+' '+r.status);
    return r.json();
  }
  async function query(person, collection, field, arg) {
    const structuredQuery={from:[{collectionId:collection}]};
    if(field) structuredQuery.where={fieldFilter:{field:{fieldPath:field},op:'EQUAL',
      value:field==='__name__'?{referenceValue:root+'/'+collection+'/'+arg}:value(arg)}};
    const headers={'Content-Type':'application/json'};
    if(person)headers.Authorization='Bearer '+person.token;
    const r=await fetch(api+':runQuery',{method:'POST',headers,body:JSON.stringify({structuredQuery})});
    const result=await r.json();
    assert.equal(r.status,200,collection+' '+JSON.stringify(result.error));
  }
  const profile = (p,role)=>({name:p.name,email:p.email,phone:'0900000000',role,status:'active',avatarUrl:'',createdAt:new Date().toISOString()});
  const workerProfile = p=>({name:p.name,skills:'',area:'TP. Hồ Chí Minh',experience:'',bio:'',approval:'pending',reason:'',rating:0,reviewCount:0});
  const [c,a,w,v] = await Promise.all(['customer','staff','worker1','worker2'].map(signup));
  await commit(a,[put('users/'+a.uid,profile(a,'customer'))]);
  await getAuth(app).setCustomUserClaims(a.uid,{role:'admin'});
  a.token=(await callAuth('signInWithPassword',{email:a.email,password:pass})).idToken;
  await commit(c,[put('users/'+c.uid,profile(c,'customer'))]);
  for(const p of [w,v]) {
    await commit(p,[put('users/'+p.uid,profile(p,'worker')),put('worker_profiles/'+p.uid,workerProfile(p))]);
  }
  const svc='test-'+prefix;
  await commit(a,[put('services/'+svc,{name:'Vệ sinh theo lịch',active:true,unit:'giờ',price:80000,duration:2,category:'Dọn nhà'})]);
  await read(null,'services/'+svc,200);
  await query(null,'services','active',true);
  for(const p of [c,w,a]){
    await query(p,'users',p===a?null:'__name__',p.uid);
    await query(p,'worker_profiles',p===a?null:p===w?'__name__':'approval',p===w?p.uid:'approved');
    for(const col of ['orders','payments','reviews']) await query(p,col,p===a?null:p===w?'workerId':'customerId',p.uid);
    await query(p,'notifications','userId',p.uid);
    await query(p,'rating_totals');
  }
  await query(c,'addresses','userId',c.uid);
  await commit(c,[put('users/'+c.uid,{role:'admin'},true)],403);
  await commit(c,[put('users/'+c.uid,{appearance:{scene:'corner',tint:'sage',scale:1.15,still:true}},true)]);
  const book='users/'+c.uid+'/settings/addressBook', addr='a-'+prefix, addr2='b-'+prefix;
  const address={userId:c.uid,label:'Nhà',contact:'Khách',phone:'0900000000',detail:'Địa chỉ kiểm thử',area:'TP. Hồ Chí Minh',note:'',default:true};
  await commit(c,[put('addresses/'+addr,address),put(book,{ids:[addr],defaultId:addr})]);
  await commit(c,[put('addresses/'+addr,{default:false},true),put('addresses/'+addr2,address),put(book,{ids:[addr,addr2],defaultId:addr2})]);
  await commit(c,[del('addresses/'+addr2),put('addresses/'+addr,{default:true},true),put(book,{ids:[addr],defaultId:addr})]);
  await read(w,'addresses/'+addr,403);
  const nextDay=new Date(Date.now()+86400000);nextDay.setUTCHours(9,0,0,0);
  const date=nextDay.toISOString().slice(0,10);
  const order={serviceId:svc,serviceName:'Vệ sinh theo lịch',customerId:c.uid,customerName:c.name,workerId:null,workerName:null,
    addressId:addr,area:address.area,contactName:address.contact,contactPhone:address.phone,entryNote:address.note,addressSnapshot:address.detail+', '+address.area,date,time:'09:00',duration:2,total:160000,scheduledAt:nextDay,
    status:'pending',paymentMethod:'cod',paymentStatus:'unpaid',createdAt:new Date().toISOString(),inAppVersion:1};
  const offer=Object.fromEntries(['customerId','serviceName','date','time','duration','total','status','scheduledAt','area'].map(k=>[k,order[k]]));
  const oid='o-'+prefix, cancelled='c-'+prefix,overlap='x-'+prefix;
  const titles={pending:'Đơn đang chờ nhận',accepted:'Đã có người nhận việc',working:'Công việc đã bắt đầu',completed:'Công việc đã hoàn thành',cancelled:'Đơn đã bị hủy'};
  const note=(id,status,uid)=>put('notifications/'+[id,status,uid].join('_'),{orderId:id,status,userId:uid,title:titles[status],body:'Đơn '+id+' có cập nhật mới.',read:false,createdAt:new Date().toISOString()});
  for(const id of [oid,cancelled,overlap]) await commit(c,[put('orders/'+id,order),put('job_offers/'+id,offer),note(id,'pending',c.uid)]);
  await commit(c,[put('orders/'+cancelled,{status:'cancelled'},true),del('job_offers/'+cancelled),note(cancelled,'cancelled',c.uid)]);
  await read(w,'job_offers/'+oid,403);
  const approve=p=>put('worker_profiles/'+p.uid,{approval:'approved',reason:'',approvedBy:a.uid,approvedAt:new Date().toISOString()},true);
  await commit(c,[approve(w)],403);
  for(const p of [w,v]) await commit(a,[approve(p)]);
  await read(w,'job_offers/'+oid,200);
  await read(w,'orders/'+oid,403);
  const slot=id=>({id,start:nextDay,end:new Date(nextDay.getTime()+7200000)});
  const acceptLedger=(p,id)=>put('work_calendars/'+p.uid,{orderId:id,position:0,jobs:[slot(id)]});
  const attempts=await Promise.all([w,v].map(p=>commit(p,[put('orders/'+oid,{status:'accepted',workerId:p.uid,workerName:p.name},true),
    del('job_offers/'+oid),acceptLedger(p,oid),note(oid,'accepted',c.uid),note(oid,'accepted',p.uid)],null)));
  assert.deepEqual(attempts.sort((a,b)=>a-b),[200,403]);
  const winner=(await read(c,'orders/'+oid,200)).fields.workerId.stringValue===w.uid?w:v;
  await commit(winner,[put('orders/'+overlap,{status:'accepted',workerId:winner.uid,workerName:winner.name},true),
    del('job_offers/'+overlap),put('work_calendars/'+winner.uid,{orderId:overlap,position:1,jobs:[slot(oid),slot(overlap)]}),note(overlap,'accepted',c.uid),note(overlap,'accepted',winner.uid)],403);
  const receipt=put('payments/'+oid,{orderId:oid,customerId:c.uid,workerId:winner.uid,amount:order.total,method:'cod',status:'paid'});
  receipt.updateTransforms=[{fieldPath:'paidAt',setToServerValue:'REQUEST_TIME'}];
  for(const status of ['working','completed']) await commit(winner,[
    put('orders/'+oid,{status,...(status==='completed'?{paymentStatus:'paid'}:{})},true),note(oid,status,c.uid),note(oid,status,winner.uid),...(status==='completed'?[receipt,put('work_calendars/'+winner.uid,{orderId:oid,position:0,jobs:[]})]:[])]);
  await read(c,'payments/'+oid,200);
  const rev={orderId:oid,workerId:winner.uid,customerId:c.uid,stars:5,comment:'Tốt',createdAt:new Date().toISOString()};
  const reviewWrites=[put('reviews/'+oid,rev),put('rating_totals/'+winner.uid,{lastOrder:oid,count:1,sum:5})];
  await commit(c,reviewWrites); await commit(c,reviewWrites,403);
  await commit(c,[put('notifications/'+[oid,'completed',c.uid].join('_'),{read:true},true)]);
  await commit(a,[put('users/'+winner.uid,{status:'blocked'},true)]);
  await read(winner,'orders/'+oid,403);
  await read(c,'reviews/'+oid,200);
});
