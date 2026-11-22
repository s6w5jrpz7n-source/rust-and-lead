'use strict';
/* Sitcom-Baukasten für animierte Sketche (Figuren aus „Opas Testament“, erweitert). Lädt nach engine.js. */
const SKIN1 = '#f2c7a5', SKIN_OLD = '#efc9b0', SKIN_K = '#e8b894', SKIN_D = '#e03131';
function figur(x, y, s, o) {
  const t = o.t || 0, m = o.mouth || 0, mood = o.mood || 'neutral', skin = o.skin || SKIN1;
  ctx.save(); ctx.translate(x, y); if (o.rot) ctx.rotate(o.rot); ctx.scale(s, s);
  if (o.ghost) { ctx.globalAlpha *= o.ghost; }
  if (o.tail) { P(); ctx.moveTo(60, 0); ctx.bezierCurveTo(220, 40, 200, -160, 260 + Math.sin(t * 3) * 20, -200); ctx.lineWidth = 14; ctx.strokeStyle = INK; ctx.stroke(); ctx.lineWidth = 8; ctx.strokeStyle = '#c92a2a'; ctx.stroke(); P(); ctx.moveTo(240 + Math.sin(t * 3) * 20, -200); ctx.lineTo(290 + Math.sin(t * 3) * 20, -250); ctx.lineTo(284 + Math.sin(t * 3) * 20, -186); ctx.closePath(); fs('#c92a2a', 5); }
  if (o.ghost) { P(); ctx.moveTo(-116, -40); for (let i = 0; i <= 8; i++) ctx.lineTo(-116 + i * 29, 160 + Math.sin(t * 6 + i) * 18 + (i % 2) * 30); ctx.lineTo(116, -40); ctx.closePath(); fs(o.shirt || '#dbe4ff', 7); }
  else if (o.stand) {
    const sw = o.walk ? Math.sin(t * 9) * 26 : 0;
    rr(-92 + sw, -30, 74, 300, 30); fs(o.pants || '#495057', 6); rr(18 - sw, -30, 74, 300, 30); fs(o.pants || '#495057', 6);
    ell(-58 + sw, 272, 54, 22); fs(o.shoes || '#343a40', 6); ell(58 - sw, 272, 54, 22); fs(o.shoes || '#343a40', 6);
    if (o.skirt) { P(); ctx.moveTo(-112, -40); ctx.lineTo(112, -40); ctx.lineTo(140, 150); ctx.lineTo(-140, 150); ctx.closePath(); fs(o.skirt, 6); }
  } else if (!o.noLegs) {
    rr(-104, -18, 96, 84, 34); fs(o.pants || '#495057', 6); rr(8, -18, 96, 84, 34); fs(o.pants || '#495057', 6);
    rr(-92, 40, 70, 210, 26); fs(o.pants || '#495057', 6); rr(22, 40, 70, 210, 26); fs(o.pants || '#495057', 6);
    ell(-58, 252, 50, 22); fs('#343a40', 6); ell(58, 252, 50, 22); fs('#343a40', 6);
  }
  rr(-116, -262, 232, 280, 76); fs(o.shirt || '#868e96', 7);
  if (o.collar) { P(); ctx.moveTo(-40, -250); ctx.lineTo(0, -200); ctx.lineTo(40, -250); ctx.closePath(); fs(o.collar, 5); }
  if (o.tie) { P(); ctx.moveTo(-12, -232); ctx.lineTo(12, -232); ctx.lineTo(18, -120); ctx.lineTo(0, -100); ctx.lineTo(-18, -120); ctx.closePath(); fs(o.tie, 5); }
  if (o.hood) { P(); ctx.ellipse(0, -258, 80, 34, 0, 0, Math.PI); fs(o.hood, 6); seg(-24, -230, -30, -150, 5, '#dee2e6'); seg(24, -230, 30, -150, 5, '#dee2e6'); }
  const hl = o.handL || [-130, -40], hr = o.handR || [130, -40];
  limb(-104, -224, hl[0], hl[1], 30, o.shirt || '#868e96'); limb(104, -224, hr[0], hr[1], 30, o.shirt || '#868e96');
  if (o.holdL) o.holdL(hl[0], hl[1]);
  circ(hl[0], hl[1], 24); fs(skin, 6);
  if (o.finger) {
    ctx.save(); circ(hr[0], hr[1], 24); fs(skin, 6); rr(hr[0] - 8, hr[1] - 74, 16, 56, 8); fs(skin, 5); ctx.restore();
    const f = Math.floor(t * 12);
    for (let i = -3; i <= 2; i++) for (let j = -4; j <= 1; j++) { ctx.fillStyle = ['#e8b89a', '#d9a383', '#f2c7a5', '#c98f6f'][Math.floor(rnd(i * 7 + j * 13 + f) * 4)]; ctx.fillRect(hr[0] + i * 20, hr[1] + j * 20, 20, 20); }
  } else { circ(hr[0], hr[1], 24); fs(skin, 6); }
  if (o.holdR) o.holdR(hr[0], hr[1]);
  rr(-30, -296, 60, 56, 20); fs(skin, 6);
  for (const sd of [-1, 1]) { ell(sd * 92, -356, 17, 26); fs(skin, 6); }
  if (o.earrings) for (const sd of [-1, 1]) { circ(sd * 94, -318, 12); fs('#fcc419', 5); }
  if (o.hair === 'bob') { P(); ctx.ellipse(0, -372, 128, 136, 0, Math.PI * 0.92, Math.PI * 2.08); ctx.lineTo(118, -290); ctx.lineTo(-118, -290); ctx.closePath(); fs(o.hairCol, 7); }
  if (o.hair === 'long') { P(); ctx.moveTo(-120, -380); ctx.quadraticCurveTo(-150, -200, -130, -150); ctx.lineTo(130, -150); ctx.quadraticCurveTo(150, -200, 120, -380); ctx.closePath(); fs(o.hairCol, 7); }
  if (o.hair === 'bun') { circ(0, -480, 50); fs(o.hairCol, 6); }
  ell(0, -360, 92, 106); fs(skin, 7);
  if (mood === 'furious' || mood === 'sick') { ell(0, -360, 89, 103); ctx.fillStyle = mood === 'furious' ? 'rgba(255,40,40,0.35)' : 'rgba(80,200,60,0.4)'; ctx.fill(); }
  // Haare
  if (o.hair === 'bob') { P(); ctx.ellipse(0, -400, 100, 80, 0, Math.PI, Math.PI * 2); ctx.quadraticCurveTo(40, -420, -10, -398); ctx.quadraticCurveTo(-60, -410, -100, -400); ctx.closePath(); fs(o.hairCol, 6); seg(-30, -460, 20, -420, 6, '#fff3bf'); }
  if (o.hair === 'receding') { P(); ctx.arc(0, -380, 96, Math.PI * 1.05, Math.PI * 1.32); ctx.lineTo(-40, -440); ctx.closePath(); fs(o.hairCol, 5); P(); ctx.arc(0, -380, 96, Math.PI * 1.68, Math.PI * 1.95); ctx.lineTo(40, -440); ctx.closePath(); fs(o.hairCol, 5); }
  if (o.hair === 'long') { P(); ctx.ellipse(0, -410, 104, 70, 0, Math.PI, Math.PI * 2); ctx.quadraticCurveTo(30, -400, -20, -380); ctx.quadraticCurveTo(-70, -392, -104, -410); ctx.closePath(); fs(o.hairCol, 6); }
  if (o.hair === 'bun') { P(); ctx.ellipse(0, -404, 98, 70, 0, Math.PI, Math.PI * 2); ctx.closePath(); fs(o.hairCol, 6); for (const sd of [-1, 1]) seg(sd * 20, -460, sd * 60, -420, 3, '#adb5bd'); }
  if (o.hair === 'slick') { P(); ctx.ellipse(0, -410, 100, 66, 0, Math.PI, Math.PI * 2); ctx.quadraticCurveTo(60, -420, 0, -400); ctx.quadraticCurveTo(-60, -400, -100, -410); ctx.closePath(); fs(o.hairCol, 6); seg(-50, -450, 40, -440, 4, 'rgba(255,255,255,0.4)'); }
  if (o.horns) for (const sd of [-1, 1]) { P(); ctx.moveTo(sd * 50, -440); ctx.quadraticCurveTo(sd * 110, -500, sd * 96, -560); ctx.quadraticCurveTo(sd * 80, -490, sd * 20, -456); ctx.closePath(); fs('#f1f3f5', 6); }
  if (o.hair === 'sides') { for (const sd of [-1, 1]) { P(); ctx.ellipse(sd * 84, -392, 26, 40, sd * 0.4, 0, Math.PI * 2); fs(o.hairCol, 5); } }
  if (o.hair === 'curls') { for (let i = 0; i < 9; i++) { const a = Math.PI * (1.05 + i * 0.1); circ(Math.cos(a) * 92, -372 + Math.sin(a) * 100, 30); fs(o.hairCol, 5); } }
  if (o.hair === 'cap') {
    P(); ctx.arc(0, -392, 96, Math.PI, Math.PI * 2); ctx.closePath(); fs(o.hairCol, 6);
    rr(-104, -404, 208, 26, 10); fs(o.hairCol, 5); rr(50, -420, 90, 24, 10); fs(o.hairCol, 5);
  }
  // Augen
  const ey = -372, bigEye = mood === 'shocked' || mood === 'sabShock';
  for (const sd of [-1, 1]) {
    const ex = sd * 34;
    if (mood === 'dead' || mood === 'calm') { P(); ctx.arc(ex, ey - 2, 16, Math.PI * 0.15, Math.PI * 0.85); fs(null, 6); continue; }
    if (mood === 'excited') { P(); ctx.arc(ex, ey + 6, 16, Math.PI * 1.1, Math.PI * 1.9); fs(null, 7); continue; }
    if (mood === 'sick') { seg(ex - 14, ey - 6, ex + 14, ey + 4, 6); seg(ex - 14, ey + 4, ex + 14, ey - 6, 6); continue; }
    if (o.wink && sd > 0) { P(); ctx.arc(ex, ey + 4, 16, Math.PI * 1.1, Math.PI * 1.9); fs(null, 7); continue; }
    ell(ex, ey, bigEye ? 22 : 18, bigEye ? 26 : 20); fs(WHITE, 5);
    circ(ex + (o.lookX || 0) * 6, ey + 2 + (o.lookY || 0) * 6, bigEye ? 6 : 8); ctx.fillStyle = INK; ctx.fill();
    if (mood === 'smug' || mood === 'bored') { ctx.save(); ell(ex, ey, 19, 21); ctx.clip(); ctx.fillStyle = skin; ctx.fillRect(ex - 22, ey - 24, 44, 22); ctx.restore(); seg(ex - 18, ey - 2, ex + 18, ey - 2, 5); }
    if (mood === 'sad') { ell(ex + 4, ey + 34 + ((t * 60) % 40), 6, 9); fs('#74c0fc', 3); }
  }
  if (o.glasses) { for (const sd of [-1, 1]) { circ(sd * 34, ey, 30); fs(null, 6); } seg(-4, ey - 2, 4, ey - 2, 6); }
  // Brauen
  const bc = o.browCol || '#5c4033', bw = o.bushy ? 13 : 8, wig = o.wiggle ? Math.sin(t * 22) * 8 : 0;
  for (const sd of [-1, 1]) {
    const ex = sd * 34;
    if (mood === 'sad') seg(ex - sd * 20, ey - 38 - 8 + wig, ex + sd * 20, ey - 30 + wig, bw, bc);
    else if (mood === 'furious' || mood === 'angry') seg(ex - sd * 20, ey - 26, ex + sd * 20, ey - 42, bw, bc);
    else if (bigEye) seg(ex - 18, ey - 50, ex + 18, ey - 50, bw, bc);
    else seg(ex - 18, ey - 36 - wig * (sd > 0 ? 1 : 0), ex + 18, ey - 36 - wig * (sd > 0 ? 1 : 0), bw, bc);
  }
  ell(0, -334, 15, 19); ctx.fillStyle = 'rgba(160,80,60,0.25)'; ctx.fill();
  if (o.stubble) { ctx.fillStyle = 'rgba(80,60,50,0.35)'; for (let i = 0; i < 40; i++) { const a = Math.PI * (0.15 + 0.7 * rnd(i)); circ(Math.cos(a) * 78 * rnd(i + 3) ** 0.3, -360 + Math.sin(a) * 96 * (0.6 + 0.4 * rnd(i + 7)), 2.5); ctx.fill(); } }
  // Mund
  const my = -300, lc = o.lips || '#7a1f2b';
  if (m > 0.07) { ell(0, my + 4, 26 + 10 * m, 6 + 26 * m); fs('#4a1018', 6); if (o.lips) { ell(0, my + 4, 26 + 10 * m, 6 + 26 * m); fs(null, 6, o.lips); } }
  else if (mood === 'shocked' || mood === 'sabShock') { ell(0, my + 6, 18, 24); fs('#4a1018', 6); }
  else if (mood === 'sad' || mood === 'angry' || mood === 'furious') { P(); ctx.arc(0, my + 26, 26, Math.PI * 1.2, Math.PI * 1.8); fs(null, 7, lc); }
  else if (mood === 'excited') { P(); ctx.moveTo(-34, my - 6); ctx.quadraticCurveTo(0, my + 44, 34, my - 6); ctx.closePath(); fs('#4a1018', 6); ctx.fillStyle = WHITE; ctx.fillRect(-24, my - 4, 48, 10); }
  else if (mood === 'sick') { ell(-50, my - 4, 18, 14); fs('#8ce99a', 5); ell(50, my - 4, 18, 14); fs('#8ce99a', 5); seg(-22, my, 22, my, 7); }
  else if (mood === 'smug') { P(); ctx.arc(14, my - 22, 30, Math.PI * 0.2, Math.PI * 0.75); fs(null, 7, lc); }
  else if (mood === 'bored') seg(-22, my + 2, 22, my + 2, 6, lc);
  else { P(); ctx.arc(0, my - 18, 28, Math.PI * 0.25, Math.PI * 0.75); fs(null, 6, lc); }
  if (o.mustache) { P(); ctx.moveTo(-50, my - 12); ctx.quadraticCurveTo(0, my - 44, 50, my - 12); ctx.quadraticCurveTo(0, my - 22, -50, my - 12); ctx.closePath(); fs(o.mustache, 5); }
  if (mood === 'furious') for (const sd of [-1, 1]) { const u = (t * 2 + (sd > 0 ? 0.5 : 0)) % 1; alpha(1 - u, () => { circ(sd * 100, -470 - u * 90, 18 + u * 20); fs('rgba(255,255,255,0.85)', 0); }); }
  if (mood === 'sweat' || mood === 'shocked') { const u = (t * 1.5) % 1; ell(96, -420 + u * 60, 9, 14); fs('#a5d8ff', 4); }
  ctx.restore();
}

function emo(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
function phoneR(x, y, s = 1, rot = -0.15, screen) {
  at(x, y, s, rot, () => { rr(-40, -78, 80, 156, 14); fs('#212529', 5); rr(-32, -66, 64, 132, 8); fs(screen || '#4dabf7', 0); });
}
function flash(t, t0) { if (t >= t0 && t - t0 < 0.08) { ctx.fillStyle = 'rgba(255,255,255,0.35)'; ctx.fillRect(-80, -80, W + 160, H + 160); } }
/* Schnittliste: [[Zeit, fn]] – harter Schnitt mit kurzem Weißblitz */
function cutAt(t, list) {
  let cur = list[0];
  for (const s of list) if (t >= s[0]) cur = s;
  const st = cur[0];
  ctx.save(); cur[1](t, t - st); ctx.restore();
  flash(t, st > 0.1 ? st : -1);
}
function sketchTitle(t, title, emoji, until) {
  alpha(1 - fade(t, until, 0.3), () => at(540, 300, 1, -0.03, () => {
    rr(-440, -90, 880, 180, 24); fs('rgba(20,20,30,0.88)', 0);
    txt(title, -30, -14, 80, '#ffd43b', { maxW: 700 }); emo(emoji, 375, -16, 66);
    txt('Sketch', 0, 54, 30, WHITE, { weight: 700 });
  }));
}
function endCard(t, t0, line1, line2) {
  if (t < t0) return;
  alpha(fade(t, t0, 0.3), () => { ctx.fillStyle = 'rgba(0,0,0,0.5)'; ctx.fillRect(-80, -80, W + 160, H + 160); });
  at(540, 1040, pop(t, t0, 0.45), 0, () => { txt(line1, 0, 0, 64, '#ffd43b', { stroke: 12, maxW: 960 }); if (line2) txt(line2, 0, 80, 44, WHITE, { stroke: 9, weight: 800, maxW: 960 }); });
}

/* Kamera: Bildausschnitt um (fx, fy) mit Zoom z */
function cam(fx, fy, z, fn) { ctx.save(); ctx.translate(540, 960); ctx.scale(z, z); ctx.translate(-fx, -fy); fn(); ctx.restore(); }
function zoomIn(t, t0, z0, z1, d = 0.25) { return lerp(z0, z1, eOut(prog(t, t0, d))); }
