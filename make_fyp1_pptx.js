"use strict";
const pptxgen = require("pptxgenjs");

const pres = new pptxgen();
pres.layout = "LAYOUT_16x9"; // 10" × 5.625"
pres.title  = "MyBahaya FYP1 Presentation";
pres.author = "Ahmad Shukri";

// ── Palette (no # prefix) ──────────────────────────────────
const M   = "341515";  // maroon
const N   = "ACA494";  // nude
const NL  = "F0ECE6";  // nude very light
const NM  = "C4B9AC";  // nude mid
const W   = "FFFFFF";  // white
const TXT = "2A1515";  // dark text

const mk = () => ({ type:"outer", color:"000000", blur:7, offset:2, angle:45, opacity:0.10 });

// ════════════════════════════════════════════════════════════
// SLIDE 1 — TITLE
// ════════════════════════════════════════════════════════════
const s1 = pres.addSlide();
s1.background = { color: M };

s1.addShape(pres.shapes.OVAL, { x:7.2, y:-1.2, w:4.0, h:4.0, fill:{color:N,transparency:82}, line:{color:N,width:0} });
s1.addShape(pres.shapes.OVAL, { x:8.0, y:-0.5, w:2.4, h:2.4, fill:{color:N,transparency:68}, line:{color:N,width:0} });

s1.addText("MyBahaya", {
  x:0.7, y:1.05, w:8.0, h:1.55,
  fontFace:"Cambria", fontSize:68, bold:true,
  color:W, align:"left", valign:"middle", margin:0
});
s1.addText("AI-Powered Emergency Reporting & Real-Time Community Alert Platform", {
  x:0.7, y:2.72, w:7.6, h:0.72,
  fontFace:"Calibri", fontSize:17,
  color:N, align:"left", margin:0
});
s1.addShape(pres.shapes.LINE, { x:0.7, y:3.58, w:2.5, h:0, line:{color:N, width:1.5} });
s1.addText("FYP1 Presentation  ·  Ahmad Shukri  ·  Universiti Teknikal Malaysia Melaka (UTeM)  ·  2025/2026", {
  x:0.7, y:3.74, w:8.6, h:0.44,
  fontFace:"Calibri", fontSize:10.5,
  color:NM, align:"left", margin:0
});
s1.addNotes("Assalamualaikum. Good morning, evaluators. My name is Ahmad Shukri. Today I present MyBahaya — an AI-powered emergency reporting and real-time community alert platform for Malaysia.");

// ════════════════════════════════════════════════════════════
// SLIDE 2 — INTRODUCTION
// ════════════════════════════════════════════════════════════
const s2 = pres.addSlide();
s2.background = { color: W };

s2.addText("Introduction", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:M, align:"left", margin:0
});

const intro = [
  { title:"What is MyBahaya?",
    body:"A mobile-first platform enabling Malaysian citizens to report emergencies in real-time, complete with media upload, GPS tagging, and live status tracking." },
  { title:"Who uses it?",
    body:"Citizens submit and track reports. Emergency organizations (Fire, Police, Medical) receive auto-assigned cases. Admins moderate via web dashboard." },
  { title:"How does it work?",
    body:"Citizen submits photo + GPS → AI analyses severity → Nearest org auto-assigned → FCM push to org & nearby citizens → Status updates in real-time." },
];

intro.forEach((c, i) => {
  const cx = 0.38 + i * 3.21;
  s2.addShape(pres.shapes.ROUNDED_RECTANGLE, { x:cx, y:1.0, w:3.0, h:4.28, fill:{color:NL}, rectRadius:0.12, shadow:mk(), line:{color:NM,width:0.5} });
  s2.addShape(pres.shapes.OVAL,              { x:cx+1.05, y:1.14, w:0.9, h:0.9, fill:{color:M}, line:{color:M,width:0} });
  s2.addText(c.title, {
    x:cx+0.1, y:2.18, w:2.8, h:0.45,
    fontFace:"Cambria", fontSize:13, bold:true,
    color:M, align:"center", margin:0
  });
  s2.addText(c.body, {
    x:cx+0.12, y:2.7, w:2.76, h:2.4,
    fontFace:"Calibri", fontSize:12,
    color:TXT, align:"left", valign:"top", margin:0
  });
});

s2.addNotes("MyBahaya has three user types: citizens, organizations, admins. Flow: submit → AI → route → notify → track.");

// ════════════════════════════════════════════════════════════
// SLIDE 3 — PROBLEM STATEMENT
// ════════════════════════════════════════════════════════════
const s3 = pres.addSlide();
s3.background = { color: W };

s3.addText("Problem Statement", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:M, align:"left", margin:0
});

const probs = [
  { num:"01", title:"No Dedicated Reporting App",  desc:"Malaysia has no mobile app for citizens to report non-fire emergencies with media evidence and GPS location in real-time.", dark:true  },
  { num:"02", title:"Slow Emergency Routing",       desc:"Traditional 999 calls rely on human dispatchers. No automated system routes incidents to the nearest available organization.", dark:false },
  { num:"03", title:"No Community Awareness",       desc:"Citizens near an incident are not notified, causing late community response and repeated submissions of the same incident.", dark:true  },
  { num:"04", title:"Fake Report Abuse",            desc:"Without automated verification, emergency services are overwhelmed by false reports — wasting critical response resources.", dark:false },
];

probs.forEach((p, i) => {
  const col = i % 2;
  const row = Math.floor(i / 2);
  const px = col === 0 ? 0.38 : 5.2;
  const py = row === 0 ? 1.0  : 3.2;
  const bg   = p.dark ? M  : NL;
  const txtC = p.dark ? W  : TXT;
  const lblC = p.dark ? N  : M;
  const bdrC = p.dark ? M  : NM;

  s3.addShape(pres.shapes.ROUNDED_RECTANGLE, { x:px, y:py, w:4.6, h:1.96, fill:{color:bg}, rectRadius:0.1, shadow:mk(), line:{color:bdrC,width:0.5} });
  s3.addText(p.num,   { x:px+0.15, y:py+0.1,  w:0.7,  h:0.44, fontFace:"Cambria", fontSize:18, bold:true, color:lblC, align:"left",  margin:0 });
  s3.addText(p.title, { x:px+0.15, y:py+0.57, w:4.3,  h:0.42, fontFace:"Cambria", fontSize:13, bold:true, color:p.dark?W:M, align:"left", margin:0 });
  s3.addText(p.desc,  { x:px+0.15, y:py+1.0,  w:4.3,  h:0.85, fontFace:"Calibri", fontSize:11.5, color:txtC, align:"left", valign:"top", margin:0 });
});

s3.addNotes("Four problems: no reporting app, slow routing, no community awareness, fake reports. These gaps justify MyBahaya.");

// ════════════════════════════════════════════════════════════
// SLIDE 4 — KEY STATISTICS (real cited sources)
// ════════════════════════════════════════════════════════════
const s4 = pres.addSlide();
s4.background = { color: W };

s4.addText("Problem Statement — Key Statistics", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:27, bold:true,
  color:M, align:"left", margin:0
});
s4.addText("Sources: DOSM ICT Survey 2024  ·  MERS 999 ScienceDirect 2026  ·  The Star 2025  ·  MJPHM Kelantan Study", {
  x:0.5, y:0.82, w:9, h:0.28,
  fontFace:"Calibri", fontSize:10, italic:true,
  color:N, align:"left", margin:0
});

// 4 stat cards — 2 top, 2 bottom
const stats = [
  {
    num:"99.5%",
    label:"of Malaysians own a mobile phone",
    sub:"yet no dedicated emergency reporting app exists",
    cite:"DOSM ICT Use & Access Survey, 2024",
    dark:true, x:0.38, y:1.18
  },
  {
    num:"84.7%",
    label:"of ambulance calls had delayed response",
    sub:"Response times exceeded WHO & MOH benchmarks in all districts",
    cite:"MJPHM — Kelantan Ambulance Study",
    dark:false, x:5.18, y:1.18
  },
  {
    num:"169,000+",
    label:"prank / fake calls to MERS 999",
    sub:"In 2025 alone — disrupting real emergency responses",
    cite:"The Star, November 2025",
    dark:false, x:0.38, y:3.2
  },
  {
    num:"2–3%",
    label:"of all 999 calls are real emergencies",
    sub:"Majority are false reports — wasting critical resources",
    cite:"The Sun / CiliSOS — MERS 999 Analysis",
    dark:true, x:5.18, y:3.2
  },
];

stats.forEach(st => {
  const bg = st.dark ? M : NL;
  const bdr = st.dark ? M : NM;
  s4.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x:st.x, y:st.y, w:4.6, h:1.95,
    fill:{color:bg}, rectRadius:0.1, shadow:mk(), line:{color:bdr, width:0.5}
  });
  // Big number
  s4.addText(st.num, {
    x:st.x+0.15, y:st.y+0.1, w:4.3, h:0.65,
    fontFace:"Cambria", fontSize:32, bold:true,
    color:st.dark ? N : M, align:"left", margin:0
  });
  // Label
  s4.addText(st.label, {
    x:st.x+0.15, y:st.y+0.74, w:4.3, h:0.38,
    fontFace:"Cambria", fontSize:12, bold:true,
    color:st.dark ? W : TXT, align:"left", margin:0
  });
  // Sub description
  s4.addText(st.sub, {
    x:st.x+0.15, y:st.y+1.12, w:4.3, h:0.38,
    fontFace:"Calibri", fontSize:10.5,
    color:st.dark ? NM : "5A4A4A", align:"left", margin:0
  });
  // Citation tag
  s4.addText("📌 " + st.cite, {
    x:st.x+0.15, y:st.y+1.5, w:4.3, h:0.32,
    fontFace:"Calibri", fontSize:9, italic:true,
    color:st.dark ? NM : N, align:"left", margin:0
  });
});

s4.addNotes("All statistics from real sources. 99.5% phone ownership confirms mobile reach. 84.7% ambulance delay + response times exceeding WHO benchmarks prove the problem. 169,000 fake calls in 2025 and only 2-3% real calls justify AI fake detection in MyBahaya.");

// ════════════════════════════════════════════════════════════
// SLIDE 5 — EXISTING WORK COMPARISON
// ════════════════════════════════════════════════════════════
const s5 = pres.addSlide();
s5.background = { color: W };

s5.addText("Problem Statement — Existing Work Comparison", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:25, bold:true,
  color:M, align:"left", margin:0
});

const ch = "✓";
const cx = "✗";

const tbl = [
  // header row
  [
    { text:"Feature",          options:{ bold:true, color:W, fill:{color:M},     fontSize:11, align:"center" } },
    { text:"999 System",       options:{ bold:true, color:W, fill:{color:M},     fontSize:11, align:"center" } },
    { text:"MySejahtera",      options:{ bold:true, color:W, fill:{color:M},     fontSize:11, align:"center" } },
    { text:"Waze",             options:{ bold:true, color:W, fill:{color:M},     fontSize:11, align:"center" } },
    { text:"MyBahaya",         options:{ bold:true, color:W, fill:{color:"5C1010"}, fontSize:11, align:"center" } },
  ],
  // data rows
  makeRow("Real-Time Community Alerts",  cx, cx, "Partial", ch, false),
  makeRow("Photo / Video Upload",        cx, ch, ch,        ch, true ),
  makeRow("AI Severity Analysis",        cx, cx, cx,        ch, false),
  makeRow("Report Status Tracking",      cx, ch, cx,        ch, true ),
  makeRow("Auto Organisation Routing",   cx, cx, cx,        ch, false),
  makeRow("Fake Report Detection (AI)",  cx, cx, cx,        ch, true ),
];

function makeRow(feat, c1, c2, c3, c4, alt) {
  const bg = alt ? NL : W;
  function cell(val) {
    const isCheck = val === ch;
    const isCross = val === cx;
    return {
      text: val,
      options: {
        color: isCheck ? M : (isCross ? "BB0000" : "B8860B"),
        bold: isCheck || isCross,
        fontSize: isCheck ? 15 : (isCross ? 14 : 10),
        align: "center",
        fill: { color: bg }
      }
    };
  }
  return [
    { text:feat, options:{ fontSize:11, align:"left", fill:{color:bg}, color:TXT } },
    cell(c1), cell(c2), cell(c3),
    { text:c4, options:{ bold:true, fontSize:15, color:M, align:"center", fill:{color:alt ? NL : W} } }
  ];
}

s5.addTable(tbl, {
  x:0.35, y:0.92, w:9.3,
  border: { pt:0.5, color:NM },
  fontFace: "Calibri",
  rowH: 0.56,
  colW: [2.85, 1.44, 1.44, 1.44, 2.13],
});

s5.addNotes("Only MyBahaya provides all six features. Competitors lack AI analysis, auto routing, and fake detection.");

// ════════════════════════════════════════════════════════════
// SLIDE 6 — OBJECTIVES
// ════════════════════════════════════════════════════════════
const s6 = pres.addSlide();
s6.background = { color: W };

s6.addText("Objectives", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:M, align:"left", margin:0
});

const objs = [
  "To develop a cross-platform mobile application that enables Malaysian citizens to submit emergency reports with multimedia evidence and real-time GPS coordinates.",
  "To implement an AI analysis module using Google Gemini 2.5 Flash that automatically assesses incident severity (1–5), identifies hazards, and detects fake reports.",
  "To design a geolocation-based routing system that auto-assigns reports to the nearest emergency organisation and delivers real-time FCM push notifications to all stakeholders.",
];

objs.forEach((obj, i) => {
  const oy = 1.1 + i * 1.44;
  s6.addShape(pres.shapes.OVAL, { x:0.38, y:oy+0.19, w:0.72, h:0.72, fill:{color:M}, line:{color:M,width:0} });
  s6.addText(String(i+1), { x:0.38, y:oy+0.19, w:0.72, h:0.72, fontFace:"Cambria", fontSize:18, bold:true, color:W, align:"center", valign:"middle", margin:0 });
  s6.addShape(pres.shapes.ROUNDED_RECTANGLE, { x:1.28, y:oy, w:8.32, h:1.25, fill:{color:i%2===0?NL:W}, rectRadius:0.09, shadow:mk(), line:{color:NM,width:0.5} });
  s6.addText(obj, { x:1.45, y:oy+0.08, w:8.0, h:1.09, fontFace:"Calibri", fontSize:12.5, color:TXT, align:"left", valign:"middle", margin:0 });
});

s6.addNotes("Three objectives: build mobile reporting app, implement Gemini AI analysis, design geolocation routing system.");

// ════════════════════════════════════════════════════════════
// SLIDE 7 — SCOPE
// ════════════════════════════════════════════════════════════
const s7 = pres.addSlide();
s7.background = { color: W };

s7.addText("Scope", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:M, align:"left", margin:0
});

const scopes = [
  { label:"Users",              dark:true,  items:["Malaysian citizens — Android mobile app", "Emergency organizations — Fire, Police, Medical", "System administrators — Web dashboard"] },
  { label:"Functionalities",    dark:false, items:["Real-time report submission with photo/video", "AI severity analysis & fake detection", "FCM push alerts (org + nearby citizens)"] },
  { label:"Geographic Coverage",dark:false, items:["Peninsular Malaysia", "5 incident categories: Fire, Medical, Theft, Assault, Other"] },
  { label:"Exclusions (FYP 1)", dark:true,  items:["iOS platform — not in scope", "Government API integration — not in scope", "Payment or legal processing — not included"] },
];

scopes.forEach((sc, i) => {
  const col = i % 2;
  const row = Math.floor(i / 2);
  const sx = col === 0 ? 0.38 : 5.2;
  const sy = row === 0 ? 1.0  : 3.2;
  const bg   = sc.dark ? M  : NL;
  const bdr  = sc.dark ? M  : NM;

  s7.addShape(pres.shapes.ROUNDED_RECTANGLE, { x:sx, y:sy, w:4.62, h:2.0, fill:{color:bg}, rectRadius:0.1, shadow:mk(), line:{color:bdr,width:0.5} });
  s7.addText(sc.label, { x:sx+0.15, y:sy+0.1, w:4.35, h:0.44, fontFace:"Cambria", fontSize:14, bold:true, color:sc.dark?N:M, align:"left", margin:0 });
  s7.addText(
    sc.items.map((item, idx) => ({ text:item, options:{ bullet:true, breakLine: idx < sc.items.length - 1, color:sc.dark?W:TXT } })),
    { x:sx+0.15, y:sy+0.57, w:4.35, h:1.32, fontFace:"Calibri", fontSize:11.5, align:"left", valign:"top", margin:0 }
  );
});

s7.addNotes("Scope: Android for citizens, organizations, admins. Peninsular Malaysia. Five categories. iOS and government APIs excluded in FYP1.");

// ════════════════════════════════════════════════════════════
// SLIDE 8 — ERD
// ════════════════════════════════════════════════════════════
const s8 = pres.addSlide();
s8.background = { color: W };

s8.addText("Entity Relationship Diagram (ERD)", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:28, bold:true,
  color:M, align:"left", margin:0
});

s8.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x:0.65, y:1.0, w:8.7, h:4.3,
  fill:{color:NL}, rectRadius:0.14,
  line:{color:N, width:1.5, dashType:"dash"}
});
s8.addText("[ ERD Diagram ]", {
  x:0.65, y:2.2, w:8.7, h:0.7,
  fontFace:"Cambria", fontSize:24, italic:true,
  color:NM, align:"center", valign:"middle", margin:0
});
s8.addText("5 Entities:   USERS   ·   REPORTS   ·   ORGANIZATIONS   ·   PUBLIC_INCIDENTS   ·   ADMINS", {
  x:0.65, y:3.05, w:8.7, h:0.45,
  fontFace:"Calibri", fontSize:12,
  color:N, align:"center", margin:0
});
s8.addText("(Insert ERD diagram here)", {
  x:0.65, y:4.92, w:8.7, h:0.3,
  fontFace:"Calibri", fontSize:10, italic:true,
  color:NM, align:"center", margin:0
});

s8.addNotes("Five Firestore collections. Reports link to Users via userId, to Organisations via assignedOrgId, and mirror sanitised data to Public Incidents. Admins manage the platform.");

// ════════════════════════════════════════════════════════════
// SLIDE 9 — METHODOLOGY
// ════════════════════════════════════════════════════════════
const s9 = pres.addSlide();
s9.background = { color: W };

s9.addText("Methodology — Agile SDLC", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:M, align:"left", margin:0
});

const phases = [
  { n:"1", label:"Planning",        desc:"Define requirements, scope & tech stack selection", dark:true  },
  { n:"2", label:"Analysis",        desc:"User stories, use cases, data requirements",        dark:false },
  { n:"3", label:"Design",          desc:"ERD, system architecture & UI wireframes",           dark:true  },
  { n:"4", label:"Implementation",  desc:"Flutter app, Spring Boot API, Firebase integration", dark:false },
  { n:"5", label:"Testing",         desc:"Unit, integration & user acceptance testing",         dark:true  },
  { n:"6", label:"Deployment",      desc:"VPS, Nginx, Docker MinIO, domain & SSL setup",       dark:false },
];

phases.forEach((ph, i) => {
  const col = i % 3;
  const row = Math.floor(i / 3);
  const px  = 0.34 + col * 3.12;
  const py  = 1.0  + row * 2.22;
  const bg  = ph.dark ? M : NL;

  s9.addShape(pres.shapes.ROUNDED_RECTANGLE, { x:px, y:py, w:2.96, h:2.02, fill:{color:bg}, rectRadius:0.1, shadow:mk(), line:{color:ph.dark?M:NM,width:0.5} });
  s9.addShape(pres.shapes.OVAL,              { x:px+0.1, y:py+0.14, w:0.55, h:0.55, fill:{color:ph.dark?N:M}, line:{color:ph.dark?N:M,width:0} });
  s9.addText(ph.n,     { x:px+0.1, y:py+0.14, w:0.55, h:0.55, fontFace:"Cambria", fontSize:13, bold:true, color:ph.dark?M:W, align:"center", valign:"middle", margin:0 });
  s9.addText(ph.label, { x:px+0.14, y:py+0.74, w:2.72, h:0.4, fontFace:"Cambria", fontSize:13, bold:true, color:ph.dark?W:M, align:"left", margin:0 });
  s9.addText(ph.desc,  { x:px+0.14, y:py+1.15, w:2.72, h:0.77, fontFace:"Calibri", fontSize:11.5, color:ph.dark?NL:TXT, align:"left", valign:"top", margin:0 });
});

s9.addText("Iterative Agile sprints allow continuous feedback and adaptability throughout the project lifecycle.", {
  x:0.4, y:5.25, w:9.2, h:0.3,
  fontFace:"Calibri", fontSize:10, italic:true,
  color:N, align:"center", margin:0
});

s9.addNotes("Agile SDLC chosen for its iterative nature. Six phases: Planning through Deployment. Each sprint reviewed with supervisor.");

// ════════════════════════════════════════════════════════════
// SLIDE 10 — ARCHITECTURE DESIGN
// ════════════════════════════════════════════════════════════
const s10 = pres.addSlide();
s10.background = { color: W };

s10.addText("System Architecture Design", {
  x:0.5, y:0.2, w:9, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:M, align:"left", margin:0
});

s10.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x:0.65, y:1.0, w:8.7, h:4.0,
  fill:{color:NL}, rectRadius:0.14,
  line:{color:N, width:1.5, dashType:"dash"}
});
s10.addText("[ System Architecture Diagram ]", {
  x:0.65, y:2.2, w:8.7, h:0.7,
  fontFace:"Cambria", fontSize:22, italic:true,
  color:NM, align:"center", valign:"middle", margin:0
});
s10.addText("(Insert System Architecture Diagram here)", {
  x:0.65, y:3.05, w:8.7, h:0.42,
  fontFace:"Calibri", fontSize:11, italic:true,
  color:NM, align:"center", margin:0
});

// Tech badges
["Flutter", "Spring Boot", "Firebase", "Gemini AI", "MinIO", "FCM Push"].forEach((t, i) => {
  const bx = 0.58 + i * 1.49;
  s10.addShape(pres.shapes.ROUNDED_RECTANGLE, { x:bx, y:5.1, w:1.36, h:0.38, fill:{color:i%2===0?M:N}, rectRadius:0.15, line:{color:i%2===0?M:N,width:0} });
  s10.addText(t, { x:bx, y:5.1, w:1.36, h:0.38, fontFace:"Calibri", fontSize:10, bold:true, color:W, align:"center", valign:"middle", margin:0 });
});

s10.addNotes("Three-tier architecture: Client (Flutter + Web browser), Application (Spring Boot REST API on VPS), Data (Firebase Firestore, MinIO, Gemini AI, FCM).");

// ════════════════════════════════════════════════════════════
// SLIDE 11 — CONCLUSION
// ════════════════════════════════════════════════════════════
const s11 = pres.addSlide();
s11.background = { color: M };

s11.addShape(pres.shapes.OVAL, { x:-1.2, y:3.2, w:3.8, h:3.8, fill:{color:N,transparency:82}, line:{color:N,width:0} });
s11.addShape(pres.shapes.OVAL, { x:8.5,  y:-0.8, w:2.8, h:2.8, fill:{color:N,transparency:75}, line:{color:N,width:0} });

s11.addText("Conclusion", {
  x:0.7, y:0.3, w:8.6, h:0.65,
  fontFace:"Cambria", fontSize:30, bold:true,
  color:N, align:"left", margin:0
});

const pts = [
  "MyBahaya fills a real gap — no existing platform in Malaysia combines real-time reporting, AI analysis, and community alerting in one app.",
  "Geolocation-based routing (Haversine formula) ensures the nearest emergency organisation is notified with an automated ETA estimate.",
  "Google Gemini 2.5 Flash provides automated severity scoring (1–5), hazard identification, and AI-based fake report detection.",
  "The platform is fully deployed at api.mybahaya.com with Firebase Firestore real-time updates and FCM push notifications.",
];

pts.forEach((pt, i) => {
  const py = 1.15 + i * 0.97;
  s11.addShape(pres.shapes.OVAL, { x:0.7, y:py+0.03, w:0.44, h:0.44, fill:{color:N}, line:{color:N,width:0} });
  s11.addText(String(i+1), { x:0.7, y:py+0.03, w:0.44, h:0.44, fontFace:"Cambria", fontSize:12, bold:true, color:M, align:"center", valign:"middle", margin:0 });
  s11.addText(pt, { x:1.3, y:py, w:8.0, h:0.82, fontFace:"Calibri", fontSize:13, color:W, align:"left", valign:"middle", margin:0 });
});

s11.addText("Thank you  ·  Terima kasih  ·  Q&A", {
  x:0.7, y:5.12, w:8.6, h:0.38,
  fontFace:"Cambria", fontSize:13, italic:true,
  color:NM, align:"center", margin:0
});

s11.addNotes("MyBahaya addresses all four identified problems and is fully deployed. Ready for the tool demo. Open for questions.");

// ════════════════════════════════════════════════════════════
// WRITE FILE
// ════════════════════════════════════════════════════════════
const OUT = "/Users/user/my_bahaya_fyp/diagrams-xml/MyBahaya_FYP1.pptx";
pres.writeFile({ fileName: OUT })
  .then(() => console.log("DONE: " + OUT))
  .catch(err => { console.error("ERROR:", err); process.exit(1); });
