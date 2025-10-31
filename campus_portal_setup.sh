#!/usr/bin/env bash
set -e
PROJECT_DIR="campus_portal_site"
mkdir -p "$PROJECT_DIR"/assets/{css,js,img}
cd "$PROJECT_DIR"

cat > assets/css/style.css <<'CSS'
/* Simple modern-ish styling */
:root{--bg:#0f1724;--card:#0b1220;--accent:#ff6b6b;--muted:#94a3b8;--glass: rgba(255,255,255,0.03)}
*{box-sizing:border-box;font-family:Inter,ui-sans-serif,system-ui,-apple-system,'Segoe UI',Roboto,'Helvetica Neue',Arial}
body{margin:0;background:linear-gradient(180deg,#071029 0%, #07121a 100%);color:#e6eef8}
.container{max-width:1100px;margin:28px auto;padding:20px}
.header{display:flex;align-items:center;gap:16px}
.logo{width:86px;height:86px;border-radius:12px;overflow:hidden;flex:0 0 86px;background:var(--glass);display:grid;place-items:center}
.logo img{width:100%;height:100%;object-fit:cover}
.card{background:var(--card);padding:18px;border-radius:12px;box-shadow:0 6px 18px rgba(2,6,23,0.6);}
.login-grid{display:grid;grid-template-columns:1fr 340px;gap:20px}
.form input,.form select{width:100%;padding:10px;border-radius:8px;border:1px solid rgba(255,255,255,0.06);background:transparent;color:inherit;margin-bottom:10px}
.btn{display:inline-block;padding:10px 12px;border-radius:10px;border:none;background:var(--accent);color:#08121a;font-weight:700;cursor:pointer}
.small{font-size:13px;color:var(--muted)}
.event{border-radius:8px;padding:12px;margin-bottom:8px;background:linear-gradient(180deg, rgba(255,255,255,0.02), transparent);}
.nav{display:flex;gap:8px;margin-top:10px}
.feedback-btn{margin-left:8px;padding:6px 8px;border-radius:8px;border:1px solid rgba(255,255,255,0.06);background:transparent;color:var(--muted);cursor:pointer}
.table{width:100%;border-collapse:collapse}
.table th,.table td{padding:8px;border-bottom:1px dashed rgba(255,255,255,0.03);text-align:left}
CSS

cat > assets/js/app.js <<'JS'
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
JS

cat > index.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Campus Portal — Login</title>
  <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo card"><img src="assets/img/logo.gif" alt="logo" onerror="this.src='https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif'"></div>
      <div>
        <h1>Campus Portal</h1>
        <div class="small">A creative interactive event portal</div>
      </div>
    </div>

    <div class="card login-grid" style="margin-top:18px">
      <div>
        <h3>Upcoming Events</h3>
        <div id="upcoming"></div>
      </div>

      <div class="card form">
        <h3>Login / Register</h3>
        <input id="name" placeholder="Full name (for register)">
        <input id="email" placeholder="Email">
        <input id="password" placeholder="Password" type="password">
        <div style="display:flex;gap:8px;margin-bottom:10px">
          <label><input type="radio" name="role" value="student" checked> Student</label>
          <label><input type="radio" name="role" value="faculty"> Faculty</label>
          <label><input type="radio" name="role" value="admin"> Admin</label>
        </div>
        <div class="nav">
          <button class="btn" id="loginBtn">Login</button>
          <button class="btn" id="regBtn">Register</button>
        </div>
        <div style="margin-top:10px" class="small">Default admin: admin@campus.com / password: admin</div>
      </div>
    </div>
  </div>

  <script src="assets/js/app.js"></script>
  <script>
    CP.renderUpcoming(document.getElementById('upcoming'));
    document.getElementById('regBtn').addEventListener('click', ()=>{
      const name=document.getElementById('name').value.trim(); const email=document.getElementById('email').value.trim(); const password=document.getElementById('password').value; const role = document.querySelector('input[name="role"]:checked').value;
      if(!name||!email||!password) return alert('please fill name, email and password');
      const r = CP.registerUser({name,email,password,role});
      if(!r.ok) return alert(r.msg);
      alert('Registered — you can now login');
    });
    document.getElementById('loginBtn').addEventListener('click', ()=>{
      const email=document.getElementById('email').value.trim(); const password=document.getElementById('password').value; const role = document.querySelector('input[name="role"]:checked').value;
      const r = CP.loginUser(email,password,role);
      if(!r.ok) return alert(r.msg);
      // save session minimal
      localStorage.setItem('cp_session', JSON.stringify({userId:r.user.id,role:r.user.role,name:r.user.name,email:r.user.email}));
      CP.goTo(role);
    });
  </script>
</body>
</html>
HTML

cat > student.html <<'HTML'
<!doctype html>
<html>
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Student Dashboard</title>
<link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
<div class="container">
  <div class="header">
    <div class="logo card"><img src="assets/img/logo.gif" alt="logo" onerror="this.src='https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif'"></div>
    <div><h2>Student Dashboard</h2><div class="small">Welcome — register for events and give feedback</div></div>
  </div>
  <div class="card" style="margin-top:16px">
    <h3>Register for Event</h3>
    <select id="evSelect"></select>
    <input id="s_name" placeholder="Name">
    <input id="s_email" placeholder="Email">
    <input id="s_phone" placeholder="Phone">
    <input id="s_course" placeholder="Course (e.g. B.Tech)">
    <input id="s_year" placeholder="Year (e.g. 3)">
    <div style="display:flex;gap:8px"><button class="btn" id="s_reg">Register</button>
    <button class="feedback-btn" id="open_fb">Feedback</button></div>
  </div>

  <div id="fb_card" class="card" style="margin-top:12px;display:none">
    <h3>Event Feedback</h3>
    <select id="fb_event"></select>
    <textarea id="fb_text" placeholder="Write your feedback here" style="width:100%;height:100px;border-radius:8px;background:transparent;border:1px solid rgba(255,255,255,0.06);color:inherit;padding:8px"></textarea>
    <div style="margin-top:8px"><button class="btn" id="fb_submit">Submit Feedback</button></div>
  </div>
</div>
<script src="assets/js/app.js"></script>
<script>
  const sess = JSON.parse(localStorage.getItem('cp_session')||'null');
  if(!sess||sess.role!=='student') { alert('Please login as student'); location.href='index.html'; }
  CP.renderEventsSelection(document.getElementById('evSelect'));
  CP.renderEventsSelection(document.getElementById('fb_event'));
  document.getElementById('s_reg').addEventListener('click', ()=>{
    const data={id:Math.random().toString(36).slice(2),eventId:document.getElementById('evSelect').value,studentId:sess.userId, name:document.getElementById('s_name').value || sess.name, email:document.getElementById('s_email').value || sess.email, phone:document.getElementById('s_phone').value, course:document.getElementById('s_course').value, year:document.getElementById('s_year').value};
    if(!data.eventId) return alert('select event');
    CP.registerForEvent(data);
  });
  document.getElementById('open_fb').addEventListener('click', ()=>{ document.getElementById('fb_card').style.display='block'; });
  document.getElementById('fb_submit').addEventListener('click', ()=>{
    const fb={id:Math.random().toString(36).slice(2),eventId:document.getElementById('fb_event').value,studentId:sess.userId, text:document.getElementById('fb_text').value};
    if(!fb.text) return alert('please write feedback');
    CP.submitFeedback(fb);
  });
</script>
</body>
</html>
HTML

cat > faculty.html <<'HTML'
<!doctype html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Faculty Dashboard</title><link rel="stylesheet" href="assets/css/style.css"></head>
<body>
<div class="container">
  <div class="header"><div class="logo card"><img src="assets/img/logo.gif" alt="logo" onerror="this.src='https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif'"></div><div><h2>Faculty</h2><div class="small">Manage attendance</div></div></div>
  <div class="card" style="margin-top:12px">
    <h3>Select Event</h3>
    <select id="f_event"></select>
    <div id="students_list" style="margin-top:12px"></div>
  </div>
</div>
<script src="assets/js/app.js"></script>
<script>
  const sess = JSON.parse(localStorage.getItem('cp_session')||'null');
  if(!sess||sess.role!=='faculty') { alert('Please login as faculty'); location.href='index.html'; }
  CP.renderEventsSelection(document.getElementById('f_event'));
  document.getElementById('f_event').addEventListener('change', ()=>{
    const ev = document.getElementById('f_event').value; const regs = CP.get(DBName='cp_regs') || [];
    const list = regs.filter(r=>r.eventId===ev);
    const container = document.getElementById('students_list');
    if(!list.length) { container.innerHTML = '<div class="small">No students registered yet</div>'; return; }
    container.innerHTML = '<table class="table"><tr><th>Name</th><th>Email</th><th>Course</th><th>Year</th><th>Attendance</th></tr>' + list.map(r=>`<tr><td>${r.name}</td><td>${r.email}</td><td>${r.course||'-'}</td><td>${r.year||'-'}</td><td><button onclick="mark(\'${ev}\',\'${r.studentId}\',\'Present\')" class="btn">Present</button> <button onclick="mark('${ev}','${r.studentId}','Absent')" class="feedback-btn">Absent</button></td></tr>`).join('') + '</table>';
  });
  function mark(ev,stu,status){ CP.toggleAttendance(ev,stu,status); alert('Marked '+status); }
  window.mark = mark;
</script>
</body>
</html>
HTML

cat > admin.html <<'HTML'
<!doctype html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Admin Panel</title><link rel="stylesheet" href="assets/css/style.css"></head>
<body>
<div class="container">
  <div class="header"><div class="logo card"><img src="assets/img/logo.gif" alt="logo" onerror="this.src='https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif'"></div><div><h2>Admin</h2><div class="small">Create events & view feedback</div></div></div>

  <div class="card" style="margin-top:12px">
    <h3>Create Event</h3>
    <input id="a_title" placeholder="Title">
    <input id="a_date" placeholder="Date (YYYY-MM-DD)">
    <input id="a_desc" placeholder="Short description">
    <div style="display:flex;gap:8px"><button class="btn" id="a_create">Create</button><button class="feedback-btn" id="a_refresh">Refresh List</button></div>
  </div>

  <div class="card" style="margin-top:12px">
    <h3>Events</h3>
    <div id="events_list"></div>
  </div>

  <div class="card" style="margin-top:12px">
    <h3>Feedback</h3>
    <div id="fb_list"></div>
  </div>
</div>
<script src="assets/js/app.js"></script>
<script>
  const sess = JSON.parse(localStorage.getItem('cp_session')||'null');
  if(!sess||sess.role!=='admin') { alert('Please login as admin'); location.href='index.html'; }
  function refresh(){
    const events = CP.get('cp_events');
    document.getElementById('events_list').innerHTML = events.map(e=>`<div class="event"><strong>${e.title}</strong> <div class="small">${e.date}</div><div class="small">${e.desc}</div><div style="margin-top:6px"><button class="feedback-btn" onclick="del('${e.id}')">Delete</button></div></div>`).join('');
    const fbs = CP.get('cp_feedback');
    document.getElementById('fb_list').innerHTML = (fbs.length? fbs.map(f=>`<div class="event"><div class="small">event: ${ (CP.get('cp_events').find(e=>e.id===f.eventId)||{}).title || f.eventId }</div><div>${f.text}</div></div>`).join('') : '<div class="small">No feedback yet</div>');
  }
  document.getElementById('a_create').addEventListener('click', ()=>{
    const ev={id:Math.random().toString(36).slice(2),title:document.getElementById('a_title').value,date:document.getElementById('a_date').value,desc:document.getElementById('a_desc').value};
    if(!ev.title) return alert('title required');
    CP.createEvent(ev); refresh();
  });
  function del(id){ if(confirm('Delete event?')){ CP.deleteEvent(id); refresh(); }}
  window.del = del; document.getElementById('a_refresh').addEventListener('click', refresh);
  refresh();
</script>
</body>
</html>
HTML

cat > assets/img/README.txt <<'TXT'
Place your GIF logo here as "logo.gif". The index and pages use assets/img/logo.gif; if not present they fallback to an online sample GIF.
TXT

chmod +x campus_portal_setup.sh || true

echo "Setup complete. Files created in: $PROJECT_DIR"
echo "How to run:"
echo "  1) If using Git Bash on Windows: open Git Bash, run: bash campus_portal_setup.sh"
echo "  2) cd $PROJECT_DIR"
echo "  3) (recommended) start a local web server:"
echo "       python -m http.server 8000"
echo "     then open http://localhost:8000/index.html in your browser"
echo "  4) Default admin: admin@campus.com / password: admin"
