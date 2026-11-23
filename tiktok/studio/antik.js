'use strict';
/* Baukasten für die Philosophie-Serie: schwarzfigurige Vasenmalerei (Terrakotta + Glanzton-Schwarz). Lädt nach engine.js. */
const TERRA = '#d9793b', TERRA_D = '#b65a25', TERRA_L = '#eea06a', BLK = '#1c120c', CREAM = '#f3e2c0', PURP = '#8e2d1c', GOLD = '#ffd36b';
const SERIF = '"Liberation Serif", "DejaVu Serif", serif';
window.EP_CAPCOL = { P: GOLD };

/* ---------- Hintergrund & Ornamente ---------- */
function vaseBg() {
  const g = ctx.createRadialGradient(540, 820, 120, 540, 900, 1100);
  g.addColorStop(0, '#eb9150'); g.addColorStop(0.6, TERRA); g.addColorStop(1, '#a84f1f');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
}
function meander(y, h = 44, col = BLK) {
  ctx.fillStyle = col; ctx.fillRect(0, y - 6, W, 5); ctx.fillRect(0, y + h + 1, W, 5);
  const u = h / 4;
  ctx.strokeStyle = col; ctx.lineWidth = u * 0.62; ctx.lineCap = 'butt'; ctx.lineJoin = 'miter';
  for (let x = -h; x < W + h; x += h * 1.25) {
    P(); ctx.moveTo(x, y + h - u * 0.5); ctx.lineTo(x, y + u * 0.5); ctx.lineTo(x + h, y + u * 0.5); ctx.lineTo(x + h, y + h - u * 0.5);
    ctx.lineTo(x + u * 1.6, y + h - u * 0.5); ctx.lineTo(x + u * 1.6, y + u * 2); ctx.lineTo(x + h - u * 1.4, y + u * 2); ctx.stroke();
  }
}
function tongues(y, n = 18, col = BLK) { // Zungenfries
  const w = W / n;
  for (let i = 0; i < n; i++) { P(); ctx.ellipse(i * w + w / 2, y, w * 0.36, 26, 0, 0, Math.PI); ctx.fillStyle = i % 2 ? col : PURP; ctx.fill(); }
}
/* Fries-Rahmen: oben Serie + Titel, Bildfeld 430–1250, Untertitel darunter */
function frame(ep, title) {
  meander(392, 40); meander(1262, 40);
  pill(ep, 540, 170, 30, BLK, CREAM, { lw: 0 });
  stxt(title, 540, 285, 66, CREAM, { stroke: 10 });
}
function stxt(s, x, y, size, col, o = {}) {
  ctx.save(); ctx.font = `${o.italic ? 'italic ' : ''}700 ${size}px ${SERIF}`; ctx.textAlign = o.align || 'center'; ctx.textBaseline = 'middle';
  ctx.translate(x, y); if (o.rot) ctx.rotate(o.rot);
  const w = ctx.measureText(s).width; const mw = o.maxW || 980; if (w > mw) ctx.scale(mw / w, mw / w);
  if (o.ls) ctx.letterSpacing = `${o.ls}px`;
  if (o.stroke) { ctx.lineWidth = o.stroke; ctx.strokeStyle = o.sc || BLK; ctx.lineJoin = 'round'; ctx.strokeText(s, 0, 0); }
  ctx.fillStyle = col; ctx.fillText(s, 0, 0); ctx.restore();
}
/* Mehrzeiliges Zitat auf Pergament-Karte */
function quoteCard(lines, who, x, y, p, o = {}) {
  at(x, y, p, o.rot || 0, () => {
    const lh = o.size ? o.size * 1.25 : 70, h = lines.length * lh + (who ? 120 : 70), w = o.w || 900;
    rr(-w / 2, -h / 2, w, h, 26); fs(CREAM, 8, BLK);
    rr(-w / 2 + 16, -h / 2 + 16, w - 32, h - 32, 18); fs(null, 3, TERRA_D);
    lines.forEach((ln, i) => stxt(ln, 0, -h / 2 + 60 + i * lh, o.size || 56, BLK, { italic: true, maxW: w - 80 }));
    if (who) stxt(who, 0, h / 2 - 48, 34, TERRA_D, { maxW: w - 80 });
  });
}
function sbubble(text, x, y, p, o = {}) {
  at(x, y, p, o.rot || 0, () => {
    const size = o.size || 46, lines = Array.isArray(text) ? text : [text];
    ctx.save(); ctx.font = `700 ${size}px ${SERIF}`; const w = Math.max(...lines.map(l => ctx.measureText(l).width)) + 70; ctx.restore();
    const h = lines.length * size * 1.2 + 44, tx = o.tail || 0;
    P(); ctx.roundRect(-w / 2, -h / 2, w, h, 30); ctx.moveTo(tx - 22, h / 2 - 2); ctx.lineTo(tx + (o.tdx || -30), h / 2 + 50); ctx.lineTo(tx + 22, h / 2 - 2);
    fs(CREAM, 6, BLK); P(); ctx.rect(tx - 20, h / 2 - 8, 40, 10); ctx.fillStyle = CREAM; ctx.fill();
    lines.forEach((l, i) => stxt(l, 0, -h / 2 + 22 + size * 0.6 + i * size * 1.2, size, BLK));
  });
}
function sunDisc(x, y, r, t, a = 1) {
  alpha(a, () => {
    ctx.save(); ctx.translate(x, y); ctx.rotate(t * 0.2);
    for (let i = 0; i < 16; i++) { P(); ctx.moveTo(0, 0); ctx.arc(0, 0, r * 2.2, i / 16 * Math.PI * 2, (i + 0.5) / 16 * Math.PI * 2); ctx.closePath(); ctx.fillStyle = 'rgba(255,211,107,0.22)'; ctx.fill(); }
    ctx.restore();
    circ(x, y, r); fs(GOLD, 6, BLK);
  });
}

/* ---------- Figuren (schwarzfigurig, Profil) ----------
   Ursprung = Füße. o: dir (+1 schaut nach rechts), beard, helmet, cloak, pose ('stand'|'walk'|'sit'|'lie'), ph (Schrittphase),
   aF/aB [Schulter, Ellbogen] Winkel vorderer/hinterer Arm (0 = hängt, positiv nach vorn), mouth (0–1), eye ('open'|'wide'|'closed'|'calm'),
   hold ('bowl'|'lamp'|'staff'|'chicken'|'spear'), robe (Farbe), scale */
function bl(x1, y1, x2, y2, w) { seg(x1, y1, x2, y2, w, BLK); }
function fig(x, y, s, o = {}) {
  const d = o.dir || 1, pose = o.pose || 'stand';
  ctx.save(); ctx.translate(x, y); ctx.scale(s * d, s);
  const robe = o.robe || BLK, ph = o.ph || 0;
  const hipY = pose === 'sit' ? -150 : -210;
  // Beine
  if (pose === 'stand' || pose === 'walk') {
    const sw = pose === 'walk' ? Math.sin(ph * Math.PI * 2) * 0.45 : 0.08;
    for (const k of [-1, 1]) { const a = sw * k, fx = Math.sin(a) * 200, fy = hipY + Math.cos(a) * 200; bl(0, hipY, fx, fy, 30); ell(fx + 22, fy - 4, 34, 12); ctx.fillStyle = BLK; ctx.fill(); }
  } else if (pose === 'sit') {
    const fy = o.footY ?? -10; bl(0, hipY, 110, hipY + 10, 34); bl(110, hipY + 10, 120 + (o.legOut || 0), fy, 30); ell(140 + (o.legOut || 0), fy + 4, 32, 12); ctx.fillStyle = BLK; ctx.fill();
  }
  if (o.cloak) { P(); ctx.moveTo(-20, -350); ctx.quadraticCurveTo(-140 - Math.sin(ph * 6) * 10, -250, -110, -110); ctx.lineTo(-30, -130); ctx.closePath(); ctx.fillStyle = o.cloak; ctx.fill(); }
  // Gewand (Chiton/Himation)
  P(); ctx.moveTo(-46, -350); ctx.lineTo(46, -350); ctx.lineTo(pose === 'sit' ? 120 : 70, pose === 'sit' ? -140 : -112); ctx.lineTo(pose === 'sit' ? -60 : -74, pose === 'sit' ? -140 : -112); ctx.closePath();
  ctx.fillStyle = robe; ctx.fill();
  ctx.strokeStyle = robe === BLK ? TERRA_L : BLK; ctx.lineWidth = 2.5;
  for (let i = 0; i < 4; i++) { P(); ctx.moveTo(-28 + i * 20, -330); ctx.quadraticCurveTo(-34 + i * 24, -230, -48 + i * 30, -122); ctx.stroke(); }
  if (o.belt !== false) seg(-48, -265, 50, -265, 5, robe === BLK ? TERRA_L : BLK);
  // Arme: Schulter (0,-335)
  const arm = (ang, side) => {
    const [a1, a2] = ang; const L1 = 100, L2 = 92;
    const ex = Math.sin(a1) * L1, ey = -335 + Math.cos(a1) * L1;
    const hx = ex + Math.sin(a1 + a2) * L2, hy = ey + Math.cos(a1 + a2) * L2;
    bl(0, -335, ex, ey, 26); bl(ex, ey, hx, hy, 22); circ(hx, hy, 15); ctx.fillStyle = BLK; ctx.fill();
    return [hx, hy, a1 + a2];
  };
  arm(o.aB || [-0.25, 0.3], 0);
  // Kopf
  const hy = -398;
  circ(4, hy, 44); ctx.fillStyle = BLK; ctx.fill();
  P(); ctx.moveTo(40, hy - 14); ctx.lineTo(62, hy + 6); ctx.lineTo(40, hy + 10); ctx.closePath(); ctx.fill(); // Nase
  if (o.beard) { P(); ctx.moveTo(-10, hy + 20); ctx.quadraticCurveTo(10, hy + (o.beard === 'long' ? 120 : 84), 46, hy + 26); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = TERRA_L; ctx.lineWidth = 2; for (let i = 0; i < 3; i++) { P(); ctx.moveTo(4 + i * 12, hy + 32); ctx.lineTo(8 + i * 10, hy + (o.beard === 'long' ? 92 : 66)); ctx.stroke(); } }
  // Haar / Haarband
  P(); ctx.arc(-6, hy - 6, 44, Math.PI * 0.85, Math.PI * 1.7); ctx.lineWidth = 3; ctx.strokeStyle = TERRA_L; ctx.stroke();
  if (o.helmet) {
    P(); ctx.arc(4, hy - 4, 52, Math.PI * 0.9, Math.PI * 2.05); ctx.lineTo(56, hy + 30); ctx.lineTo(30, hy + 30); ctx.lineTo(28, hy + 2); ctx.lineTo(-40, hy + 6); ctx.closePath(); fs(BLK, 4, TERRA_L);
    P(); ctx.moveTo(-50, hy - 40); ctx.quadraticCurveTo(0, hy - 140 - Math.sin(ph * 6) * 6, 70, hy - 46); ctx.quadraticCurveTo(0, hy - 100, -50, hy - 40); ctx.fillStyle = PURP; ctx.fill();
  }
  // Auge (aufgetragenes Weiß) + Mund
  const eye = o.eye || 'open';
  if (eye === 'closed' || eye === 'calm') { P(); ctx.arc(22, hy - 8, 10, eye === 'calm' ? 0.1 : Math.PI + 0.2, eye === 'calm' ? Math.PI - 0.1 : -0.2, eye !== 'calm'); ctx.lineWidth = 4; ctx.strokeStyle = CREAM; ctx.stroke(); }
  else { const r = eye === 'wide' ? 14 : 10; ell(24, hy - 8, r * 1.35, r); ctx.fillStyle = CREAM; ctx.fill(); circ(28, hy - 8, r * 0.55); ctx.fillStyle = BLK; ctx.fill(); }
  const m = o.mouth || 0;
  if (!o.beard || o.helmet) { if (m > 0.1) { ell(44, hy + 22, 7, 3 + m * 8); ctx.fillStyle = PURP; ctx.fill(); } else seg(36, hy + 22, 48, hy + 22, 3, TERRA_L); }
  else if (m > 0.1) { ell(42, hy + 20, 7, 3 + m * 8); ctx.fillStyle = PURP; ctx.fill(); }
  // vorderer Arm + Gegenstand
  const [hx2, hy2, ha] = arm(o.aF || [0.25, 0.2], 1);
  if (o.hold) holdItem(o.hold, hx2, hy2, ha, o);
  ctx.restore();
}
function holdItem(kind, x, y, a, o) {
  ctx.save(); ctx.translate(x, y);
  if (kind === 'staff') { seg(0, -170, 0, 220, 10, BLK); }
  else if (kind === 'spear') { seg(0, -300, 0, 260, 8, BLK); P(); ctx.moveTo(-14, -300); ctx.lineTo(0, -360); ctx.lineTo(14, -300); ctx.closePath(); ctx.fillStyle = BLK; ctx.fill(); }
  else if (kind === 'bowl') { P(); ctx.ellipse(0, -14, 46, 22, 0, 0, Math.PI); fs(CREAM, 5, BLK); seg(-46, -14, 46, -14, 5, BLK); }
  else if (kind === 'lamp') { seg(0, 0, 0, 40, 4, BLK); ctx.save(); ctx.shadowColor = GOLD; ctx.shadowBlur = 60; rr(-26, 40, 52, 70, 10); fs(GOLD, 5, BLK); ctx.restore(); seg(-26, 75, 26, 75, 3, BLK); circ(0, 75, 10); ctx.fillStyle = '#fff3bf'; ctx.fill(); }
  else if (kind === 'chicken') { ctx.rotate(-a + (o.chickRot || 0)); plucked(0, -70, 0.9); }
  ctx.restore();
}
/* Gerupftes Huhn */
function plucked(x, y, s) {
  at(x, y, s, 0, () => {
    for (const k of [-1, 1]) { seg(k * 22, 50, k * 30, 120, 6, '#e8a33d'); seg(k * 30, 120, k * 48, 128, 5, '#e8a33d'); seg(k * 30, 120, k * 16, 130, 5, '#e8a33d'); }
    ell(0, 0, 70, 62); fs('#f6c9b3', 6, BLK);
    for (let i = 0; i < 9; i++) { circ(-40 + rnd(i) * 80, -30 + rnd(i + 4) * 60, 3); ctx.fillStyle = '#d39a86'; ctx.fill(); }
    P(); ctx.moveTo(40, -30); ctx.quadraticCurveTo(70, -90, 62, -120); ctx.lineWidth = 22; ctx.strokeStyle = BLK; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 14; ctx.strokeStyle = '#f6c9b3'; ctx.stroke();
    circ(64, -134, 26); fs('#f6c9b3', 5, BLK); P(); ctx.moveTo(86, -138); ctx.lineTo(112, -128); ctx.lineTo(86, -122); ctx.closePath(); fs('#e8a33d', 3, BLK);
    for (let i = 0; i < 3; i++) { circ(52 + i * 10, -162 + (i % 2) * 4, 9); ctx.fillStyle = '#d6332a'; ctx.fill(); }
    circ(72, -140, 5); ctx.fillStyle = BLK; ctx.fill();
  });
}
/* Pithos (großer Tonkrug), liegend; Öffnung zeigt nach rechts */
function pithos(x, y, s, o = {}) {
  at(x, y, s, o.rot || 0, () => {
    const body = () => { P(); ctx.moveTo(180, -70); ctx.bezierCurveTo(120, -175, -60, -180, -170, -140); ctx.bezierCurveTo(-275, -100, -275, 100, -170, 140); ctx.bezierCurveTo(-60, 180, 120, 175, 180, 70); ctx.closePath(); };
    body(); fs(TERRA_L, 8, BLK);
    ctx.save(); body(); ctx.clip();
    ctx.fillStyle = BLK; ctx.fillRect(-60, -200, 22, 400); ctx.fillRect(96, -200, 14, 400);
    for (let k = -6; k <= 6; k++) { circ(30, k * 26, 6); ctx.fill(); }
    ctx.strokeStyle = 'rgba(255,240,210,0.35)'; ctx.lineWidth = 18; P(); ctx.arc(-40, -40, 120, Math.PI * 1.1, Math.PI * 1.45); ctx.stroke();
    ctx.restore();
    rr(176, -72, 60, 144, 6); fs(TERRA_D, 7, BLK);
    ell(246, 0, 24, 94); fs(TERRA_D, 7, BLK); ell(252, 0, 14, 72); ctx.fillStyle = '#2a140a'; ctx.fill();
  });
}
/* Holzfass (das Klischee) */
function barrel(x, y, s) {
  at(x, y, s, 0, () => {
    P(); ctx.moveTo(-150, -260); ctx.quadraticCurveTo(-200, -130, -150, 0); ctx.lineTo(150, 0); ctx.quadraticCurveTo(200, -130, 150, -260); ctx.closePath(); fs('#a0622d', 8, BLK);
    for (const yy of [-60, -200]) { P(); ctx.moveTo(-172, yy); ctx.quadraticCurveTo(0, yy + 16, 172, yy); ctx.lineWidth = 14; ctx.strokeStyle = '#555'; ctx.stroke(); }
    for (const xx of [-80, 0, 80]) seg(xx, -255, xx * 1.1, -5, 3, '#6b3d18');
    ell(0, -260, 150, 34); fs('#5a3416', 7, BLK);
  });
}
function column(x, y, h, s = 1) {
  at(x, y, s, 0, () => {
    rr(-60, -h, 120, h, 4); ctx.fillStyle = CREAM; ctx.fill(); for (let i = -2; i <= 2; i++) seg(i * 22, -h + 30, i * 22, -10, 4, '#c9b48e');
    rr(-60, -h, 120, h, 4); fs(null, 5, BLK);
    rr(-84, -h - 34, 168, 34, 6); fs(CREAM, 5, BLK); rr(-72, -10, 144, 14, 4); fs(CREAM, 5, BLK);
  });
}
/* Kinder-Figur (kleiner, ohne Bart) */
function child(x, y, s, o = {}) { fig(x, y, s * 0.62, Object.assign({ beard: false }, o)); }
function ground(y) { seg(40, y, 1040, y, 6, BLK); for (let x = 60; x < 1040; x += 90) seg(x, y + 14, x + 40, y + 14, 3, TERRA_D); }
/* Szenenumschalter: [[zeilenId oder Zeit, fn]], fn(t, lt) */
function sceneAt(t, list) {
  const st = list.map((it, i) => i === 0 ? 0 : (typeof it[0] === 'number' ? it[0] : T(it[0]) - 0.12));
  let ci = 0; st.forEach((s, i) => { if (t >= s) ci = i; });
  list[ci][1](t, t - st[ci]);
  const lt = t - st[ci], D = 0.35;
  if (ci > 0 && lt < D) alpha(1 - eIO(lt / D), () => { ctx.fillStyle = TERRA; ctx.fillRect(0, 432, W, 830); list[ci - 1][1](t, t - st[ci - 1]); });
}
function chainIcon(x, y, s, broken = 0) {
  at(x, y, s, 0, () => {
    for (let i = 0; i < 4; i++) { const off = i >= 2 ? broken * 60 : -broken * 0; at((i - 1.5) * 70 + (i >= 2 ? broken * 40 : -broken * 40), (i >= 2 ? broken * 30 : 0), 1, (i % 2) * 0.3 + (i >= 2 ? broken * 0.6 : 0), () => { ell(0, 0, 44, 26); fs(null, 12, BLK); }); }
  });
}
