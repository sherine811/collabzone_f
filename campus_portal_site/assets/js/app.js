// Single-file front-end "backend" using localStorage
const DB = {
  eventsKey: 'cp_events',
  usersKey: 'cp_users',
  regsKey: 'cp_regs',
  feedbackKey: 'cp_feedback',
  attendanceKey: 'cp_attendance'
}

function uid(prefix='id'){return prefix+Math.random().toString(36).slice(2,9)}

function get(key, def){return JSON.parse(localStorage.getItem(key)||'null')||def}
function set(key,val){localStorage.setItem(key,JSON.stringify(val))}

function seed(){
  if(!get(DB.eventsKey,[]).length){
    const sample = [
      {id:uid('e'),title:'AI Workshop',desc:'Intro to ML and hands-on labs',date:'2025-11-10'},
      {id:uid('e'),title:'Hackathon',desc:'24-hour coding sprint',date:'2025-12-05'},
      {id:uid('e'),title:'Tech Talk: Cloud',desc:'Industry panel on cloud careers',date:'2025-11-20'}
    ];
    set(DB.eventsKey,sample);
  }
  if(!get(DB.usersKey,[]).length){
    const admin={id:uid('u'),name:'admin',email:'admin@campus.com',role:'admin',password:'admin'};
    set(DB.usersKey,[admin]);
  }
}

// --- Index / Login Page functions ---
function renderUpcoming(el){
  const events = get(DB.eventsKey,[]);
  if(!el) return;
  el.innerHTML = events.map(e=>`<div class="event"><strong>${e.title}</strong><div class="small">${e.date}</div><div class="small">${e.desc}</div></div>`).join('');
}

function registerUser(data){
  const users = get(DB.usersKey,[]);
  if(users.find(u=>u.email===data.email)) return {ok:false,msg:'Email already registered'};
  data.id = uid('u');
  users.push(data); set(DB.usersKey,users); return {ok:true,user:data};
}

function loginUser(email,password,role){
  const users=get(DB.usersKey,[]);
  const u = users.find(x=>x.email===email && x.role===role);
  if(!u) return {ok:false,msg:'No user with that role and email'};
  if(u.password!==password) return {ok:false,msg:'Incorrect password'};
  return {ok:true,user:u};
}

// navigation helper
function goTo(role){ if(role==='student') location.href='student.html'; if(role==='faculty') location.href='faculty.html'; if(role==='admin') location.href='admin.html'; }

// --- Student page helpers ---
function renderEventsSelection(el){ const events = get(DB.eventsKey,[]); el.innerHTML = events.map(e=>`<option value="${e.id}">${e.title} — ${e.date}</option>`).join(''); }

function registerForEvent(form){
  const regs = get(DB.regsKey,[]);
  regs.push(form); set(DB.regsKey,regs);
  alert('Successfully registered');
}

function submitFeedback(feedback){
  const fb = get(DB.feedbackKey,[]); fb.push(feedback); set(DB.feedbackKey,fb); alert('Feedback submitted — thank you!');
}

// --- Faculty tools ---
function getStudentsForEvent(eventId){
  const regs = get(DB.regsKey,[]).filter(r=>r.eventId===eventId);
  return regs;
}

function toggleAttendance(eventId, studentId, status){
  const attendance = get(DB.attendanceKey,[]);
  const idx = attendance.findIndex(a=>a.eventId===eventId && a.studentId===studentId);
  if(idx>=0){ attendance[idx].status = status; } else { attendance.push({id:uid('a'),eventId,studentId,status}); }
  set(DB.attendanceKey,attendance);
}

// --- Admin tools ---
function createEvent(ev){ const events = get(DB.eventsKey,[]); events.push(ev); set(DB.eventsKey,events); }
function deleteEvent(eventId){ let events = get(DB.eventsKey,[]); events = events.filter(e=>e.id!==eventId); set(DB.eventsKey,events);
 // also remove related regs, attendance
 set(DB.regsKey, get(DB.regsKey,[]).filter(r=>r.eventId!==eventId));
 set(DB.attendanceKey, get(DB.attendanceKey,[]).filter(a=>a.eventId!==eventId));
}

// expose for pages
window.CP = {seed, renderUpcoming, registerUser, loginUser, goTo, renderEventsSelection, registerForEvent, submitFeedback, getStudentsForEvent, toggleAttendance, createEvent, deleteEvent, get}

// auto-seed on load
window.addEventListener('DOMContentLoaded',(e)=>{ CP.seed(); });
