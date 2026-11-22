'use strict';
/* Baukasten für die Geschichts-Serie (Titanic & Co.): Schiffe, Meer, Figuren, Vintage-Look. Lädt nach engine.js. */
const NAVY = '#0b1a2e', SEA = '#14405e', SEA_D = '#0b2a40', FOAM = '#cfe8f3', PAPER = '#f2e6cc', SEPIA = '#5b3f1f', RUST = '#9c3a22', BUFF = '#d9a441', GOLDH = '#ffcf5a';
const SERIFH = '"Liberation Serif", "DejaVu Serif", serif', MONO = '"Liberation Mono", "DejaVu Sans Mono", monospace';
const OUT = '#0d1621';
window.EP_CAPCOL = { H: GOLDH };

function stxtH(s, x, y, size, col, o = {}) {
  ctx.save(); ctx.font = `${o.italic ? 'italic ' : ''}${o.weight || 700} ${size}px ${o.mono ? MONO : SERIFH}`; ctx.textAlign = o.align || 'center'; ctx.textBaseline = 'middle';
  ctx.translate(x, y); if (o.rot) ctx.rotate(o.rot);
  const w = ctx.measureText(s).width, mw = o.maxW || 980; if (w > mw) ctx.scale(mw / w, mw / w);
  if (o.stroke) { ctx.lineWidth = o.stroke; ctx.strokeStyle = o.sc || OUT; ctx.lineJoin = 'round'; ctx.strokeText(s, 0, 0); }
  ctx.fillStyle = col; ctx.fillText(s, 0, 0); ctx.restore();
}
function emo(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }

/* ---------- Himmel, Meer, Look ---------- */
function sky(c1, c2, y1 = 1400) { const g = ctx.createLinearGradient(0, 0, 0, y1); g.addColorStop(0, c1); g.addColorStop(1, c2); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); }
function nightSky(t) {
  sky('#050b16', '#163352');
  for (let i = 0; i < 90; i++) { const x = rnd(i) * W, y = 380 + rnd(i + 50) * 700, tw = 0.5 + 0.5 * Math.sin(t * 2 + i); circ(x, y, 1.5 + rnd(i + 9) * 2); ctx.fillStyle = `rgba(255,255,240,${0.3 + 0.6 * tw})`; ctx.fill(); }
}
function dawnSky() { sky('#2b3a6b', '#f4a582', 1150); }
function daySky() { sky('#7cc4ee', '#d8f0fb', 1100); }
function seaSurface(y, t, o = {}) {
  const g = ctx.createLinearGradient(0, y, 0, H); g.addColorStop(0, o.c1 || SEA); g.addColorStop(1, o.c2 || SEA_D);
  P(); ctx.moveTo(0, H); for (let x = 0; x <= W; x += 12) ctx.lineTo(x, y + Math.sin(x / 70 + t * 1.6) * 7 + Math.sin(x / 23 - t * 2.3) * 3); ctx.lineTo(W, H); ctx.closePath();
  ctx.fillStyle = g; ctx.fill();
  ctx.strokeStyle = o.foam || 'rgba(207,232,243,0.45)'; ctx.lineWidth = 3;
  for (let r = 0; r < 5; r++) { const yy = y + 40 + r * 60; for (let x = (r * 97 + t * 30) % 160 - 160; x < W; x += 160) { P(); ctx.moveTo(x, yy); ctx.quadraticCurveTo(x + 30, yy - 8, x + 60, yy); ctx.stroke(); } }
}
function grain(t) {
  const f = Math.floor(t * 30);
  ctx.fillStyle = 'rgba(255,255,255,0.05)';
  for (let i = 0; i < 160; i++) { ctx.fillRect(rnd(i + f * 7) * W, rnd(i * 3 + f) * H, 2, 2); }
  const v = ctx.createRadialGradient(540, 900, 500, 540, 900, 1250); v.addColorStop(0, 'rgba(0,0,0,0)'); v.addColorStop(1, 'rgba(0,0,0,0.55)'); ctx.fillStyle = v; ctx.fillRect(0, 0, W, H);
}
function headerH(ep, title) {
  const g = ctx.createLinearGradient(0, 0, 0, 380); g.addColorStop(0, 'rgba(5,10,20,0.85)'); g.addColorStop(1, 'rgba(5,10,20,0)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, 380);
  pill(ep, 540, 170, 30, GOLDH, OUT, { lw: 0 });
  stxtH(title, 540, 278, 62, PAPER, { stroke: 10 });
  const g2 = ctx.createLinearGradient(0, 1250, 0, 1560); g2.addColorStop(0, 'rgba(5,10,20,0)'); g2.addColorStop(1, 'rgba(5,10,20,0.7)'); ctx.fillStyle = g2; ctx.fillRect(0, 1250, W, 310);
}
function shakeAt(t, times, amp = 22) { let a = 0; for (const c of times) if (t >= c) a += amp * Math.exp(-(t - c) * 6); return [Math.sin(t * 91) * a, Math.cos(t * 73) * a]; }
function tag(text, x, y, p, o = {}) {
  at(x, y, p, o.rot || 0, () => {
    const size = o.size || 38;
    ctx.save(); ctx.font = `700 ${size}px ${o.mono ? MONO : SERIFH}`; const w = ctx.measureText(text).width + 60; ctx.restore();
    rr(-w / 2, -size * 0.85, w, size * 1.7, o.r ?? 10); fs(o.bg || PAPER, 5, o.line || OUT);
    stxtH(text, 0, 3, size, o.fg || OUT, { mono: o.mono });
  });
}
function stampH(text, x, y, p, col = '#c92a2a', rot = -0.12, size = 70) {
  if (p <= 0) return;
  at(x, y, lerp(2.2, 1, eOut(clamp(p))), rot, () => alpha(clamp(p * 3), () => {
    ctx.save(); ctx.font = `900 ${size}px ${SERIFH}`; const w = ctx.measureText(text).width + 50; ctx.restore();
    rr(-w / 2, -size * 0.75, w, size * 1.5, 10); fs(null, 9, col); stxtH(text, 0, 4, size, col, { weight: 900 });
  }));
}
function thermo(x, y, label, p = 1) {
  at(x, y, p, 0, () => {
    rr(-26, -200, 52, 230, 26); fs('#fff', 6, OUT); circ(0, 40, 44); fs('#4dabf7', 6, OUT);
    rr(-12, -40, 24, 80, 10); ctx.fillStyle = '#4dabf7'; ctx.fill();
    for (let i = 0; i < 6; i++) seg(10, -180 + i * 28, 26, -180 + i * 28, 4, OUT);
    stxtH(label, 0, 130, 54, '#fff', { stroke: 9 });
  });
}
function clockH(x, y, hours, p = 1, label) {
  at(x, y, p, 0, () => {
    circ(0, 0, 90); fs(PAPER, 7, OUT);
    for (let i = 0; i < 12; i++) { const a = i / 12 * Math.PI * 2; seg(Math.cos(a) * 70, Math.sin(a) * 70, Math.cos(a) * 80, Math.sin(a) * 80, 5, OUT); }
    const ma = hours * Math.PI * 2 - Math.PI / 2, ha = hours / 12 * Math.PI * 2 - Math.PI / 2;
    seg(0, 0, Math.cos(ha) * 45, Math.sin(ha) * 45, 9, OUT); seg(0, 0, Math.cos(ma) * 68, Math.sin(ma) * 68, 6, OUT);
    if (label) stxtH(label, 0, 140, 50, '#fff', { stroke: 9 });
  });
}

/* ---------- Schiffe ---------- */
/* Olympic-Klasse, Bug rechts, Ursprung = Wasserlinie Mitte. o: hull ('black'|'white'), band (Farbe), crosses, lights, funnels, tilt, smoke, t */
function liner(x, y, s, o = {}) {
  const t = o.t || 0, white = o.hull === 'white';
  at(x, y, s, o.tilt || 0, () => {
    if (o.smoke !== false) for (let f = 0; f < 3; f++) for (let i = 0; i < 6; i++) { const u = ((t * 0.4 + i / 6) % 1); circ(-230 + f * 140 - u * 260, -330 - u * 140, 20 + u * 40); ctx.fillStyle = `rgba(80,80,90,${0.35 * (1 - u)})`; ctx.fill(); }
    seg(-440, -100, -430, -430, 5, OUT); seg(400, -100, 390, -430, 5, OUT); seg(-430, -420, 390, -420, 2, OUT);
    // Schornsteine
    for (let i = 0; i < 4; i++) { const fx = -230 + i * 140; P(); ctx.moveTo(fx - 26, -180); ctx.lineTo(fx - 40, -330); ctx.lineTo(fx + 12, -330); ctx.lineTo(fx + 26, -180); ctx.closePath(); fs(BUFF, 4, OUT); P(); ctx.moveTo(fx - 37, -300); ctx.lineTo(fx - 40, -330); ctx.lineTo(fx + 12, -330); ctx.lineTo(fx + 14, -300); ctx.closePath(); ctx.fillStyle = '#111'; ctx.fill(); }
    // Aufbauten
    rr(-340, -150, 660, 60, 4); fs('#ece6d6', 4, OUT); rr(-280, -186, 520, 40, 4); fs('#ece6d6', 4, OUT);
    for (let i = 0; i < 8; i++) { rr(-320 + i * 80, -170, 44, 14, 6); fs('#fff', 2, OUT); }
    // Rumpf
    P(); ctx.moveTo(-500, -100); ctx.lineTo(470, -100); ctx.lineTo(500, -110); ctx.lineTo(460, 60); ctx.lineTo(-440, 60); ctx.quadraticCurveTo(-500, 40, -505, -40); ctx.closePath();
    fs(white ? '#f4f4f0' : '#15181c', 5, OUT);
    ctx.save(); ctx.clip(); ctx.fillStyle = white ? '#2b8a3e' : RUST; ctx.fillRect(-520, 0, 1040, 70);
    if (white) { ctx.fillStyle = o.band || '#2f9e44'; ctx.fillRect(-520, -62, 1040, 18); }
    else { ctx.fillStyle = '#e8e2d0'; ctx.fillRect(-520, -100, 1040, 8); }
    ctx.restore();
    if (o.lights !== false) for (let i = 0; i < 26; i++) { circ(-430 + i * 34, -72, 4.5); ctx.fillStyle = o.lights === 'off' ? '#333' : (white ? '#555' : '#ffe08a'); ctx.fill(); }
    if (o.crosses) for (const cx of [-260, 120]) { rr(cx - 34, -96, 68, 30, 3); ctx.fillStyle = '#fff'; ctx.fill(); ctx.fillStyle = '#e03131'; ctx.fillRect(cx - 30, -88, 60, 14); ctx.fillRect(cx - 7, -110, 14, 58); }
    if (o.name) stxtH(o.name, 300, -82, 20, white ? OUT : '#e8e2d0');
  });
}
/* kleineres Schiff mit einem Schornstein (Carpathia) */
function smallShip(x, y, s, o = {}) {
  at(x, y, s, 0, () => {
    seg(-260, -80, -255, -300, 4, OUT); seg(240, -80, 235, -300, 4, OUT);
    P(); ctx.moveTo(-30, -150); ctx.lineTo(-44, -300); ctx.lineTo(14, -300); ctx.lineTo(28, -150); ctx.closePath(); fs('#c0392b', 4, OUT); ctx.fillStyle = '#111'; ctx.fillRect(-44, -300, 58, 26);
    rr(-180, -150, 360, 70, 4); fs('#ece6d6', 4, OUT);
    P(); ctx.moveTo(-310, -80); ctx.lineTo(300, -80); ctx.lineTo(330, -90); ctx.lineTo(300, 50); ctx.lineTo(-280, 50); ctx.quadraticCurveTo(-320, 30, -315, -20); ctx.closePath(); fs('#1c1f24', 5, OUT);
    if (o.name) stxtH(o.name, 0, -40, 26, '#e8e2d0');
  });
}
/* Kriegsschiff (Kreuzer) mit Rammbug, Bug rechts */
function warship(x, y, s) {
  at(x, y, s, 0, () => {
    for (const fx of [-60, 60]) { rr(fx - 24, -230, 48, 140, 4); fs('#8a939b', 4, OUT); }
    rr(-200, -110, 380, 40, 4); fs('#9aa3ab', 4, OUT);
    seg(120, -100, 230, -150, 10, OUT); seg(-150, -100, -250, -140, 10, OUT);
    P(); ctx.moveTo(-380, -70); ctx.lineTo(330, -70); ctx.lineTo(400, 30); ctx.lineTo(330, 50); ctx.lineTo(-340, 50); ctx.quadraticCurveTo(-385, 20, -380, -70); ctx.closePath(); fs('#6c757d', 5, OUT);
  });
}
function lifeboat(x, y, s, o = {}) {
  at(x, y, s, o.rot || 0, () => {
    if (o.people) for (let i = 0; i < o.people; i++) { const px = -150 + i * (300 / Math.max(1, o.people - 1)); circ(px, -40, 20); ctx.fillStyle = ['#e9c39b', '#c98b5a', '#f1d1b0'][i % 3]; ctx.fill(); ctx.lineWidth = 3; ctx.strokeStyle = OUT; ctx.stroke(); rr(px - 18, -24, 36, 30, 8); ctx.fillStyle = ['#495057', '#7a4a2a', '#2f3e46'][i % 3]; ctx.fill(); }
    P(); ctx.moveTo(-210, -20); ctx.lineTo(210, -20); ctx.quadraticCurveTo(200, 40, 140, 50); ctx.lineTo(-140, 50); ctx.quadraticCurveTo(-200, 40, -210, -20); ctx.closePath(); fs(o.col || '#f8f9fa', 6, OUT);
    seg(-200, -6, 200, -6, 4, '#adb5bd');
    if (o.num) stxtH(String(o.num), 0, 18, 30, OUT);
  });
}

/* ---------- Figuren (flacher Cartoon) ----------
   Ursprung = Füße. o: dir, role ('baker'|'stew'|'nurse'|'woman'|'man'|'officer'), aF/aB [Schulter, Ellbogen], eye, mouth, hold, blush, hair */
const SKINH = '#f1c9a5';
function person(x, y, s, o = {}) {
  const d = o.dir || 1, role = o.role || 'man', fem = ['stew', 'nurse', 'woman'].includes(role);
  const coat = o.coat || { baker: '#f8f9fa', stew: '#22313f', nurse: '#f8f9fa', woman: '#7b4b94', man: '#3b4a5a', officer: '#1d2b3a' }[role];
  ctx.save(); ctx.translate(x, y); ctx.scale(s * d, s);
  const limbC = (x1, y1, x2, y2, w, c) => { seg(x1, y1, x2, y2, w + 8, OUT); seg(x1, y1, x2, y2, w, c); };
  // Beine / Rock
  if (o.pose !== 'swim') {
    if (fem) { P(); ctx.moveTo(-60, -230); ctx.lineTo(60, -230); ctx.lineTo(80, -10); ctx.lineTo(-80, -10); ctx.closePath(); fs(coat, 6, OUT); ell(-30, -6, 26, 10); ell(30, -6, 26, 10); ctx.fillStyle = '#222'; ctx.fill(); }
    else { const sw = o.pose === 'walk' ? Math.sin((o.ph || 0) * Math.PI * 2) * 0.4 : 0.06; for (const k of [-1, 1]) { const a = sw * k; limbC(k * 22, -200, k * 22 + Math.sin(a) * 190, -200 + Math.cos(a) * 190, 34, role === 'baker' ? '#dee2e6' : '#2b2f36'); ell(k * 22 + Math.sin(a) * 190 + 14, -8, 30, 12); ctx.fillStyle = '#222'; ctx.fill(); } }
  }
  // Rumpf
  rr(-62, -360, 124, 170, 40); fs(coat, 6, OUT);
  if (role === 'baker') { for (const k of [-1, 1]) for (let i = 0; i < 3; i++) { circ(k * 18, -320 + i * 38, 5); ctx.fillStyle = '#adb5bd'; ctx.fill(); } }
  if (role === 'stew') { rr(-40, -330, 80, 150, 14); fs('#fff', 4, OUT); }
  if (role === 'nurse') { rr(-40, -330, 80, 150, 14); fs('#fff', 4, OUT); ctx.fillStyle = '#e03131'; ctx.fillRect(-14, -300, 28, 8); ctx.fillRect(-4, -310, 8, 28); }
  if (role === 'officer') for (let i = 0; i < 3; i++) { circ(20, -330 + i * 40, 5); ctx.fillStyle = BUFF; ctx.fill(); }
  // Arme
  const arm = ang => { const [a1, a2] = ang; const sx = 0, sy = -335, L1 = 90, L2 = 86; const ex = sx + Math.sin(a1) * L1, ey = sy + Math.cos(a1) * L1, hx = ex + Math.sin(a1 + a2) * L2, hy = ey + Math.cos(a1 + a2) * L2; limbC(sx, sy, ex, ey, 30, coat); limbC(ex, ey, hx, hy, 26, coat); circ(hx, hy, 17); fs(SKINH, 5, OUT); return [hx, hy]; };
  arm(o.aB || [-0.2, 0.2]);
  // Kopf
  const hy = -420;
  if (o.hairLong || fem) { P(); ctx.ellipse(-6, hy + 10, 66, 74, 0, 0, Math.PI * 2); ctx.fillStyle = o.hair || '#6b3a1e'; ctx.fill(); }
  circ(0, hy, 58); fs(SKINH, 6, OUT);
  P(); ctx.arc(0, hy - 6, 60, Math.PI * 1.05, Math.PI * 1.95); ctx.closePath(); ctx.fillStyle = o.hair || (fem ? '#6b3a1e' : '#4a3020'); ctx.fill();
  if (role === 'baker') { rr(-50, hy - 120, 100, 70, 10); fs('#fff', 5, OUT); for (const k of [-36, 0, 36]) { circ(k, hy - 122, 30); fs('#fff', 5, OUT); } rr(-52, hy - 66, 104, 22, 6); fs('#fff', 5, OUT); }
  if (role === 'stew') { rr(-46, hy - 76, 92, 26, 8); fs('#fff', 4, OUT); }
  if (role === 'nurse') { P(); ctx.moveTo(-64, hy - 40); ctx.quadraticCurveTo(0, hy - 90, 64, hy - 40); ctx.lineTo(70, hy + 60); ctx.lineTo(40, hy + 40); ctx.lineTo(40, hy - 30); ctx.lineTo(-40, hy - 30); ctx.lineTo(-40, hy + 40); ctx.lineTo(-70, hy + 60); ctx.closePath(); fs('#fff', 4, OUT); ctx.fillStyle = '#e03131'; ctx.fillRect(-8, hy - 64, 16, 5); ctx.fillRect(-2.5, hy - 70, 5, 17); }
  if (role === 'officer') { rr(-56, hy - 74, 112, 30, 6); fs('#1d2b3a', 4, OUT); rr(-20, hy - 60, 70, 14, 6); fs('#111', 0); }
  // Gesicht (Profil-leicht: nach rechts versetzt)
  const eye = o.eye || 'open';
  for (const ex of [8, 36]) {
    if (eye === 'closed' || eye === 'drunk') { P(); ctx.arc(ex, hy - 6, 8, eye === 'drunk' ? 0.2 : Math.PI + 0.3, eye === 'drunk' ? Math.PI - 0.2 : -0.3, eye !== 'drunk'); ctx.lineWidth = 4; ctx.strokeStyle = OUT; ctx.stroke(); }
    else { circ(ex, hy - 6, eye === 'wide' ? 11 : 7); ctx.fillStyle = eye === 'wide' ? '#fff' : OUT; ctx.fill(); if (eye === 'wide') { ctx.lineWidth = 3; ctx.strokeStyle = OUT; ctx.stroke(); circ(ex + 2, hy - 6, 5); ctx.fillStyle = OUT; ctx.fill(); } }
  }
  if (o.blush) for (const ex of [0, 44]) { ell(ex, hy + 16, 14, 8); ctx.fillStyle = 'rgba(240,80,80,0.55)'; ctx.fill(); }
  if (role === 'baker') { P(); ctx.moveTo(6, hy + 24); ctx.quadraticCurveTo(24, hy + 12, 44, hy + 24); ctx.quadraticCurveTo(24, hy + 34, 6, hy + 24); ctx.fillStyle = '#4a3020'; ctx.fill(); }
  const m = o.mouth || 0;
  if (m > 0.1) { ell(24, hy + 36, 10, 4 + 10 * m); fs('#7a1f2b', 3, OUT); }
  else { P(); ctx.arc(24, hy + 28, 14, 0.25, Math.PI - 0.25); ctx.lineWidth = 4; ctx.strokeStyle = OUT; ctx.stroke(); }
  const [hx, hy2] = arm(o.aF || [0.2, 0.2]);
  if (o.hold) heldItem(o.hold, hx, hy2);
  ctx.restore();
}
function heldItem(kind, x, y) {
  ctx.save(); ctx.translate(x, y);
  if (kind === 'bottle') { rr(-14, -70, 28, 80, 8); fs('#2f9e44', 4, OUT); rr(-6, -96, 12, 30, 4); fs('#2f9e44', 4, OUT); rr(-12, -44, 24, 26, 3); ctx.fillStyle = PAPER; ctx.fill(); }
  else if (kind === 'glass') { P(); ctx.moveTo(-22, -70); ctx.lineTo(22, -70); ctx.lineTo(14, 0); ctx.lineTo(-14, 0); ctx.closePath(); fs('rgba(255,255,255,0.5)', 4, OUT); P(); ctx.moveTo(-18, -40); ctx.lineTo(18, -40); ctx.lineTo(14, 0); ctx.lineTo(-14, 0); ctx.closePath(); ctx.fillStyle = '#c2410c'; ctx.fill(); }
  else if (kind === 'bread') { for (let i = 0; i < 4; i++) { ell(-10 + i * 6, -20 - i * 26, 50, 20); fs('#d9a066', 4, OUT); } }
  else if (kind === 'baby') { ell(10, -20, 56, 34); fs('#fff', 5, OUT); circ(44, -34, 22); fs(SKINH, 4, OUT); }
  else if (kind === 'toothbrush') { ctx.rotate(-0.6); rr(-6, -110, 12, 120, 5); fs('#4dabf7', 4, OUT); rr(-10, -130, 20, 30, 4); fs('#fff', 3, OUT); }
  ctx.restore();
}
/* Kopf eines Schwimmers über Wasser */
function swimmer(x, y, s, o = {}) {
  person(x, y + 360 * s, s, Object.assign({ pose: 'swim' }, o));
}
function iceberg(x, y, s) {
  at(x, y, s, 0, () => { P(); ctx.moveTo(-200, 0); ctx.lineTo(-120, -160); ctx.lineTo(-60, -120); ctx.lineTo(0, -260); ctx.lineTo(80, -150); ctx.lineTo(140, -180); ctx.lineTo(210, 0); ctx.closePath(); fs('#e7f5ff', 6, '#5c7cfa'); P(); ctx.moveTo(0, -260); ctx.lineTo(30, -60); ctx.lineTo(80, -150); ctx.closePath(); ctx.fillStyle = '#a5d8ff'; ctx.fill(); });
}
function deckChair(x, y, s, rot) {
  at(x, y, s, rot, () => { seg(-50, 30, 40, -40, 10, '#8d5524'); seg(-50, -10, 50, 30, 10, '#8d5524'); seg(40, -40, 60, -10, 8, '#8d5524'); });
}
function sceneAtH(t, list) {
  const st = list.map((it, i) => i === 0 ? 0 : (typeof it[0] === 'number' ? it[0] : T(it[0]) - 0.12));
  let ci = 0; st.forEach((s, i) => { if (t >= s) ci = i; });
  list[ci][1](t, t - st[ci]);
  const lt = t - st[ci], D = 0.35;  // weiche Überblendung statt Schwarzblende
  if (ci > 0 && lt < D) alpha(1 - eIO(lt / D), () => list[ci - 1][1](t, t - st[ci - 1]));
}
