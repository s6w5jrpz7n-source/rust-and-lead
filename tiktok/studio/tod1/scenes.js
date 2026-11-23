'use strict';
/* DER TOD HAT MONTAG – animierter Sketch, schwarzer Humor */
window.EP_LOGO = false;
window.EP_NAMES = { T: 'TOD', C: 'CHEF', G: 'KUNDE' };
window.EP_CAPCOL = { T: '#cbb8ff', C: '#ff8787', G: '#8fe9ff' };
window.EP_STAMPS = ['ewig', 'kuendige', 'infinity', 'glow'];

const ROBE = '#24213a', ROBE_D = '#100f1a', BONE = '#efeadb', BONE_D = '#bfb79f', SOCKET = '#171523';
const DEVIL = '#e2483d', GHOST = '#e6f7ff', GHOST_D = '#7fb2c9', MONO2 = '"JetBrains Mono", monospace';

/* ---------- Figuren ---------- */
function boneHand(x, y) {
  for (const k of [-1, 0, 1]) { seg(x + k * 9, y + 6, x + k * 12, y + 30, 9, BONE_D); seg(x + k * 9, y + 6, x + k * 12, y + 30, 5, BONE); }
  circ(x, y, 18); fs(BONE, 4, BONE_D);
}
function drawScythe(x, y, s, rot) {
  at(x, y, s, rot, () => {
    limb(0, 0, 0, -860, 16, '#6b4f3a');
    P(); ctx.moveTo(4, -850); ctx.quadraticCurveTo(-120, -930, -300, -800); ctx.quadraticCurveTo(-150, -860, -2, -800); ctx.closePath();
    fs('#c9d1d9', 6, '#5d6670');
    seg(-40, -842, -250, -812, 4, 'rgba(255,255,255,0.6)');
  });
}
function drawTod(x, y, s, o = {}) {
  const t = o.t || 0, m = o.mouth || 0, mood = o.mood || 'tired';
  ctx.save(); ctx.translate(x, y); if (o.rot) ctx.rotate(o.rot); ctx.scale(s, s);
  P(); ctx.moveTo(-118, -385); ctx.quadraticCurveTo(-150, -200, -178, 0); ctx.lineTo(178, 0); ctx.quadraticCurveTo(150, -200, 118, -385); ctx.closePath(); fs(ROBE, 7, ROBE_D);
  seg(-40, -300, -62, -20, 5, ROBE_D); seg(40, -300, 66, -20, 5, ROBE_D);
  ell(0, -478, 130, 142); fs(ROBE, 7, ROBE_D);
  ell(0, -466, 100, 114); ctx.fillStyle = '#0a0911'; ctx.fill();
  // Schädel
  const jd = m * 20;
  rr(-44, -446 + jd, 88, 50, 18); fs(BONE, 5, BONE_D);
  for (let i = -3; i <= 3; i++) seg(i * 11, -446 + jd, i * 11, -428 + jd, 3, BONE_D);
  ell(0, -492, 70, 72); fs(BONE, 5, BONE_D);
  rr(-40, -452, 80, 14, 4); fs(BONE, 3, BONE_D);
  for (let i = -3; i <= 3; i++) seg(i * 11, -452, i * 11, -440, 3, BONE_D);
  for (const sd of [-1, 1]) {
    ell(sd * 27, -494, 21, 24); ctx.fillStyle = SOCKET; ctx.fill();
    if (mood !== 'blank') {
      const glow = mood === 'glow';
      ctx.save(); if (glow) { ctx.shadowColor = '#ff2d2d'; ctx.shadowBlur = 30; }
      circ(sd * 27 + (o.lookX || 0) * 6, -490 + (o.lookY || 0) * 6, mood === 'surprised' ? 9 : glow ? 8 : 6);
      ctx.fillStyle = glow ? '#ff2d2d' : '#f8f4e8'; ctx.fill(); ctx.restore();
    }
    if (mood === 'tired' || mood === 'annoyed') {
      ctx.save(); ell(sd * 27, -494, 21, 24); ctx.clip();
      P();
      if (mood === 'tired') { ctx.rect(sd * 27 - 30, -530, 60, 34); }
      else { ctx.moveTo(sd * 27 - 30, -530); ctx.lineTo(sd * 27 + 30, -530); ctx.lineTo(sd * 27 + 30 * -sd, -506); ctx.lineTo(sd * 27 - 30 * -sd, -490); ctx.closePath(); }
      ctx.fillStyle = BONE; ctx.fill(); ctx.restore();
      if (mood === 'tired') seg(sd * 27 - 20, -496, sd * 27 + 20, -496, 4, BONE_D);
      else seg(sd * 27 - 24 * -sd, -490, sd * 27 + 24 * -sd, -506, 4, BONE_D);
    }
  }
  P(); ctx.moveTo(0, -470); ctx.lineTo(-9, -454); ctx.lineTo(9, -454); ctx.closePath(); ctx.fillStyle = SOCKET; ctx.fill();
  seg(34, -548, 48, -528, 3, BONE_D); seg(48, -528, 42, -512, 3, BONE_D);
  // Arme
  const hl = o.handL || [-112, -150], hr = o.handR || [112, -150];
  limb(-100, -360, hl[0], hl[1] - 10, 42, ROBE); limb(100, -360, hr[0], hr[1] - 10, 42, ROBE);
  if (o.mug) drawMug(hr[0] + 30, hr[1] + 40, 0.9, t);
  boneHand(hl[0], hl[1]); boneHand(hr[0], hr[1]);
  ctx.restore();
}
function drawTeufel(x, y, s, o = {}) {
  const m = o.mouth || 0, t = o.t || 0;
  at(x, y, s, o.rot || 0, () => {
    P(); ctx.moveTo(-235, 0); ctx.quadraticCurveTo(-225, -150, -92, -178); ctx.lineTo(92, -178); ctx.quadraticCurveTo(225, -150, 235, 0); ctx.closePath(); fs('#26262f', 7);
    P(); ctx.moveTo(-60, -178); ctx.lineTo(0, -60); ctx.lineTo(60, -178); ctx.closePath(); fs(WHITE, 6);
    P(); ctx.moveTo(-14, -164); ctx.lineTo(14, -164); ctx.lineTo(22, -72); ctx.lineTo(0, -50); ctx.lineTo(-22, -72); ctx.closePath(); fs('#b3121f', 5);
    rr(-42, -222, 84, 64, 20); fs('#c93b31', 6);
    for (const sd of [-1, 1]) {
      P(); ctx.moveTo(sd * 58, -400); ctx.quadraticCurveTo(sd * 128, -478, sd * 96, -540); ctx.quadraticCurveTo(sd * 86, -466, sd * 26, -418); ctx.closePath(); fs('#f3e3c3', 6);
      P(); ctx.moveTo(sd * 112, -336); ctx.lineTo(sd * 156, -380); ctx.lineTo(sd * 114, -292); ctx.closePath(); fs(DEVIL, 6);
    }
    ell(0, -322, 118, 134); fs(DEVIL, 7);
    P(); ctx.moveTo(-114, -352); ctx.quadraticCurveTo(-104, -458, 0, -462); ctx.quadraticCurveTo(104, -458, 114, -352); ctx.quadraticCurveTo(60, -424, 0, -384); ctx.quadraticCurveTo(-60, -424, -114, -352); ctx.closePath(); fs('#1b1b22', 6);
    for (const sd of [-1, 1]) {
      P(); ctx.moveTo(sd * 18, -356); ctx.quadraticCurveTo(sd * 50, -386, sd * 88, -352); ctx.lineWidth = 10; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.stroke();
      ell(sd * 48, -324, 25, 17); fs('#ffd43b', 5);
      ell(sd * 48 + Math.sin(t * 1.3) * 4, -324, 4, 13); ctx.fillStyle = INK; ctx.fill();
    }
    ell(-70, -280, 16, 9); ctx.fillStyle = 'rgba(120,0,0,0.25)'; ctx.fill(); ell(70, -280, 16, 9); ctx.fill();
    const my = -262;
    if (m > 0.07) {
      P(); ctx.moveTo(-66, my); ctx.quadraticCurveTo(0, my + 26, 66, my); ctx.quadraticCurveTo(0, my + 40 + 60 * m, -66, my); ctx.closePath(); fs('#5a0d12', 6);
      ctx.save(); P(); ctx.moveTo(-66, my); ctx.quadraticCurveTo(0, my + 26, 66, my); ctx.quadraticCurveTo(0, my + 40 + 60 * m, -66, my); ctx.closePath(); ctx.clip();
      ctx.fillStyle = WHITE; ctx.fillRect(-70, my - 4, 140, 22); ctx.restore();
    } else {
      P(); ctx.moveTo(-68, my - 6); ctx.quadraticCurveTo(0, my + 44, 68, my - 6); ctx.quadraticCurveTo(0, my + 14, -68, my - 6); ctx.closePath(); fs(WHITE, 6);
    }
    P(); ctx.moveTo(-18, -208); ctx.lineTo(18, -208); ctx.lineTo(0, -170); ctx.closePath(); fs('#1b1b22', 5);
  });
}
function drawGeist(x, y, s, o = {}) {
  const t = o.t || 0, m = o.mouth || 0, mood = o.mood || 'shock';
  at(x, y + Math.sin(t * 2.2) * 14, s, Math.sin(t * 1.7) * 0.04, () => {
    ctx.save(); ctx.globalAlpha *= 0.93;
    P(); ctx.moveTo(-100, -20); ctx.bezierCurveTo(-118, -190, 118, -190, 100, -20); ctx.lineTo(112, 230);
    for (let i = 0; i <= 6; i++) { const xx = 112 - i * (224 / 6), yy = 230 + (i % 2 ? 36 : 0) + Math.sin(t * 6 + i) * 9; ctx.lineTo(xx, yy); }
    ctx.closePath(); fs(GHOST, 6, GHOST_D);
    ctx.restore();
    P(); ctx.moveTo(-40, -150); ctx.quadraticCurveTo(-10, -200, 10, -160); ctx.quadraticCurveTo(30, -205, 46, -150); fs(null, 6, GHOST_D);
    limb(-90, 40, -130, -20, 26, GHOST); limb(90, 40, 126, -10, 26, GHOST);
    at(140, -40, 1, 0.2, () => {
      rr(-30, -54, 60, 104, 12); fs('#1f2333', 5);
      rr(-22, -44, 44, 82, 6); fs('#8fe3ff', 0);
      seg(-18, -30, 14, 20, 3, WHITE); seg(14, -40, -6, 0, 3, WHITE);
    });
    for (const sd of [-1, 1]) {
      ell(sd * 36, -60, 24, mood === 'angry' ? 16 : 28); fs(WHITE, 5, GHOST_D);
      circ(sd * 36, -56, mood === 'shock' ? 6 : 9); ctx.fillStyle = INK; ctx.fill();
      if (mood === 'angry') seg(sd * 14, -88, sd * 60, -100, 8, INK);
      else { P(); ctx.arc(sd * 36, -104, 22, Math.PI * 1.15, Math.PI * 1.85); fs(null, 7, INK); }
    }
    if (m > 0.07) { ell(0, 22, 22 + 8 * m, 8 + 30 * m); fs('#2f4a5a', 5, GHOST_D); }
    else if (mood === 'angry') { P(); ctx.arc(0, 44, 22, Math.PI * 1.2, Math.PI * 1.8); fs(null, 7, INK); }
    else { ell(0, 22, 14, 18); fs('#2f4a5a', 5, GHOST_D); }
  });
}

/* ---------- Requisiten ---------- */
function drawMug(x, y, s, t) {
  at(x, y, s, 0, () => {
    P(); ctx.arc(36, -42, 22, -Math.PI / 2, Math.PI / 2); ctx.lineWidth = 12; ctx.strokeStyle = INK; ctx.stroke(); ctx.lineWidth = 6; ctx.strokeStyle = WHITE; ctx.stroke();
    rr(-36, -84, 72, 84, 12); fs(WHITE, 6);
    txt('No.1', 0, -50, 20, RED, { weight: 900 });
    txt('SENSENMANN', 0, -28, 9, INK, { weight: 800 });
    for (let i = 0; i < 2; i++) { const u = (t * 0.8 + i * 0.5) % 1; alpha((1 - u) * 0.6, () => { P(); ctx.moveTo(-10 + i * 20, -90 - u * 60); ctx.quadraticCurveTo(-24 + i * 20, -110 - u * 60, -10 + i * 20, -130 - u * 60); fs(null, 5, '#ffffff'); }); }
  });
}
function drawAlarm(x, y, t, ringing) {
  const r = ringing ? Math.sin(t * 60) * 0.14 : 0;
  at(x, y, 1, r, () => {
    seg(-34, -10, -46, 6, 8); seg(34, -10, 46, 6, 8);
    for (const sd of [-1, 1]) { circ(sd * 40, -128, 24); fs('#ffd43b', 6); }
    seg(0, -150, 0, -132, 6);
    circ(0, -70, 62); fs('#e03131', 7); circ(0, -70, 46); fs(WHITE, 5);
    seg(0, -70, 0, -104, 6); seg(0, -70, 0, -40, 4, RED);
  });
  if (ringing) for (let i = 0; i < 3; i++) { const a = -2.4 + i * 0.6; seg(x + Math.cos(a) * 90, y - 80 + Math.sin(a) * 90, x + Math.cos(a) * 120, y - 80 + Math.sin(a) * 120, 7, YELLOW); seg(x - Math.cos(a) * 90, y - 80 + Math.sin(a) * 90, x - Math.cos(a) * 120, y - 80 + Math.sin(a) * 120, 7, YELLOW); }
}
function drawMonitor(x, y, w, h, fn) {
  rr(x - 30, y, 60, 40, 6); fs('#2c2e3a', 5);
  rr(x - 90, y + 30, 180, 16, 8); fs('#2c2e3a', 5);
  rr(x - w / 2, y - h, w, h, 18); fs('#14151d', 7);
  ctx.save(); rr(x - w / 2 + 14, y - h + 14, w - 28, h - 28, 10); ctx.clip();
  fn(x - w / 2 + 14, y - h + 14, w - 28, h - 28);
  ctx.restore();
}
function ticketGlow(x0, y0, w, h, t) {
  ctx.fillStyle = '#eef1f8'; ctx.fillRect(x0, y0, w, h);
  ctx.fillStyle = '#20222e'; ctx.fillRect(x0, y0, w, 34);
  for (let i = 0; i < 6; i++) { const yy = y0 + 46 + i * 32 - ((t * 20) % 32); ctx.fillStyle = i % 2 ? '#dfe3ee' : '#e9ecf4'; ctx.fillRect(x0 + 8, yy, w - 16, 26); ctx.fillStyle = RED; ctx.fillRect(x0 + w - 60, yy + 6, 44, 14); }
}
function officeBG(t) {
  bg('#2c3150', '#1b1e2f');
  rr(60, 330, 380, 440, 10); ctx.fillStyle = '#141625'; ctx.fill();
  ctx.save(); rr(76, 346, 348, 408, 6); ctx.clip();
  const g = ctx.createLinearGradient(0, 346, 0, 754); g.addColorStop(0, '#5b4b8a'); g.addColorStop(0.65, '#e9727c'); g.addColorStop(1, '#ffb36b');
  ctx.fillStyle = g; ctx.fillRect(76, 346, 348, 408);
  circ(310, 730, 64); ctx.fillStyle = 'rgba(255,225,160,0.95)'; ctx.fill();
  const bl = [[76, 60, 180], [130, 52, 262], [178, 70, 150], [242, 46, 226], [284, 82, 300], [360, 70, 190]];
  bl.forEach(([bx, bw, bh], i) => {
    ctx.fillStyle = '#23243a'; ctx.fillRect(bx, 754 - bh, bw, bh);
    for (let j = 0; j < 8; j++) if (rnd(i * 13 + j) > 0.55) { ctx.fillStyle = '#ffd56b'; ctx.fillRect(bx + 8 + (j % 3) * 16, 754 - bh + 14 + Math.floor(j / 3) * 30, 8, 12); }
  });
  ctx.restore();
  seg(250, 346, 250, 754, 10, '#141625'); seg(76, 550, 424, 550, 10, '#141625');
  const flick = rnd(Math.floor(t * 12) + 7) > 0.92 ? 0.25 : 1;
  const lg = ctx.createRadialGradient(750, 262, 10, 750, 262, 420);
  lg.addColorStop(0, `rgba(230,240,255,${0.28 * flick})`); lg.addColorStop(1, 'rgba(230,240,255,0)');
  ctx.fillStyle = lg; ctx.fillRect(300, 0, 900, 700);
  rr(560, 250, 380, 24, 12); ctx.fillStyle = flick < 1 ? '#8a90a3' : '#eef2fa'; ctx.fill();
  at(850, 470, 1, 0.04, () => {
    rr(-95, -110, 190, 220, 8); fs('#f4f1ea', 5, '#141625');
    ctx.fillStyle = '#d64545'; ctx.fillRect(-95, -110, 190, 50);
    txt('MONTAG', 0, -84, 30, WHITE); txt('1', 0, 4, 90, INK); txt('von ∞', 0, 76, 28, '#555', { weight: 800 });
  });
  drawScythe(140, 1150, 0.95, -0.13);
}
function deskFront() {
  ctx.fillStyle = '#6b5446'; ctx.fillRect(-80, 1140, W + 160, 36);
  ctx.fillStyle = '#4a3a31'; ctx.fillRect(-80, 1174, W + 160, 600);
  seg(-80, 1176, W + 80, 1176, 5, '#2b211c');
}

/* ---------- Szenen ---------- */
function todAtDesk(t, x, o = {}) {
  const typing = o.typing ? Math.sin(t * 22) * 6 : 0;
  const opts = { t, handL: [-120, -328 + typing], handR: [120, -328 - typing] };
  for (const k in o) if (o[k] !== undefined) opts[k] = o[k];
  drawTod(x, 1560 + (o.dy || 0), 1.35, opts);
}
function sceneOffice(t) {
  officeBG(t);
  const wake = C('wake');
  const rise = eOut(prog(t, wake - 0.15, 0.55));
  const sleeping = rise < 1;
  todAtDesk(t, 430, { mood: rise < 0.5 ? 'blank' : 'tired', mouth: mouthOf('T', t), dy: (1 - rise) * 190, rot: (1 - rise) * 0.32, lookY: 0.3 });
  deskFront();
  rr(300, 1118, 260, 26, 6); fs('#3a3d4d', 5);
  drawAlarm(170, 1150, t, t < C('ring') + 1.1 && t > C('ring') - 0.05);
  drawMug(600, 1146, 1, t);
  drawMonitor(800, 1110, 330, 250, (x0, y0, w, h) => ticketGlow(x0, y0, w, h, t));
  if (sleeping) for (let i = 0; i < 3; i++) { const u = (t * 0.9 + i / 3) % 1; alpha((1 - u) * (1 - rise), () => txt('Z', 520 + u * 80 + i * 10, 900 - u * 160, 50 + i * 12, WHITE, { stroke: 8 })); }
  const tm = C('todmuede');
  alpha(1 - fade(t, tm - 0.2, 0.3), () => at(540, 400, 1, 0, () => {
    txt('DER TOD', 0, -60, 120, WHITE, { stroke: 18 });
    txt('HAT MONTAG', 0, 70, 120, '#ff6b6b', { stroke: 18, maxW: 980 });
  }));
  if (t >= tm - 0.05) at(540, 520, pop(t, tm - 0.05, 0.4), -0.05, () => {
    const w1 = tw('TOD', 140), w2 = tw('MÜDE', 140);
    txt('TOD', -w2 / 2, 0, 140, '#ff6b6b', { stroke: 20 }); txt('MÜDE', w1 / 2, 0, 140, WHITE, { stroke: 20 });
  });
}
const TICKETS = [
  ['#4812', 'Herbert K., 87', 'Altersschwäche', 'normal', '#868e96'],
  ['#4813', 'Kevin S., 24', 'Selfie am Abgrund', 'hoch', RED],
  ['#4814', 'Gabi M., 52', 'Pilze selbst gesammelt', 'hoch', RED],
  ['#4815', 'Unbekannt', '„Halt mal mein Bier“', 'dringend', ORANGE],
  ['#4816', 'Dieter P., 61', 'Grill + Benzin', 'hoch', RED],
  ['#4817', 'Jens T., 33', 'Handy beim Überqueren', 'hoch', RED],
  ['#4818', 'Ilse W., 103', 'hat einfach keine Lust mehr', 'niedrig', '#2f9e44'],
  ['#4819', 'Marco B., 45', 'Bungee, Seil „passt schon“', 'hoch', RED],
];
function sceneInbox(t) {
  bg('#15161f', '#0d0e14');
  rr(40, 300, 1000, 880, 30); fs('#0f1017', 10, '#2a2c3a');
  ctx.save(); rr(64, 324, 952, 832, 16); ctx.clip();
  ctx.fillStyle = '#f3f4f8'; ctx.fillRect(64, 324, 952, 832);
  ctx.fillStyle = '#20222e'; ctx.fillRect(64, 324, 952, 104);
  at(116, 376, 0.32, 0, () => { ell(0, -488 + 480, 70, 72); fs(BONE, 8, BONE_D); for (const sd of [-1, 1]) { ell(sd * 27, -14, 21, 24); ctx.fillStyle = SOCKET; ctx.fill(); } });
  txt('JENSEITS GmbH', 150, 360, 36, WHITE, { align: 'left' });
  txt('Ticketsystem · Außendienst', 150, 398, 24, '#9aa0b4', { align: 'left', weight: 700 });
  const n = Math.round(lerp(4690, 4812, eOut(prog(t, C('count') - 0.1, 1.3))));
  pill(`${n.toLocaleString('de-DE')} offen`, 820, 376, 34, RED, WHITE, { lw: 0 });
  const t0 = T('b1') - 0.3;
  TICKETS.forEach((tk, i) => {
    const appear = t0 + i * 0.32;
    if (t < appear) return;
    const yy = 450 + i * 96 + (1 - eOut(prog(t, appear, 0.3))) * 40;
    alpha(fade(t, appear, 0.25), () => {
      rr(84, yy, 912, 84, 14); fs(i % 2 ? WHITE : '#f8f9fc', 3, '#e1e4ee');
      ctx.save(); ctx.font = `700 24px ${MONO2}`; ctx.fillStyle = '#868e96'; ctx.textBaseline = 'middle'; ctx.fillText(tk[0], 104, yy + 28); ctx.restore();
      txt(tk[1], 204, yy + 28, 30, INK, { align: 'left' });
      txt(tk[2], 104, yy + 62, 26, '#495057', { align: 'left', weight: 600 });
      pill(tk[3], 830, yy + 42, 24, tk[4], WHITE, { lw: 0 });
    });
  });
  const ps = C('persoenlich');
  if (t >= ps) { const a = eOut(prog(t, ps, 0.3)); ctx.fillStyle = `rgba(255,71,87,${0.95 * a})`; ctx.fillRect(64, 1156 - 70 * a, 952, 70); txt('Selbstabholung: nicht möglich.', 540, 1156 - 35 * a, 34, WHITE, { alpha: a }); }
  ctx.restore();
  const click = Math.abs(Math.sin(t * 7)) > 0.95 ? 0.94 : 1;
  at(860, 1260, click, 0, () => { rr(-46, -70, 92, 130, 46); fs('#2c2e3a', 6, '#0b0b10'); seg(0, -70, 0, -20, 4, '#0b0b10'); limb(60, 90, 20, -10, 40, ROBE); boneHand(10, -40); });
}
function sceneMeeting(t) {
  bg('#1d1e24', '#141519');
  txt('Team-Meeting: Q4-Ziele Jenseits', 70, 262, 30, WHITE, { align: 'left', weight: 800 });
  circ(1000, 262, 10); ctx.fillStyle = RED; ctx.fill();
  ctx.save(); ctx.font = `700 22px ${MONO2}`; ctx.fillStyle = '#9aa0b4'; ctx.textAlign = 'right'; ctx.textBaseline = 'middle'; ctx.fillText('REC · 23 Teilnehmer', 980, 262); ctx.restore();
  const cS = gLineSpk(t) === 'C', tS = gLineSpk(t) === 'T';
  // Haupt-Kachel: Chef
  rr(50, 310, 980, 690, 26); ctx.fillStyle = '#2a1416'; ctx.fill();
  ctx.save(); rr(50, 310, 980, 690, 26); ctx.clip();
  const g = ctx.createLinearGradient(0, 310, 0, 1000); g.addColorStop(0, '#3b1214'); g.addColorStop(1, '#a8321f'); ctx.fillStyle = g; ctx.fillRect(50, 310, 980, 690);
  for (let i = 0; i < 9; i++) { const fx = 60 + i * 120, fh = 80 + Math.abs(Math.sin(t * 4 + i * 1.7)) * 70; P(); ctx.moveTo(fx, 1000); ctx.quadraticCurveTo(fx + 30, 1000 - fh * 1.4, fx + 60, 1000 - fh * 0.4); ctx.quadraticCurveTo(fx + 80, 1000 - fh, fx + 110, 1000); ctx.closePath(); ctx.fillStyle = i % 2 ? 'rgba(255,146,43,0.8)' : 'rgba(255,212,59,0.7)'; ctx.fill(); }
  at(760, 520, pop(t, C('goal') - 0.05, 0.4), 0.03, () => {
    rr(-200, -150, 400, 290, 14); fs('#fff8f0', 6);
    txt('ZIELVORGABE', 0, -108, 34, '#b3121f');
    txt('mehr Kundennähe', 0, -62, 30, INK, { weight: 800 });
    P(); ctx.moveTo(-150, 100); ctx.lineTo(-60, 40); ctx.lineTo(10, 70); ctx.lineTo(140, -20); ctx.lineWidth = 10; ctx.strokeStyle = '#2f9e44'; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.stroke();
    arrowHead(146, -24, -0.6, 22, '#2f9e44');
  });
  drawTeufel(370, 1000, 1.25, { t, mouth: mouthOf('C', t) });
  ctx.restore();
  rr(50, 310, 980, 690, 26); fs(null, cS ? 8 : 0, '#40c057');
  pill('Chef (Luzifer)', 190, 960, 24, 'rgba(0,0,0,0.55)', WHITE, { lw: 0 });
  // kleine Kachel: Tod
  rr(560, 1030, 380, 250, 22); ctx.fillStyle = '#20233a'; ctx.fill();
  ctx.save(); rr(560, 1030, 380, 250, 22); ctx.clip();
  drawTod(750, 1640, 1.05, { t, mood: 'tired', mouth: mouthOf('T', t), handL: [-120, -260], handR: [120, -260] });
  ctx.restore();
  rr(560, 1030, 380, 250, 22); fs(null, tS ? 8 : 4, tS ? '#40c057' : '#3a3d4d');
  pill('Tod · Außendienst', 670, 1250, 20, 'rgba(0,0,0,0.55)', WHITE, { lw: 0 });
  // Chat
  const ch = C('chat');
  [['Pest', 'Top!'], ['Krieg', '+1'], ['Hungersnot', 'Stark!!']].forEach(([who, msg], i) => {
    const a0 = ch + 0.15 + i * 0.35;
    if (t < a0) return;
    at(300, 1070 + i * 72, pop(t, a0, 0.3), 0, () => {
      const w = tw(`${who}: ${msg}`, 28, 700) + 40;
      rr(-w / 2, -28, w, 56, 18); fs('#2c2e3a', 0);
      txt(`${who}: ${msg}`, 0, 2, 28, WHITE, { weight: 700 });
    });
  });
}
function gLineSpk(t) { const l = TL.lines.find(l => t >= l.start - 0.04 && t <= l.end + 0.04); return l ? l.spk : null; }
function sceneStreet(t) {
  bg('#0f1530', '#2b2f5a');
  ctx.save(); ctx.fillStyle = 'rgba(255,255,255,0.7)';
  for (let i = 0; i < 40; i++) { const r = rnd(i + 3) * 2 + 1; ctx.globalAlpha = 0.4 + 0.6 * Math.abs(Math.sin(t * 2 + i)); circ(rnd(i) * W, 260 + rnd(i + 9) * 420, r); ctx.fill(); }
  ctx.restore();
  circ(860, 420, 60); ctx.fillStyle = '#fff6d6'; ctx.fill(); circ(884, 404, 52); ctx.fillStyle = '#1a2142'; ctx.fill();
  [[0, 160, 420], [150, 120, 540], [260, 180, 380], [430, 140, 600], [560, 200, 450], [750, 150, 520], [890, 190, 400]].forEach(([bx, bw, bh], i) => {
    ctx.fillStyle = '#161a33'; ctx.fillRect(bx, 1090 - bh, bw, bh);
    for (let j = 0; j < 14; j++) if (rnd(i * 31 + j) > 0.6) { ctx.fillStyle = '#ffd56b'; ctx.fillRect(bx + 14 + (j % 4) * 34, 1090 - bh + 24 + Math.floor(j / 4) * 60, 16, 26); }
  });
  ctx.fillStyle = '#3a3b46'; ctx.fillRect(-80, 1090, W + 160, 60);
  ctx.fillStyle = '#26272f'; ctx.fillRect(-80, 1150, W + 160, 700);
  for (let i = 0; i < 7; i++) { ctx.fillStyle = 'rgba(240,240,240,0.85)'; ctx.fillRect(60 + i * 140, 1180, 90, 200); }
  limb(110, 1100, 110, 640, 12, '#4a4e5e'); rr(70, 620, 120, 34, 10); fs('#4a4e5e', 6);
  P(); ctx.moveTo(90, 654); ctx.lineTo(130, 654); ctx.lineTo(260, 1100); ctx.lineTo(-40, 1100); ctx.closePath(); ctx.fillStyle = 'rgba(255,224,130,0.13)'; ctx.fill();
  limb(910, 1100, 910, 780, 10, '#4a4e5e'); rr(870, 690, 80, 110, 12); fs('#1f2028', 6);
  ctx.save(); ctx.shadowColor = RED; ctx.shadowBlur = 20; circ(910, 724, 14); ctx.fillStyle = RED; ctx.fill(); ctx.fillRect(904, 738, 12, 26); ctx.restore();
  // Geist
  const gIn = C('ghostIn');
  const ga = fade(t, gIn - 0.2, 0.5);
  const gl = TL.lines.find(l => l.spk === 'G' && t >= l.start - 0.1 && t <= l.end + 0.6);
  const gmood = t >= T('d3') - 0.05 ? 'angry' : 'shock';
  alpha(ga, () => drawGeist(300, 900 - (1 - ga) * 120, 1.0, { t, mouth: mouthOf('G', t), mood: gmood }));
  if (t >= C('tot') && t < C('tot') + 1.2) at(430, 690, pop(t, C('tot'), 0.3), 0.1, () => txt('?!', 0, 0, 110, YELLOW, { stroke: 14 }));
  // Tod
  drawScythe(600, 1300, 0.95, -0.08);
  drawTod(760, 1300, 1.05, { t, mood: 'tired', mouth: mouthOf('T', t), handL: [-150, -300], handR: [110, -250] });
  at(760 + 110 * 1.05 + 10, 1300 - 250 * 1.05 - 40, 1, 0.1, () => { rr(-50, -66, 100, 132, 12); fs('#2c2e3a', 6); rr(-40, -54, 80, 108, 6); fs('#bfe3ff', 0); txt('#4817', 0, -30, 18, INK); });
  alpha(1 - fade(t, T('d3') - 0.2, 0.3), () => at(740, 560, pop(t, C('third') - 0.05, 0.4), -0.04, () => pill('Handy-Fälle heute: 3', 0, 0, 38, ORANGE, WHITE)));
  // Formular
  const fm = C('form');
  if (t >= fm - 0.05) at(540, 560, 0.85 * pop(t, fm - 0.05, 0.45), -0.05 + Math.sin(t * 2) * 0.02, () => {
    rr(-190, -230, 380, 460, 12); fs('#fffdf6', 6);
    txt('FORMULAR 7b', 0, -186, 40, INK);
    txt('Beschwerde über das', 0, -136, 26, '#495057', { weight: 700 });
    txt('eigene Ableben', 0, -104, 26, '#495057', { weight: 700 });
    for (let i = 0; i < 6; i++) { seg(-150, -50 + i * 44, 150, -50 + i * 44, 3, '#ced4da'); rr(-160, -66 + i * 44, 18, 18, 3); fs(null, 3, '#adb5bd'); }
  });
  stamp('BEARBEITUNG: ∞', 540, 650, t, C('ewig'), -0.14, { size: 54 });
}
function sceneQuit(t) {
  officeBG(t);
  const kd = C('kuendige'), inf = C('infinity'), cof = C('coffee');
  const leave = eIO(prog(t, cof + 0.7, 1.3));
  const mood = t >= inf - 0.1 && t < cof ? 'blank' : (t >= T('e1') && t < T('e2') ? 'annoyed' : 'tired');
  const slam = t >= kd - 0.25 && t < kd + 0.3;
  todAtDesk(t, 430 + leave * 950, {
    mood, mouth: mouthOf('T', t), lookX: 0.8,
    handL: slam ? [-125, -328 - Math.max(0, (kd - t)) * 300] : undefined,
    handR: t >= cof + 0.3 ? [140, -340] : undefined,
    mug: t >= cof + 0.3,
  });
  deskFront();
  rr(300, 1118, 260, 26, 6); fs('#3a3d4d', 5);
  if (t < cof + 0.3) drawMug(600, 1146, 1, t);
  drawMonitor(800, 1110, 330, 250, (x0, y0, w, h) => {
    const g = ctx.createLinearGradient(0, y0, 0, y0 + h); g.addColorStop(0, '#3b1214'); g.addColorStop(1, '#a8321f'); ctx.fillStyle = g; ctx.fillRect(x0, y0, w, h);
    drawTeufel(x0 + w / 2, y0 + h + 10, 0.44, { t, mouth: mouthOf('C', t) });
  });
  if (t >= kd - 0.05) at(215, 1128, 0.85 * pop(t, kd - 0.05, 0.3), -0.1, () => {
    rr(-120, -150, 240, 170, 8); fs(WHITE, 5);
    txt('KÜNDIGUNG', 0, -112, 32, RED);
    for (let i = 0; i < 3; i++) seg(-90, -66 + i * 26, 90 - i * 30, -66 + i * 26, 3, '#ced4da');
  });
  if (t >= inf - 0.05) {
    at(540, 560, pop(t, inf - 0.05, 0.45), 0, () => {
      txt('Kündigungsfrist:', 0, -170, 50, WHITE, { stroke: 12 });
      txt('∞', 0, 20, 340, RED, { stroke: 24, sc: WHITE });
    });
  }
}
function sceneOutro(t) {
  bg('#0c0b14', '#050409');
  const gl = C('glow');
  const pulse = t >= gl ? 0.5 + 0.5 * Math.sin((t - gl) * 6) : 0;
  const rg = ctx.createRadialGradient(540, 1000, 50, 540, 1000, 900);
  rg.addColorStop(0, `rgba(160,20,30,${0.18 + 0.25 * pulse * (t >= gl ? 1 : 0)})`); rg.addColorStop(1, 'rgba(0,0,0,0)');
  ctx.fillStyle = rg; ctx.fillRect(0, 0, W, H);
  const lean = eIO(prog(t, T('f1'), E('f1') - T('f1') + 0.5));
  const s = lerp(2.0, 2.3, lean);
  drawTod(540, 2080 + (s - 2.0) * 180, s, { t, mood: t >= gl ? 'glow' : 'tired', mouth: mouthOf('T', t), handL: [-150, -260], handR: [150, -260] });
  const end = E('f2') + 0.35;
  at(540, 380, pop(t, end, 0.45), 0, () => {
    txt('DER TOD', 0, -60, 110, WHITE, { stroke: 16 });
    txt('HAT MONTAG', 0, 60, 110, '#ff6b6b', { stroke: 16, maxW: 980 });
  });
  at(540, 560, pop(t, end + 0.3, 0.4), 0, () => txt('Folg mir. Das Leben ist kurz.', 0, 0, 46, WHITE, { stroke: 10, weight: 800 }));
}

window.EP_SCENES = { office: sceneOffice, inbox: sceneInbox, meeting: sceneMeeting, street: sceneStreet, quit: sceneQuit, outro: sceneOutro };
