'use strict';
/* Folge 2: Der Klamottenstuhl */
const WOOD = '#c98b50', WOOD_D = '#8d5a2b';
const CLOTH = ['#3a5bd9', '#ff6b6b', '#ffd23f', '#00b894', '#a29bfe', '#fd79a8', '#e17055', '#74b9ff', '#55efc4', '#fdcb6e'];

/* ---------- Requisiten ---------- */
function drawChair(o = {}) { // Boden y=0, Sitzfläche oben bei y=-290
  const c = o.col || WOOD, d = o.dark || WOOD_D;
  limb(-108, -260, -104, -30, 16, d); limb(108, -260, 104, -30, 16, d);
  limb(-122, -270, -114, -610, 20, c); limb(122, -270, 114, -610, 20, c);
  rr(-138, -655, 276, 72, 26); fs(c, 8);
  rr(-106, -525, 212, 28, 10); fs(c, 7);
  rr(-165, -292, 330, 46, 14); fs(c, 8);
  limb(-140, -250, -148, 0, 20, c); limb(140, -250, 148, 0, 20, c);
  seg(-142, -110, 142, -110, 10, d);
}
function drawPile(n, t, o = {}) { // auf der Sitzfläche, gibt obere Kante zurück
  const seed = o.seed || 1;
  let y = -290;
  ctx.save();
  if (o.breathe) { ctx.translate(0, -290); ctx.scale(1 + 0.015 * Math.sin(t * 2.2 + 1), 1 + 0.03 * Math.sin(t * 2.2)); ctx.translate(0, 290); }
  for (let i = 0; i < n; i++) {
    const w = 270 + rnd(i * 3 + seed) * 90;
    const h = o.fixedH || 36 + rnd(i * 5 + seed) * 22;
    const x = (rnd(i * 7 + seed) - 0.5) * 50;
    const rot = (rnd(i * 11 + seed) - 0.5) * 0.18;
    const col = o.cols ? o.cols(i) : CLOTH[Math.floor(rnd(i * 13 + seed) * CLOTH.length)];
    at(x, y - h / 2 + 6, 1, rot, () => {
      if (rnd(i * 17 + seed) > 0.45) { const sd = rnd(i * 19 + seed) > 0.5 ? 1 : -1; limb(sd * (w / 2 - 24), 0, sd * (w / 2 + 12), 60 + rnd(i + seed) * 60, 22, col); }
      rr(-w / 2, -h / 2, w, h, h / 2); fs(col, 7);
      const k = Math.floor(rnd(i * 23 + seed) * 3);
      if (k === 0) seg(-w / 2 + 34, 0, w / 2 - 34, 0, 5, 'rgba(255,255,255,0.4)');
      if (k === 1) { rr(-34, -h / 2 + 7, 68, h - 14, 6); fs('rgba(0,0,0,0.13)', 0); }
    });
    y -= (o.step || h - 8);
  }
  ctx.restore();
  return y;
}
function drawPullover(col) {
  limb(-92, -62, -150, 72, 40, col); limb(92, -62, 150, 72, 40, col);
  P(); ctx.moveTo(-102, -92); ctx.lineTo(102, -92); ctx.lineTo(96, 96); ctx.lineTo(-96, 96); ctx.closePath(); fs(col, 8);
  P(); ctx.ellipse(0, -90, 42, 20, 0, 0, Math.PI); fs('rgba(0,0,0,0.15)', 6);
  rr(-100, 78, 200, 28, 9); fs(col, 7);
  seg(-94, 4, 94, 4, 16, 'rgba(255,255,255,0.5)');
  seg(-94, 34, 94, 34, 8, 'rgba(255,255,255,0.35)');
}
function stains() { for (const [x, y, r] of [[-40, -30, 18], [30, 50, 14], [60, -50, 10], [-70, 60, 9]]) { ell(x, y, r * 1.3, r); ctx.fillStyle = 'rgba(110,80,50,0.65)'; ctx.fill(); } }
function stinkUp(x, y, t, a = 1) {
  alpha(a, () => {
    for (let k = 0; k < 3; k++) {
      P();
      for (let i = 0; i <= 20; i++) { const u = i / 20; const px = x + (k - 1) * 46 + Math.sin(u * 8 - t * 6 + k) * 12; const py = y - u * 130; i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); }
      ctx.lineWidth = 9; ctx.strokeStyle = '#6ab04c'; ctx.lineCap = 'round'; ctx.stroke();
    }
  });
}
function stinkFlow(x0, y0, x1, y1, t, a = 1) {
  alpha(a, () => {
    for (let k = 0; k < 3; k++) {
      P();
      for (let i = 0; i <= 36; i++) {
        const u = i / 36;
        const x = lerp(x0, x1, u), y = lerp(y0, y1, u) - Math.sin(u * Math.PI) * 120 + Math.sin(u * 14 - t * 10 + k * 2) * 14 + (k - 1) * 26;
        i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
      }
      ctx.save(); ctx.setLineDash([26, 22]); ctx.lineDashOffset = -t * 160;
      ctx.lineWidth = 10; ctx.strokeStyle = '#6ab04c'; ctx.lineCap = 'round'; ctx.stroke(); ctx.restore();
    }
  });
}
function sparkle(x, y, r, t, ph = 0) {
  const s = 0.55 + 0.45 * Math.sin(t * 8 + ph);
  at(x, y, s, t * 1.5 + ph, () => {
    P(); ctx.moveTo(0, -r); ctx.quadraticCurveTo(0, 0, r, 0); ctx.quadraticCurveTo(0, 0, 0, r); ctx.quadraticCurveTo(0, 0, -r, 0); ctx.quadraticCurveTo(0, 0, 0, -r);
    fs(WHITE, 4, '#f6c90e');
  });
}
function fly(cx, cy, R, t) {
  const a = t * 5, x = cx + Math.cos(a) * R, y = cy + Math.sin(a * 1.3) * R * 0.5;
  ell(x - 8, y - 10, 10, 6, -0.5); fs('rgba(255,255,255,0.8)', 3); ell(x + 8, y - 10, 10, 6, 0.5); fs('rgba(255,255,255,0.8)', 3);
  circ(x, y, 9); fs(INK, 0);
}
function drawBasket() {
  for (const [x, y, rx, ry, c] of [[-60, -212, 66, 28, '#ff6b6b'], [52, -218, 74, 30, '#ffd23f'], [0, -230, 50, 24, '#a29bfe']]) { ell(x, y, rx, ry); fs(c, 6); }
  P(); ctx.moveTo(-155, -205); ctx.lineTo(155, -205); ctx.lineTo(122, 0); ctx.lineTo(-122, 0); ctx.closePath(); fs('#74b9ff', 8);
  for (let r = 0; r < 4; r++) for (let c = -2; c <= 2; c++) { rr(c * 46 - 14 - r * 0, -170 + r * 42, 28, 22, 8); fs('rgba(0,0,0,0.13)', 0); }
  rr(-165, -222, 330, 32, 14); fs('#5aa0ee', 7);
  limb(118, -210, 150, -120, 18, WHITE); ell(160, -108, 22, 14, 0.4); fs(WHITE, 6);
}
function drawWardrobe(k, t) {
  rr(-180, -665, 360, 665, 14); fs(WOOD, 8);
  rr(-196, -712, 392, 56, 12); fs(WOOD_D, 8);
  rr(-158, -630, 316, 590, 8); fs('#3b2a1a', 6);
  if (k > 0.01) {
    seg(-148, -560, 148, -560, 8, '#9aa4b2');
    for (const hx of [-90, 0, 90]) {
      const sw = Math.sin(t * 2 + hx) * 0.06;
      at(hx, -560, 1, sw, () => { P(); ctx.arc(0, 10, 10, Math.PI, Math.PI * 2.2); fs(null, 5, '#cfd6e2'); P(); ctx.moveTo(0, 20); ctx.lineTo(-48, 58); ctx.lineTo(48, 58); ctx.closePath(); fs(null, 5, '#cfd6e2'); });
    }
    ctx.save(); ctx.globalAlpha *= 0.75;
    for (let i = 0; i < 6; i++) { const a = (i / 5) * Math.PI / 2; seg(-158, -630, -158 + Math.cos(a) * 130, -630 + Math.sin(a) * 130, 3, '#e9edf2'); }
    for (const r of [40, 75, 110]) { P(); ctx.arc(-158, -630, r, 0, Math.PI / 2); ctx.lineWidth = 3; ctx.strokeStyle = '#e9edf2'; ctx.stroke(); }
    ctx.restore();
  }
  const dw = 158 * (1 - k);
  if (dw > 1) {
    rr(-158, -630, dw, 590, 6); fs(WOOD, 7); rr(158 - dw, -630, dw, 590, 6); fs(WOOD, 7);
    if (k < 0.2) { circ(-22, -330, 10); fs(YELLOW, 5); circ(22, -330, 10); fs(YELLOW, 5); }
  }
  if (k > 0.01) {
    const ow = 150 * Math.sin(k * Math.PI / 2);
    for (const sd of [-1, 1]) {
      P(); ctx.moveTo(sd * 158, -630); ctx.lineTo(sd * (158 + ow), -660); ctx.lineTo(sd * (158 + ow), -20); ctx.lineTo(sd * 158, -40); ctx.closePath(); fs('#d9a066', 7);
    }
  }
  rr(-170, -6, 40, 14, 4); fs(WOOD_D, 5); rr(130, -6, 40, 14, 4); fs(WOOD_D, 5);
}
function drawPoster() {
  rr(-130, -165, 260, 330, 8); fs('#fffbe8', 7);
  txt('VERMISST', 0, -122, 42, RED);
  at(0, 88, 0.28, 0, () => drawChair());
  txt('seit 2019', 0, 132, 32, INK, { weight: 800 });
  at(-90, -165, 1, -0.5, () => { ctx.fillStyle = 'rgba(255,230,140,0.85)'; ctx.fillRect(-34, -12, 68, 24); });
  at(90, -165, 1, 0.5, () => { ctx.fillStyle = 'rgba(255,230,140,0.85)'; ctx.fillRect(-34, -12, 68, 24); });
}
function drawSock(t, o = {}) {
  const path = () => { P(); ctx.moveTo(-40, -120); ctx.lineTo(40, -120); ctx.lineTo(40, 40); ctx.quadraticCurveTo(40, 90, 100, 90); ctx.lineTo(120, 90); ctx.quadraticCurveTo(152, 90, 152, 120); ctx.quadraticCurveTo(152, 150, 112, 150); ctx.lineTo(-8, 150); ctx.quadraticCurveTo(-40, 150, -40, 110); ctx.closePath(); };
  path(); fs(o.col || '#f1f2f6', 0);
  ctx.save(); path(); ctx.clip();
  ctx.fillStyle = RED; ctx.fillRect(-60, -120, 240, 22); ctx.fillStyle = BLUE; ctx.fillRect(-60, -86, 240, 12);
  ell(130, 120, 32, 34); ctx.fillStyle = '#c8cdd6'; ctx.fill(); ell(-30, 140, 36, 30); ctx.fill();
  ctx.restore();
  path(); fs(null, 7);
  for (const sd of [-1, 1]) { circ(sd * 15, -42, 10); fs(WHITE, 4); circ(sd * 15 + 2, -40, 4); ctx.fillStyle = INK; ctx.fill(); }
  if (o.old) {
    P(); ctx.moveTo(-32, -22); ctx.quadraticCurveTo(-26, 70, 0, 96); ctx.quadraticCurveTo(26, 70, 32, -22); ctx.quadraticCurveTo(0, -6, -32, -22); fs('#ffffff', 5);
    seg(-28, -62, -4, -56, 8, '#dfe4ea'); seg(28, -62, 4, -56, 8, '#dfe4ea');
    P(); ctx.arc(78, -30, 20, Math.PI, Math.PI * 2); ctx.lineWidth = 9; ctx.strokeStyle = WOOD_D; ctx.stroke();
    limb(98, -30, 104, 160, 7, WOOD_D);
  } else { P(); ctx.arc(0, -22, 16, Math.PI * 0.15, Math.PI * 0.85); fs(null, 6); }
}
function drawCable() {
  P(); for (let i = 0; i <= 60; i++) { const a = i * 0.42, r = 20 + i * 0.7; const x = Math.cos(a) * r, y = Math.sin(a) * r * 0.6; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
  ctx.lineWidth = 16; ctx.strokeStyle = INK; ctx.lineJoin = 'round'; ctx.stroke(); ctx.lineWidth = 9; ctx.strokeStyle = WHITE; ctx.stroke();
  rr(56, -14, 50, 28, 8); fs('#dfe6e9', 6); rr(104, -7, 18, 14, 3); fs('#9aa4b2', 4);
}
function drawEarbuds() {
  for (const sd of [-1, 1]) { limb(sd * 28, 6, sd * 34, 70, 10, WHITE); circ(sd * 28, 0, 26); fs(WHITE, 6); circ(sd * 28 - sd * 6, -2, 9); fs('#b2bec3', 0); }
}
function drawHairTie() { P(); ctx.arc(0, 0, 36, 0, Math.PI * 2); ctx.lineWidth = 24; ctx.strokeStyle = INK; ctx.stroke(); ctx.lineWidth = 14; ctx.strokeStyle = '#fd79a8'; ctx.stroke(); }
function drawKey() { circ(-36, 0, 26); fs(YELLOW, 6); circ(-36, 0, 9); fs('#2b1260', 4); rr(-12, -9, 78, 18, 4); fs(YELLOW, 6); rr(40, 6, 12, 16, 2); fs(YELLOW, 5); rr(56, 6, 10, 12, 2); fs(YELLOW, 5); }
function drawRemote() { rr(-26, -64, 52, 128, 14); fs('#2d3436', 6); circ(0, -38, 9); fs(RED, 0); for (let i = 0; i < 3; i++) for (const sd of [-1, 1]) { circ(sd * 11, -6 + i * 22, 6); fs('#b2bec3', 0); } }
function drawMiniSock() { at(0, 0, 0.42, 0.4, () => drawSock(0, {})); }
function spiral(cx, cy, rot, a) {
  if (a <= 0.001) return;
  ctx.save(); ctx.translate(cx, cy); ctx.globalAlpha *= a;
  const g = ctx.createRadialGradient(0, 0, 10, 0, 0, 560);
  g.addColorStop(0, 'rgba(255,159,28,0.55)'); g.addColorStop(0.35, 'rgba(162,155,254,0.25)'); g.addColorStop(1, 'rgba(162,155,254,0)');
  ctx.fillStyle = g; ctx.fillRect(-600, -600, 1200, 1200);
  ctx.rotate(rot);
  for (let k = 0; k < 4; k++) {
    P();
    for (let i = 0; i <= 80; i++) { const r = 20 + i * 8; const th = k * Math.PI / 2 + i * 0.1; const x = Math.cos(th) * r, y = Math.sin(th) * r * 0.82; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
    ctx.lineWidth = 30; ctx.strokeStyle = k % 2 ? 'rgba(255,159,28,0.4)' : 'rgba(162,155,254,0.45)'; ctx.lineCap = 'round'; ctx.stroke();
  }
  ctx.restore();
}
function tumbleweed(x, y, r, rot) {
  at(x, y, 1, rot, () => {
    for (let i = 0; i < 12; i++) { P(); ctx.arc((rnd(i) - 0.5) * 24, (rnd(i + 5) - 0.5) * 24, r * (0.45 + rnd(i + 9) * 0.55), rnd(i + 3) * 6, rnd(i + 3) * 6 + 3.6); ctx.lineWidth = 6; ctx.strokeStyle = '#a0794f'; ctx.stroke(); }
  });
}
function dustCloud(x, y, t, s) {
  at(x, y, s, 0, () => {
    for (let i = 0; i < 9; i++) { circ(Math.cos(i * 0.7) * 110 + Math.sin(t * 22 + i) * 10, Math.sin(i * 1.7) * 70 + Math.cos(t * 19 + i) * 9, 70 + rnd(i) * 30); fs('#f1f2f6', 7); }
    for (let i = 0; i < 4; i++) { const a = t * 9 + i * 1.6; limb(Math.cos(a) * 150, Math.sin(a) * 100, Math.cos(a) * 200, Math.sin(a) * 140, 14, WOOD); }
    for (let i = 0; i < 3; i++) sparkle(Math.cos(t * 6 + i * 2) * 130, Math.sin(t * 6 + i * 2) * 90 - 40, 26, t, i);
  });
}
function gurkeEnterExit(t, tIn, tEnd) {
  const gOut = eIn(prog(t, tEnd + 0.05, 0.45));
  if (gOut < 1) drawGurke(540, 1270 + gOut * 1000, pop(t, tIn - 0.1, 0.45), { t, mood: 'angry', mouth: gMouth(t), hat: 'mirror', armL: 0.4, armR: 2.55 + 0.25 * Math.sin(t * 12), point: true });
}

/* ---------- Szenen ---------- */
function sceneHook(t) {
  bg('#121233', '#2a2150');
  dots(t, '#8c7ae6', 0.25, 3);
  const gIn = C('gIn');
  alpha(1 - fade(t, gIn - 0.3, 0.3), () => at(170, 640, pop(t, 0.1, 0.5), 0, () => {
    rr(-110, -150, 220, 300, 10); fs('#1e2a5a', 8);
    circ(30, -50, 46); fs('#fff3b0', 0); circ(54, -64, 40); fs('#1e2a5a', 0);
    seg(0, -150, 0, 150, 8); seg(-110, 0, 110, 0, 8);
  }));
  ctx.fillStyle = '#3b2f5c'; ctx.fillRect(-80, 1250, W + 160, 800);
  const mv = eIO(prog(t, gIn - 0.25, 0.6));
  const cx = lerp(540, 720, mv), cs = lerp(0.95, 0.7, mv);
  const sp = fade(t, 0.15, 0.5);
  alpha(sp, () => {
    const g = ctx.createLinearGradient(0, 0, 0, 1270);
    g.addColorStop(0, 'rgba(255,240,180,0.0)'); g.addColorStop(1, 'rgba(255,240,180,0.42)');
    P(); ctx.moveTo(cx - 70, -60); ctx.lineTo(cx + 70, -60); ctx.lineTo(cx + 340, 1270); ctx.lineTo(cx - 340, 1270); ctx.closePath(); ctx.fillStyle = g; ctx.fill();
    ell(cx, 1262, 320, 40); ctx.fillStyle = 'rgba(255,240,180,0.35)'; ctx.fill();
  });
  at(cx, 1250, cs * pop(t, 0.15, 0.6), 0, () => { drawChair(); drawPile(10, t, { seed: 1, breathe: true }); });
  alpha(1 - fade(t, gIn - 0.3, 0.25), () => at(cx + 250 * cs, 1250 - 560 * cs, pop(t, C('zero') - 0.05), 0.08, () => pill('Sitzungen: 0', 0, 0, 40, RED, WHITE)));
  at(540, 400, pop(t, C('title') - 0.05, 0.35), 0, () => {
    txt('DER', 0, -80, 60, WHITE, { stroke: 12 });
    txt('KLAMOTTENSTUHL', 0, 10, 112, YELLOW, { stroke: 18, maxW: 980 });
  });
  const gs = pop(t, gIn - 0.05, 0.45);
  const waving = t < T('h4');
  drawGurke(265, 1250, 0.8 * gs, { t, mood: 'happy', mouth: gMouth(t), hat: 'mirror', clip: true, armL: 0.55, armR: waving ? 2.1 + 0.35 * Math.sin(t * 7) : 0.35 });
  at(265, 1300, pop(t, C('name') - 0.05), 0, () => pill('Dr. Gurke · Gurkologe', 0, 0, 34, GREEN, WHITE));
  at(830, 645 + Math.sin(t * 2) * 6, 0.8 * pop(t, C('vermisst') - 0.05, 0.45), 0.07, () => drawPoster());
}
function sceneQuantum(t) {
  bg('#e6dcff', '#c3afff');
  stripes('#ffffff', 0.1, t * 30);
  const wsh = C('waesche'), sch = C('schrank'), sq = C('schroedinger'), sn = C('sniff'), gn = C('gehtnoch');
  const out1 = fade(t, sq - 0.25, 0.35);
  alpha(1 - out1, () => {
    at(210, 1010, pop(t, wsh - 0.3, 0.4), 0, () => { drawBasket(); txt('WÄSCHE', 0, 52, 44, INK); });
    at(870, 1010, pop(t, sch - 0.3, 0.4), 0, () => { at(0, 0, 0.42, 0, () => drawWardrobe(0, t)); txt('SCHRANK', 0, 52, 44, INK); });
    at(210, 700, pop(t, wsh + 0.3, 0.3), -0.08, () => pill('zu sauber!', 0, 0, 40, BLUE, WHITE));
    at(870, 640, pop(t, sch + 0.3, 0.3), 0.08, () => pill('zu dreckig!', 0, 0, 40, WOOD_D, WHITE));
  });
  // Titel
  at(540, 370, pop(t, sq - 0.05, 0.4), 0, () => {
    txt('SCHRÖDINGERS', 0, -50, 92, WHITE, { stroke: 16 });
    txt('PULLOVER', 0, 46, 104, YELLOW, { stroke: 18 });
  });
  // Pullover
  let px = 540, py = 760;
  const u1 = prog(t, wsh - 0.1, 0.8); if (u1 > 0 && u1 < 1) { const k = Math.sin(u1 * Math.PI); px = lerp(540, 250, k); py = lerp(760, 860, k); }
  const u2 = prog(t, sch - 0.1, 0.8); if (u2 > 0 && u2 < 1) { const k = Math.sin(u2 * Math.PI); px = lerp(540, 830, k); py = lerp(760, 830, k); }
  const big = eOut(prog(t, sq - 0.15, 0.5));
  const ps = lerp(0.8, 1.3, big) * pop(t, C('pull') - 0.1, 0.4);
  py = lerp(py, 790, big);
  const resolved = t >= gn, quantum = t >= C('both') - 0.3 && !resolved;
  const st = Math.floor(t * 9) % 2;
  if (quantum) {
    for (const [dx, col] of [[-22, 'rgba(116,185,255,0.35)'], [22, 'rgba(160,110,60,0.35)']]) alpha(0.6, () => at(px + dx + Math.sin(t * 30) * 4, py, ps, 0, () => drawPullover(col)));
  }
  at(px, py + Math.sin(t * 3) * 8, ps, Math.sin(t * 2.5) * 0.05, () => {
    drawPullover('#ff7675');
    if ((quantum && st) || (t >= sn - 0.1 && !resolved)) stains();
    if (resolved) { ell(30, 50, 16, 12); ctx.fillStyle = 'rgba(110,80,50,0.55)'; ctx.fill(); }
  });
  if (quantum && !st) for (let i = 0; i < 4; i++) sparkle(px + Math.cos(i * 1.7) * 170 * ps, py + Math.sin(i * 2.3) * 100 * ps, 26, t, i);
  if (quantum && st) stinkUp(px, py - 110 * ps, t, 0.9);
  if (resolved) { for (let i = 0; i < 2; i++) sparkle(px - 140 + i * 280, py - 120, 22, t, i); fly(px + 40, py - 60, 150, t); }
  // Etiketten
  if (t >= C('both') - 0.05 && !resolved) {
    at(230, 1080, pop(t, C('both') - 0.05, 0.3), -0.05, () => pill('SAUBER', 0, 0, 44, GREEN, WHITE));
    at(430, 1080, pop(t, C('both') + 0.15, 0.3), 0, () => pill('UND', 0, 0, 44, PURPLE, WHITE));
    at(640, 1080, pop(t, C('both') + 0.35, 0.3), 0.05, () => pill('DRECKIG', 0, 0, 44, WOOD_D, WHITE));
  }
  // Dr. Gurke
  const gx = lerp(1250, 880, eOut(prog(t, sq - 0.25, 0.5)));
  const sniffing = t >= sn - 0.1 && t < gn;
  const mood = t >= gn ? 'disgust' : (sniffing ? 'squeeze' : 'happy');
  drawGurke(gx, 1290, 0.7, { t, mood, mouth: gMouth(t), hat: 'mirror', rot: sniffing ? -0.12 : 0, armL: sniffing ? 1.2 : 0.5, armR: t >= gn ? 1.9 + 0.1 * Math.sin(t * 8) : 0.4 });
  if (t >= sn - 0.1 && t < gn + 0.5) {
    stinkFlow(px + 150 * ps, py - 20, gx - 30, 1290 - 432 * 0.7, t, 1 - fade(t, gn + 0.2, 0.3));
    at(400, 990, pop(t, sn, 0.3), -0.1, () => txt('*schnüffel*', 0, 0, 46, INK, { weight: 800 }));
  }
  stamp('SAUBER*', 540, 600, t, gn, -0.1, { size: 100, col: '#27ae60' });
  if (t >= gn + 0.3) at(760, 705, pop(t, gn + 0.35, 0.3), -0.1, () => txt('*irgendwie', 0, 0, 40, INK, { weight: 800 }));
}
function sceneLayers(t) {
  bg('#ffe6c2', '#f5c58f');
  dots(t, '#ffffff', 0.25, 13);
  const tIn = T('l1'), l1e = E('l1');
  titleBlock(t, tIn - 0.05, l1e + 0.05, 'PROBLEM #1', 'DER STUHL WÄCHST!', RED, 112);
  gurkeEnterExit(t, tIn, l1e);
  const ap = pop(t, T('l2') - 0.2, 0.5);
  const cx = 400, fy = 1240, cs = 0.85;
  const murky = ['#4b3b47', '#3d4f3a', '#5a4636', '#463a5c'], orange = ['#ff9f1c', '#e17055', '#fdcb6e'], blue = ['#3a5bd9', '#2d4fbf', '#4a6ee0'];
  if (ap > 0.001) at(cx, fy, cs * ap, 0, () => {
    drawChair();
    drawPile(10, t, { seed: 5, fixedH: 46, step: 36, breathe: true, cols: i => (i < 4 ? murky[i] : i < 7 ? orange[i - 4] : blue[i - 7]) });
    if (t >= C('layer3')) {
      const op = eOut(prog(t, C('layer3') + 0.2, 0.3)) * (blinkAt(t, 0.7) ? 0.1 : 1);
      ctx.save(); ctx.shadowColor = YELLOW; ctx.shadowBlur = 24;
      for (const sd of [-1, 1]) { ell(sd * 34 - 30, -350, 13, 13 * op); ctx.fillStyle = YELLOW; ctx.fill(); }
      ctx.restore();
    }
  });
  alpha(fade(t, C('strata'), 0.4), () => {
    const top = fy - 660 * cs;
    seg(130, fy, 130, top, 8);
    for (let y = fy; y > top; y -= 40) seg(130, y, 152, y, 4);
    pill('1,40 m', 130, top - 42, 32, INK, WHITE);
  });
  const bands = [[C('layer1'), -596, 'GESTERN', 'Jeans', '#3a5bd9'], [C('layer2'), -488, 'LETZTER SOMMER', 'Sommerjacke', ORANGE], [C('layer3'), -366, 'URZEIT', '???', '#4b3b47']];
  for (const [c, ly, big, small, col] of bands) {
    if (t < c - 0.05) continue;
    const yy = fy + ly * cs, p = pop(t, c - 0.05, 0.4);
    alpha(clamp(p), () => { seg(cx + 185 * cs, yy, 640, yy, 6); circ(cx + 185 * cs, yy, 10); fs(INK, 0); });
    at(790, yy, p, 0, () => { pill(big, 0, -20, 34, col, WHITE); txt(small, 0, 34, 30, INK, { weight: 800 }); });
  }
  if (t >= C('sock') - 0.05) {
    const sp = pop(t, C('sock'), 0.5);
    at(620, 1135 - 30 * Math.abs(Math.sin(t * 4)), sp * 0.78, Math.sin(t * 3) * 0.1, () => drawSock(t, { old: t >= C('older') }));
  }
  if (t >= C('older')) at(640, 1015, pop(t, C('older') + 0.1), -0.06, () => pill('Baujahr: ca. 1994', 0, 0, 30, '#8d6e63', WHITE));
  const camA = pop(t, T('l5') - 0.15, 0.4) * (1 - fade(t, E('l5') + 0.5, 0.3));
  drawGurkeCam(860, 560, 110, camA, { t, mood: 'whisper', mouth: gMouth(t), handR: [62, -350], bg: '#ffd6a5' });
}
function sceneGravity(t) {
  bg('#0d0a26', '#2b1260');
  dots(t, '#ffffff', 0.35, 31);
  const g2 = T('g2'), sw = C('swirl'), van = C('vanish');
  const cx = 540, cy = 915;
  const rot = t * 0.7 + Math.max(0, t - sw) * 1.8;
  spiral(cx, cy, rot, fade(t, g2 - 0.1, 0.6) * (0.35 + 0.65 * fade(t, sw, 0.6)));
  titleBlock(t, T('g1') - 0.05, E('g1') + 0.05, 'PROBLEM #2', 'ER ZIEHT ALLES AN!', RED, 110);
  gurkeEnterExit(t, T('g1'), E('g1'));
  const wob = t >= sw ? Math.sin(t * 20) * 0.015 : 0;
  at(cx, 1240, 0.7 * pop(t, g2 - 0.1, 0.5), wob, () => { drawChair(); drawPile(10, t, { seed: 2, breathe: true }); });
  alpha(1 - fade(t, van - 0.1, 0.3), () => {
    at(540, 480, pop(t, C('kilo') - 0.05), 0, () => pill('ab 2 kg Wäsche', 0, 0, 46, WHITE, INK));
    at(540, 560, pop(t, sw - 0.05), 0, () => pill('EIGENE SCHWERKRAFT', 0, 0, 46, ORANGE, WHITE));
  });
  const items = [[C('item1'), drawCable, 'Ladekabel', 0.2], [C('item2'), drawEarbuds, 'Kopfhörer', 2.3], [C('item3'), drawHairTie, 'Haargummis', 4.2],
    [van - 0.7, drawKey, '', 1.2], [van - 0.55, drawRemote, '', 3.3], [van - 0.4, drawMiniSock, '', 5.3]];
  items.forEach(([t0, fn, lab, a0], i) => {
    if (t < t0 - 0.05) return;
    const ang = a0 + (t - t0) * 0.9 + Math.max(0, t - van) * 4;
    const suck = eIn(prog(t, van - 0.1 + i * 0.06, 1.0));
    const r = (340 - (t - t0) * 12) * (1 - suck);
    if (r < 6) return;
    const x = cx + Math.cos(ang) * r, y = cy + Math.sin(ang) * r * 0.8;
    const s = pop(t, t0, 0.4) * (0.3 + 0.7 * (1 - suck));
    at(x, y, s * 1.15, ang * 0.5 + suck * 8, fn);
    if (lab) alpha(1 - suck, () => txt(lab, x, y + 78 * s, 34, WHITE, { stroke: 9 }));
  });
  at(540, 600, pop(t, C('forever') - 0.05, 0.35), -0.06, () => txt('FÜR IMMER.', 0, 0, 130, RED, { stroke: 20, sc: WHITE }));
}
function sceneSolution(t) {
  bg('#d8f8ec', '#a6e6cf');
  dots(t, '#ffffff', 0.3, 41);
  const floorY = 1240;
  ctx.fillStyle = '#7fcdb0'; ctx.fillRect(-80, floorY, W + 160, 700);
  const c2 = C('chair2'), wk = C('weeks'), f2 = C('full2'), c3 = C('chair3'), c4 = C('chair4'), mg = C('merge'), wd = C('wardrobe');
  const spread = eIO(prog(t, c2 - 0.1, 0.5));
  const mergeP = eIn(prog(t, mg, 0.6));
  const chairs = [
    { x: lerp(450, 170, spread), s: lerp(0.62, 0.5, spread), t0: T('x1') - 0.3, n: () => 10 },
    { x: 390, s: 0.5, t0: c2, n: () => Math.round(10 * eIO(prog(t, wk, f2 - wk + 0.1))) },
    { x: 610, s: 0.5, t0: c3, n: () => Math.round(10 * eOut(prog(t, c3 + 0.25, 0.8))) },
    { x: 830, s: 0.5, t0: c4, n: () => Math.round(10 * eOut(prog(t, c4 + 0.25, 0.8))) },
  ];
  if (t < mg + 0.6) chairs.forEach((c, i) => {
    if (t < c.t0 - 0.06) return;
    const drop = i === 0 ? pop(t, c.t0, 0.5) : 1;
    const dy = i === 0 ? 0 : -(1 - eIn(prog(t, c.t0 - 0.06, 0.3))) * 1000;
    const x = lerp(c.x, 450, mergeP), sc = c.s * drop * (1 - mergeP * 0.85);
    at(x, floorY + dy, sc, mergeP * 5 * (i % 2 ? 1 : -1), () => { drawChair(); drawPile(c.n(), t, { seed: 3 + i * 7 }); });
    if (mergeP < 0.05 && i > 0) at(x, floorY - 740 * c.s + dy, pop(t, c.t0 + 0.2, 0.3), 0, () => { circ(0, 0, 36); fs(YELLOW, 6); txt('#' + (i + 1), 0, 2, 34, INK); });
  });
  if (t >= mg + 0.3 && t < wd + 0.1) dustCloud(450, floorY - 260, t, pop(t, mg + 0.3, 0.3));
  if (t >= wd - 0.05) at(450, floorY, pop(t, wd - 0.05, 0.5) * 0.95, 0, () => drawWardrobe(eOut(prog(t, C('open'), 0.5)), t));
  confetti(t, wd, 450, 700);
  alpha(1 - fade(t, c2 - 0.2, 0.3), () => {
    if (t < C('stampNo')) at(540, 430, pop(t, C('aufr') - 0.1, 0.4), Math.sin(t * 5) * 0.04, () => txt('AUFRÄUMEN?', 0, 0, 110, WHITE, { stroke: 18 }));
  });
  stamp('ABGELEHNT!', 540, 440, t, C('stampNo'), -0.1, { size: 106, fadeAt: c2 - 0.2 });
  alpha(1 - fade(t, wk - 0.1, 0.3), () => at(540, 440, pop(t, c2 - 0.05, 0.4), 0, () => pill('LÖSUNG: STUHL NR. 2', 0, 0, 52, GREEN, WHITE)));
  const dc = fade(t, wk, 0.2) * (1 - fade(t, wk + 1.4, 0.25));
  if (dc > 0) alpha(dc, () => { ctx.fillStyle = 'rgba(0,0,0,0.82)'; ctx.fillRect(-80, 470, W + 160, 140); txt('3 WOCHEN SPÄTER …', 540, 542, 66, WHITE, { weight: 800 }); });
  at(540, 400, pop(t, wd - 0.05, 0.4), 0, () => txt('KLEIDERSCHRANK', 0, 0, 108, YELLOW, { stroke: 18, maxW: 980 }));
  at(540, 505, pop(t, wd + 0.25, 0.4), 0, () => pill('Erfinder: DU', 0, 0, 44, PURPLE, WHITE));
  const em = C('empty');
  if (t >= em) { const u = prog(t, em, 2.6); tumbleweed(lerp(1200, -200, u), floorY - 50 - Math.abs(Math.sin(u * 14)) * 50, 46, -u * 20); }
  const camA = pop(t, T('x2') - 0.15, 0.4) * (1 - fade(t, E('x7') + 0.9, 0.3));
  const gl = gLineAt(t);
  drawGurkeCam(855, 730, 115, camA, { t, mood: gl && gl.id === 'x2' ? 'angry' : 'happy', mouth: gMouth(t), live: true });
}
function sceneOutro(t) {
  bg('#17153a', '#35286b');
  dots(t, '#8c7ae6', 0.25, 51);
  ctx.fillStyle = '#2a2150'; ctx.fillRect(-80, 1250, W + 160, 700);
  const cta = C('cta'), creep = C('creep'), eyes = C('eyes');
  const dark = fade(t, creep, 1.2);
  const ps = 0.72 * pop(t, cta - 0.3, 0.5);
  at(770, 1250, ps, 0, () => { drawChair({ col: '#3d3470', dark: '#2c2557' }); drawPile(10, t, { seed: 9, breathe: true, cols: i => ['#463d7d', '#3d3470', '#524a8c'][i % 3] }); });
  alpha(1 - 0.6 * dark, () => {
    at(540, 330, pop(t, cta - 0.05, 0.4), 0, () => txt('Schick das der Person mit dem', 0, 0, 56, WHITE, { stroke: 12, maxW: 960 }));
    at(540, 435, pop(t, cta + 0.15, 0.4), Math.sin(t * 4) * 0.02, () => txt('KLAMOTTENSTUHL', 0, 0, 112, YELLOW, { stroke: 20, maxW: 980 }));
    at(540, 545, pop(t, C('know') - 0.05, 0.4), 0, () => txt('Du weißt genau, wer gemeint ist.', 0, 0, 46, WHITE, { stroke: 11, weight: 800 }));
    if (t >= cta + 0.4) {
      const p = eOut(prog(t, cta + 0.4, 0.7));
      ctx.save();
      P(); ctx.moveTo(900, 620); ctx.bezierCurveTo(1070, 780, 1070, 1100, 1000, 1360);
      ctx.setLineDash([2400, 2400]); ctx.lineDashOffset = 4000 * (1 - p);
      ctx.lineWidth = 26; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.stroke();
      ctx.lineWidth = 14; ctx.strokeStyle = RED; ctx.stroke();
      ctx.restore();
      if (p > 0.95) arrowHead(1000, 1372 + Math.sin(t * 8) * 8, Math.PI / 2 + 0.25, 34, RED);
    }
  });
  const wh = t >= T('o3') - 0.1;
  drawGurke(270, 1250, 0.78 * pop(t, cta - 0.2, 0.45), {
    t, mood: wh ? 'whisper' : 'happy', mouth: gMouth(t), hat: 'mirror', clip: !wh, armL: 0.5,
    armR: wh ? 0 : 2.2 + 0.2 * Math.sin(t * 6), handR: wh ? [62, -350] : undefined, lookX: wh ? 0.9 : 0,
  });
  if (dark > 0) {
    const g = ctx.createRadialGradient(540, 960, 200, 540, 960, 1100);
    g.addColorStop(0, `rgba(0,0,0,${0.35 * dark})`); g.addColorStop(1, `rgba(0,0,0,${0.85 * dark})`);
    ctx.fillStyle = g; ctx.fillRect(-80, -80, W + 160, H + 160);
  }
  if (t >= eyes) {
    const op = eOut(prog(t, eyes, 0.25)) * (blinkAt(t, 1.4) ? 0.1 : 1);
    ctx.save(); ctx.shadowColor = YELLOW; ctx.shadowBlur = 40;
    for (const sd of [-1, 1]) { ell(770 + sd * 34, 1250 - 480 * 0.72, 16, 16 * op); ctx.fillStyle = YELLOW; ctx.fill(); }
    ctx.restore();
  }
  const endT = E('o3') + 0.6;
  at(540, 1470, pop(t, endT, 0.45), 0, () => {
    txt('Folge 3?', 0, -40, 72, WHITE, { stroke: 14 });
    txt('Schreib’s in die Kommentare', 0, 40, 46, WHITE, { stroke: 11 });
  });
}

window.EP_SCENES = { hook: sceneHook, quantum: sceneQuantum, layers: sceneLayers, gravity: sceneGravity, solution: sceneSolution, outro: sceneOutro };
window.EP_STAMPS = ['title', 'gehtnoch', 'stampNo', 'forever', 'eyes'];
