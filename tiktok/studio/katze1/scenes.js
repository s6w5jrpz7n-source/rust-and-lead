'use strict';
/* TREND „der drang, …“: Katze schubst das Glas vom Tisch. ~9,6 s, als Schleife gebaut. */
const EV = TL.data.ev;
const FUR = '#f4a259', FUR_D = '#d9772b', FUR_L = '#ffd8a8', NOSE = '#ff8fab';
const TX = 330, TY = 1150, EDGE = 795, FLOOR = 1520, G0 = 620;

function k(t, a, b) { return eIO(prog(t, a, b - a)); }
function glassX(t) {
  let x = G0;
  x += 40 * k(t, EV.n1, EV.n1 + 0.35);
  x += 60 * k(t, EV.n2, EV.n2 + 0.4);
  x += (EDGE - 25 - G0 - 100) * k(t, EV.n3, EV.fall);
  return x;
}
function pawPos(t) {
  const rest = [70, -12];
  const gx = glassX(t) - TX - 108;
  const reach = k(t, EV.paw, EV.n1) * (1 - k(t, EV.back, EV.blink));
  const target = t < EV.fall ? [gx, -70] : [EDGE - TX - 140, -60];
  return [lerp(rest[0], target[0], reach), lerp(rest[1], target[1], reach)];
}
function gaze(t) {
  if (t < EV.look) return [0, 0];
  if (t < EV.paw) return [lerp(0, 1, k(t, EV.look, EV.look + 0.3)), lerp(0, 0.6, k(t, EV.look, EV.look + 0.3))];
  if (t < EV.fall) return [lerp(1, 0, k(t, EV.paw, EV.paw + 0.3)), lerp(0.6, 0, k(t, EV.paw, EV.paw + 0.3))];
  if (t < EV.back) return [lerp(0, 0.9, k(t, EV.fall, EV.fall + 0.25)), lerp(0, 1, k(t, EV.fall, EV.crash))];
  return [lerp(0.9, 0, k(t, EV.back, EV.back + 0.3)), lerp(1, 0, k(t, EV.back, EV.back + 0.3))];
}
function pupilW(t) { if (t < EV.paw) return 10; if (t < EV.back) return lerp(10, 30, k(t, EV.paw, EV.paw + 0.5)); return lerp(30, 10, k(t, EV.back, EV.back + 0.5)); }
function lid(t) {
  if (t >= EV.blink && t < EV.blink + 0.9) { const u = prog(t, EV.blink, 0.9); return u < 0.4 ? eIO(u / 0.4) : lerp(1, 0.45, eIO((u - 0.4) / 0.6)); }
  if (t >= EV.blink + 0.9) return 0.45;
  return 0;
}

/* ---------- Raum ---------- */
function kitchen(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#f6e7d0'); g.addColorStop(1, '#e8cfa9'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.save(); ctx.globalAlpha = 0.5;
  rr(620, 420, 360, 470, 20); ctx.fillStyle = '#fff8e6'; ctx.fill();
  const sg = ctx.createRadialGradient(800, 560, 20, 800, 560, 420); sg.addColorStop(0, 'rgba(255,240,200,0.9)'); sg.addColorStop(1, 'rgba(255,240,200,0)'); ctx.fillStyle = sg; ctx.fillRect(400, 200, 680, 800);
  ctx.restore();
  seg(800, 420, 800, 890, 12, 'rgba(200,170,130,0.5)'); seg(620, 655, 980, 655, 12, 'rgba(200,170,130,0.5)');
  ctx.fillStyle = '#d9c3a0'; ctx.fillRect(0, FLOOR - 20, W, H - FLOOR + 20);
  for (let x = -60; x < W; x += 120) seg(x, FLOOR - 20, x + 40, H, 3, '#c4ab85');
  // Tisch
  ctx.fillStyle = '#a0673d'; ctx.fillRect(-40, TY + 30, EDGE + 40, 70);
  const tg = ctx.createLinearGradient(0, TY - 10, 0, TY + 34); tg.addColorStop(0, '#c98c5a'); tg.addColorStop(1, '#a8703f');
  ctx.fillStyle = tg; ctx.fillRect(-40, TY - 6, EDGE + 40, 40);
  seg(-40, TY - 6, EDGE, TY - 6, 3, '#e0ad7c');
  ctx.fillStyle = '#8a5530'; ctx.fillRect(EDGE - 60, TY + 100, 46, FLOOR - TY - 120);
  ell(EDGE - 37, FLOOR - 18, 50, 10); ctx.fillStyle = 'rgba(0,0,0,0.12)'; ctx.fill();
}

/* ---------- Glas ---------- */
function glassShape(w1, w2, h) { P(); ctx.moveTo(-w1 / 2, -h); ctx.lineTo(w1 / 2, -h); ctx.lineTo(w2 / 2, 0); ctx.lineTo(-w2 / 2, 0); ctx.closePath(); }
function drawGlass(x, y, rot, t, water = 1) {
  at(x, y, 1, rot, () => {
    ell(0, 0, 50, 8); ctx.fillStyle = 'rgba(0,0,0,0.12)'; ctx.fill();
    glassShape(112, 92, 175); ctx.fillStyle = 'rgba(225,242,255,0.35)'; ctx.fill();
    if (water > 0) {
      ctx.save(); glassShape(112, 92, 175); ctx.clip();
      const lvl = -175 * 0.62 * water;
      P(); ctx.moveTo(-70, 10); ctx.lineTo(-70, lvl); for (let i = 0; i <= 10; i++) ctx.lineTo(-70 + i * 14, lvl + Math.sin(t * 6 + i) * 3); ctx.lineTo(70, 10); ctx.closePath();
      ctx.fillStyle = 'rgba(90,170,235,0.55)'; ctx.fill(); ctx.restore();
    }
    glassShape(112, 92, 175); ctx.lineWidth = 5; ctx.strokeStyle = 'rgba(255,255,255,0.95)'; ctx.stroke();
    seg(-38, -150, -30, -30, 7, 'rgba(255,255,255,0.7)'); seg(30, -160, 28, -120, 4, 'rgba(255,255,255,0.5)');
  });
}
function glassLayer(t) {
  if (t < EV.fall) { drawGlass(glassX(t), TY - 6, 0, t); return; }
  if (t < EV.crash) {
    const u = prog(t, EV.fall, EV.crash - EV.fall);
    const x = EDGE - 25 + u * 110, y = TY - 6 + u * u * (FLOOR - TY + 30), rot = u * 2.2;
    drawGlass(x, y, rot, t, 1 - u * 0.6);
    for (let i = 0; i < 14; i++) { const v = (u * 3 + rnd(i)) % 1; circ(x - 40 + rnd(i + 3) * 60 - v * 30, y - 120 + v * 140, 6 - v * 4); ctx.fillStyle = 'rgba(90,170,235,0.7)'; ctx.fill(); }
    return;
  }
  const dt = t - EV.crash, cx = EDGE + 90;
  ell(cx, FLOOR + 8, 40 + Math.min(1, dt * 3) * 150, 8 + Math.min(1, dt * 3) * 26); ctx.fillStyle = 'rgba(90,170,235,0.45)'; ctx.fill();
  for (let i = 0; i < 18; i++) {
    const a = -Math.PI * (0.1 + 0.8 * rnd(i)), v = 300 + rnd(i + 5) * 600, tt2 = Math.min(dt, 0.9);
    const x = cx + Math.cos(a) * v * tt2, y = Math.min(FLOOR + 10, FLOOR + Math.sin(a) * v * tt2 + 1600 * tt2 * tt2);
    at(x, y, 1, i + dt * (rnd(i) * 10), () => { P(); ctx.moveTo(0, -14); ctx.lineTo(12, 10); ctx.lineTo(-10, 8); ctx.closePath(); ctx.fillStyle = 'rgba(230,245,255,0.9)'; ctx.fill(); ctx.lineWidth = 2; ctx.strokeStyle = 'rgba(150,190,220,0.9)'; ctx.stroke(); });
  }
  if (t > EV.end - 0.45) { const p = prog(t, EV.end - 0.45, 0.35); alpha(p, () => drawGlass(G0, TY - 6, 0, t)); }
}

/* ---------- Katze ---------- */
function cat(t) {
  const [gx, gy] = gaze(t), pw = pupilW(t), ld = lid(t);
  const flick = Math.exp(-Math.max(0, t - EV.flick) * 4) * Math.sin((t - EV.flick) * 18) * (t > EV.flick ? 1 : 0);
  const breathe = 1 + 0.01 * Math.sin(t * 3);
  const tilt = -0.05 * k(t, EV.flick, EV.flick + 0.4) * (1 - k(t, EV.n3 - 0.2, EV.n3)) + 0.04 * k(t, EV.back, EV.back + 0.5);
  ctx.save(); ctx.translate(TX, TY);
  // Schwanz
  const tf = Math.sin(t * 2.2) * 0.15 + flick * 0.3;
  P(); ctx.moveTo(-150, -40); ctx.bezierCurveTo(-330, -40, -330, -160, -290 - tf * 80, -300);
  ctx.lineWidth = 64; ctx.strokeStyle = '#5c2e0e'; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 52; ctx.strokeStyle = FUR; ctx.stroke();
  for (let i = 0; i < 3; i++) { const u = 0.45 + i * 0.17; const bx = -((1 - u) ** 3 * 150 + 3 * (1 - u) ** 2 * u * 330 + 3 * (1 - u) * u * u * 330 + u ** 3 * (290 + tf * 80)), by = (1 - u) ** 3 * -40 + 3 * (1 - u) ** 2 * u * -40 + 3 * (1 - u) * u * u * -160 + u ** 3 * -300; circ(bx, by, 14); ctx.fillStyle = FUR_D; ctx.fill(); }
  // Körper
  ctx.save(); ctx.scale(1, breathe);
  P(); ctx.moveTo(-130, -400); ctx.bezierCurveTo(-210, -300, -230, -60, -175, 0); ctx.lineTo(175, 0); ctx.bezierCurveTo(230, -60, 210, -300, 130, -400); ctx.closePath();
  const bg2 = ctx.createLinearGradient(0, -420, 0, 0); bg2.addColorStop(0, FUR); bg2.addColorStop(1, '#e8893f'); ctx.fillStyle = bg2; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = '#5c2e0e'; ctx.stroke();
  for (const sd of [-1, 1]) for (let i = 0; i < 3; i++) { P(); ctx.arc(sd * 150, -250 + i * 70, 50, sd > 0 ? Math.PI * 0.6 : Math.PI * 0.1, sd > 0 ? Math.PI * 0.9 : Math.PI * 0.4); ctx.lineWidth = 12; ctx.strokeStyle = FUR_D; ctx.stroke(); }
  P(); ctx.moveTo(-90, -360); for (let i = 0; i <= 8; i++) ctx.lineTo(-90 + i * 22.5, -330 - (i % 2) * 26); ctx.lineTo(80, -120); ctx.quadraticCurveTo(0, -60, -80, -120); ctx.closePath(); ctx.fillStyle = '#fff4e6'; ctx.fill();
  ctx.restore();
  // linke Pfote
  ell(-70, -14, 52, 30); fs('#fff4e6', 5, '#5c2e0e'); for (const dx of [-20, 0, 20]) seg(-70 + dx, -4, -70 + dx, -18, 3, '#d9b38c');
  // rechte Pfote (schubst)
  const [px, py] = pawPos(t);
  limb(110, -320, px, py - 10, 58, FUR);
  ell(px, py, 50, 32); fs('#fff4e6', 5, '#5c2e0e'); for (const dx of [-18, 0, 18]) seg(px + dx, py + 10, px + dx, py - 4, 3, '#d9b38c');
  // Kopf
  ctx.save(); ctx.translate(0, -540); ctx.rotate(tilt); ctx.translate(0, 540);
  for (const sd of [-1, 1]) {
    const er = sd * (0.05 + (sd > 0 ? flick * 0.25 : 0));
    at(sd * 120, -660, 1, er, () => {
      P(); ctx.moveTo(-sd * 70, 30); ctx.lineTo(sd * 10, -130); ctx.lineTo(sd * 70, 40); ctx.closePath(); fs(FUR, 6, '#5c2e0e');
      P(); ctx.moveTo(-sd * 40, 20); ctx.lineTo(sd * 6, -90); ctx.lineTo(sd * 44, 26); ctx.closePath(); ctx.fillStyle = '#ffc9d6'; ctx.fill();
    });
  }
  P(); ctx.ellipse(0, -540, 210, 182, 0, 0, Math.PI * 2);
  const hg = ctx.createRadialGradient(-40, -600, 30, 0, -540, 230); hg.addColorStop(0, FUR_L); hg.addColorStop(0.5, FUR); hg.addColorStop(1, '#e8893f');
  ctx.fillStyle = hg; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = '#5c2e0e'; ctx.stroke();
  for (const sd of [-1, 1]) { P(); ctx.moveTo(sd * 180, -560); for (let i = 0; i < 4; i++) { ctx.lineTo(sd * (232 - (i % 2) * 22), -520 + i * 26); } ctx.lineTo(sd * 150, -420); ctx.closePath(); ctx.fillStyle = FUR; ctx.fill(); }
  for (const dx of [-36, 0, 36]) { P(); ctx.moveTo(dx, -712); ctx.quadraticCurveTo(dx * 1.2, -670, dx * 0.9, -640); ctx.lineWidth = 12; ctx.strokeStyle = FUR_D; ctx.lineCap = 'round'; ctx.stroke(); }
  for (const sd of [-1, 1]) { ell(sd * 120, -470, 34, 18); ctx.fillStyle = 'rgba(255,140,160,0.35)'; ctx.fill(); }
  // Augen
  for (const sd of [-1, 1]) {
    const ex = sd * 80, ey = -560;
    ctx.save(); ell(ex, ey, 56, 50, sd * -0.12); ctx.clip();
    const eg = ctx.createRadialGradient(ex, ey, 6, ex, ey, 60); eg.addColorStop(0, '#e9f78a'); eg.addColorStop(1, '#7fb53a'); ctx.fillStyle = eg; ctx.fillRect(ex - 60, ey - 60, 120, 120);
    ell(ex + gx * 16, ey + gy * 12, pw / 2, 40); ctx.fillStyle = '#1a1a1a'; ctx.fill();
    circ(ex + gx * 16 - 14, ey + gy * 12 - 16, 10); ctx.fillStyle = WHITE; ctx.fill();
    circ(ex + gx * 16 + 12, ey + gy * 12 + 14, 5); ctx.fill();
    if (ld > 0) { ctx.fillStyle = FUR; ctx.fillRect(ex - 60, ey - 60, 120, 110 * ld); seg(ex - 56, ey - 60 + 110 * ld, ex + 56, ey - 60 + 110 * ld, 6, '#5c2e0e'); }
    ctx.restore();
    ell(ex, ey, 56, 50, sd * -0.12); fs(null, 6, '#5c2e0e');
  }
  // Schnauze
  for (const sd of [-1, 1]) { ell(sd * 34, -466, 50, 38); ctx.fillStyle = '#fff4e6'; ctx.fill(); }
  ell(0, -430, 40, 24); ctx.fillStyle = '#fff4e6'; ctx.fill();
  P(); ctx.moveTo(-20, -500); ctx.lineTo(20, -500); ctx.quadraticCurveTo(22, -494, 4, -478); ctx.lineTo(-4, -478); ctx.quadraticCurveTo(-22, -494, -20, -500); ctx.closePath(); fs(NOSE, 4, '#5c2e0e');
  P(); ctx.moveTo(0, -478); ctx.lineTo(0, -466); ctx.arc(-16, -466, 16, 0, Math.PI * 0.85); fs(null, 5, '#5c2e0e'); P(); ctx.arc(16, -466, 16, Math.PI * 0.15, Math.PI); fs(null, 5, '#5c2e0e');
  for (const sd of [-1, 1]) for (let i = 0; i < 3; i++) { P(); ctx.moveTo(sd * 70, -470 + i * 14); ctx.quadraticCurveTo(sd * 170, -490 + i * 22, sd * 260, -500 + i * 34); ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(255,255,255,0.95)'; ctx.stroke(); }
  ctx.restore();
  ctx.restore();
}

/* ---------- Text ---------- */
function caption() {
  const lines = ['der drang, das glas vom', 'tisch zu schubsen 😼'];
  lines.forEach((ln, i) => {
    ctx.save(); ctx.font = `800 62px ${FONT}, "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.lineWidth = 12; ctx.strokeStyle = '#000'; ctx.lineJoin = 'round'; ctx.strokeText(ln, 540, 250 + i * 78);
    ctx.fillStyle = WHITE; ctx.fillText(ln, 540, 250 + i * 78); ctx.restore();
  });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const sh = t >= EV.crash && t < EV.crash + 0.4 ? 14 * Math.exp(-(t - EV.crash) * 10) : 0;
  ctx.save(); ctx.translate(Math.sin(t * 90) * sh, Math.cos(t * 77) * sh);
  kitchen(t);
  cat(t);
  glassLayer(t);
  ctx.restore();
  caption();
};
window.EP_SCENES = {};
