'use strict';
/* OPAS TESTAMENT – Sitcom-Sketch mit harten Schnitten (Notar / Fernseher mit VHS-Opa / Sofa-Gegenschuss) */
window.EP_LOGO = false;
window.EP_NAMES = { N: 'NOTAR', O: 'OPA (†)', U: 'UWE', S: 'SABINE', K: 'KEVIN' };
window.EP_CAPCOL = { N: '#ced4da', O: '#ffd43b', U: '#74c0fc', S: '#ff8787', K: '#69db7c' };
window.EP_STAMPS = ['mord', 'bremsen', 'oma', 'salat2'];
const MONO3 = '"JetBrains Mono", monospace';
const SKIN1 = '#f2c7a5', SKIN_OLD = '#efc9b0', SKIN_K = '#e8b894';

/* ---------- Universal-Figur (sitzend, frontal; Ursprung = Sitzfläche, Kopf bei y=-360) ---------- */
function person(x, y, s, o) {
  const t = o.t || 0, m = o.mouth || 0, mood = o.mood || 'neutral', skin = o.skin || SKIN1;
  ctx.save(); ctx.translate(x, y); if (o.rot) ctx.rotate(o.rot); ctx.scale(s, s);
  if (!o.noLegs) {
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
  ell(0, -360, 92, 106); fs(skin, 7);
  if (mood === 'furious' || mood === 'sick') { ell(0, -360, 89, 103); ctx.fillStyle = mood === 'furious' ? 'rgba(255,40,40,0.35)' : 'rgba(80,200,60,0.4)'; ctx.fill(); }
  // Haare
  if (o.hair === 'bob') { P(); ctx.ellipse(0, -400, 100, 80, 0, Math.PI, Math.PI * 2); ctx.quadraticCurveTo(40, -420, -10, -398); ctx.quadraticCurveTo(-60, -410, -100, -400); ctx.closePath(); fs(o.hairCol, 6); seg(-30, -460, 20, -420, 6, '#fff3bf'); }
  if (o.hair === 'receding') { P(); ctx.arc(0, -380, 96, Math.PI * 1.05, Math.PI * 1.32); ctx.lineTo(-40, -440); ctx.closePath(); fs(o.hairCol, 5); P(); ctx.arc(0, -380, 96, Math.PI * 1.68, Math.PI * 1.95); ctx.lineTo(40, -440); ctx.closePath(); fs(o.hairCol, 5); }
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
const CAST = {
  U: { shirt: '#c4a484', collar: '#e9dcc3', pants: '#5c677d', hair: 'receding', hairCol: '#8d7b68', mustache: '#6b5a4a' },
  S: { shirt: '#f783ac', pants: '#495057', hair: 'bob', hairCol: '#ffe066', browCol: '#a07c3c', earrings: true, lips: '#e03131' },
  K: { shirt: '#868e96', hood: '#6c757d', pants: '#343a40', hair: 'cap', hairCol: '#1c7ed6', stubble: true, skin: SKIN_K },
};

/* ---------- Requisiten ---------- */
function beer(x, y) { rr(x - 14, y - 90, 28, 96, 8); fs('#7a4b00', 5); rr(x - 8, y - 120, 16, 34, 5); fs('#7a4b00', 5); rr(x - 14, y - 60, 28, 30, 3); fs('#fff3bf', 3); }
function phone(x, y) { at(x, y - 20, 1, -0.2, () => { rr(-22, -40, 44, 80, 8); fs('#212529', 5); rr(-16, -32, 32, 62, 4); fs('#74c0fc', 0); }); }
function bowl(x, y, s = 1) {
  at(x, y, s, 0, () => {
    P(); ctx.ellipse(0, 0, 120, 70, 0, 0, Math.PI); ctx.closePath(); fs('#e9ecef', 6);
    for (let i = 0; i < 9; i++) { circ(-80 + i * 20, -12 - (i % 3) * 10, 26); fs('#ffe8a1', 4, '#d9a441'); }
    for (let i = 0; i < 8; i++) { circ(-70 + i * 20, -22 - (i % 2) * 14, 4); ctx.fillStyle = '#2f9e44'; ctx.fill(); }
    ell(0, 0, 122, 22); fs(null, 6);
  });
}
function toolbox(x, y, s = 1) { at(x, y, s, -0.08, () => { rr(-110, -60, 220, 110, 10); fs('#e03131', 6); rr(-50, -96, 100, 40, 14); fs(null, 10); rr(-110, -24, 220, 14, 3); fs('#c92a2a', 0); circ(0, -14, 10); fs('#ced4da', 4); }); }
function car(x, y, s = 1, t = 0) {
  at(x, y, s, 0, () => {
    P(); ctx.moveTo(-170, 20); ctx.lineTo(-170, -30); ctx.lineTo(-110, -40); ctx.lineTo(-70, -100); ctx.lineTo(70, -100); ctx.lineTo(120, -40); ctx.lineTo(170, -30); ctx.lineTo(170, 20); ctx.closePath(); fs('#5c940d', 7);
    rr(-60, -90, 56, 46, 6); fs('#a5d8ff', 5); rr(6, -90, 60, 46, 6); fs('#a5d8ff', 5);
    for (const [rx, ry, rrr] of [[-120, -10, 18], [40, 0, 14], [130, -20, 10], [-20, -70, 9]]) { ell(rx, ry, rrr * 1.4, rrr); ctx.fillStyle = '#a0522d'; ctx.fill(); }
    for (const sd of [-1, 1]) { circ(sd * 105, 28, 36); fs('#212529', 6); circ(sd * 105, 28, 12); fs(sd > 0 ? '#adb5bd' : '#212529', 4); }
    seg(-150, -50, -60, -40, 4, INK);
  });
}
function money(x, y, t, t0) {
  for (let i = 0; i < 14; i++) {
    const u = ((t - t0) * 0.6 + rnd(i)) % 1;
    at(x - 240 + rnd(i + 3) * 480, y - 300 + u * 600, 1, Math.sin(t * 4 + i) * 0.5, () => { rr(-40, -20, 80, 40, 4); fs('#69db7c', 4, '#2b8a3e'); txt('€', 0, 2, 24, '#2b8a3e'); });
  }
}
function polaroid(x, y, s, t, wink) {
  at(x, y, s, 0.12 + Math.sin(t * 2) * 0.03, () => {
    rr(-120, -150, 240, 290, 8); fs(WHITE, 6);
    ctx.save(); rr(-100, -130, 200, 200, 4); ctx.clip(); ctx.fillStyle = '#ffd8a8'; ctx.fillRect(-100, -130, 200, 200);
    person(0, 250, 0.5, { t, mood: 'smug', hair: 'curls', hairCol: '#ced4da', lips: '#e03131', glasses: true, skin: SKIN_OLD, shirt: '#ae3ec9', noLegs: true, wink });
    ctx.restore();
    txt('Gerda ♥', 0, 110, 30, INK, { weight: 800 });
  });
}
function proteinCan(x, y, s, t, oma) {
  at(x, y, s, 0, () => {
    rr(-90, -130, 180, 230, 20); fs('#212529', 6); rr(-96, -150, 192, 36, 10); fs('#343a40', 6);
    rr(-80, -80, 160, 110, 8); fs(oma ? '#f1f3f5' : '#fab005', 0);
    if (!oma) { txt('PROTEIN', 0, -40, 34, INK); txt('Vanille', 0, 0, 24, INK, { weight: 700 }); }
    else { txt('OMA', 0, -36, 48, INK); txt('† 2019', 0, 6, 24, INK, { weight: 700 }); }
  });
}
function staticNoise(x, y, w, h, t) {
  const f = Math.floor(t * 30);
  for (let i = 0; i < 260; i++) { const v = Math.floor(rnd(i * 3 + f * 17) * 255); ctx.fillStyle = `rgb(${v},${v},${v})`; ctx.fillRect(x + rnd(i + f * 7) * w, y + rnd(i * 5 + f) * h, 20 + rnd(i) * 60, 4 + rnd(i + 9) * 10); }
}

/* ---------- Fernsehinhalt (Designfläche 900x780) ---------- */
function opaMood(t) {
  if (t >= C('finger')) return 'angry';
  if (t >= C('oma')) return 'smug';
  if (t >= C('gerda') && t < E('o8') + 0.3) return 'smug';
  if (t >= T('o3') && t < E('o3')) return 'angry';
  return 'neutral';
}
function tvContent(t, x, y, w, h) {
  ctx.save(); rr(x, y, w, h, 46 * w / 900); ctx.clip();
  ctx.fillStyle = '#000'; ctx.fillRect(x, y, w, h);
  const on = C('vhsOn'), off = C('vhsOff');
  ctx.translate(x, y); ctx.scale(w / 900, h / 780);
  if (t < on) { ctx.restore(); return; }
  if (t < on + 0.45 || (t >= off && t < off + 0.25)) { staticNoise(0, 0, 900, 780, t); ctx.restore(); return; }
  if (t >= off + 0.25) {
    const u = prog(t, off + 0.25, 0.35);
    ctx.fillStyle = WHITE; const lw = 900 * (1 - u * 0.95), lh = Math.max(4, 780 * Math.max(0, 0.06 - u * 0.06));
    if (u < 1) ctx.fillRect(450 - lw / 2, 390 - lh / 2, lw, lh);
    ctx.restore(); return;
  }
  ctx.fillStyle = '#c4691f'; ctx.fillRect(0, 0, 900, 780);
  for (let i = 0; i < 8; i++) for (let j = 0; j < 8; j++) { circ(60 + i * 120 + (j % 2) * 60, 40 + j * 110, 34); ctx.fillStyle = (i + j) % 2 ? '#a5531a' : '#d9822b'; ctx.fill(); }
  rr(250, 230, 400, 560, 120); fs('#2b8a3e', 8); rr(190, 470, 90, 320, 40); fs('#2f9e44', 8); rr(620, 470, 90, 320, 40); fs('#2f9e44', 8);
  const mood = opaMood(t), sp = gLineAt2(t) === 'O';
  const fingerUp = t >= C('finger');
  person(450, 730, 1.18, {
    t, mood, mouth: mouthOf('O', t), skin: SKIN_OLD, shirt: '#8d6e63', collar: WHITE, pants: '#6c757d', hair: 'sides', hairCol: '#f1f3f5',
    browCol: '#f1f3f5', bushy: true, mustache: '#f1f3f5', glasses: true, noLegs: true, wiggle: t >= C('gelenkig') && t < C('gelenkig') + 1.2, wink: t >= C('wink') && t < C('wink') + 0.8,
    handL: [-150, -60], holdL: (hx, hy) => beer(hx + 6, hy + 10),
    handR: fingerUp ? [150, -360] : (sp ? [150, -150 + Math.sin(t * 8) * 30] : [140, -40]), finger: fingerUp,
  });
  // Einblendungen
  const ins = (cue, until, fn) => { if (t >= C(cue) - 0.05 && t < until) fn(pop(t, C(cue) - 0.05, 0.4)); };
  ins('kiste', T('u1'), p => toolbox(700, 600, p));
  ins('salat', E('o3') + 0.2, p => bowl(710, 610, p));
  ins('auto', E('o5') + 0.2, p => car(690, 620, p * 0.9, t));
  if (t >= C('money') - 0.05 && t < T('o7')) { money(450, 400, t, C('money')); at(450, 150, pop(t, C('money'), 0.4), 0, () => txt('300.000 €', 0, 0, 110, '#ffd43b', { stroke: 16 })); }
  ins('gerda', E('o8') + 0.3, p => polaroid(700, 400, p, t, t >= C('wink')));
  ins('dose', E('o9') + 0.4, p => proteinCan(700, 560, p, t, t >= C('oma') - 0.05));
  stamp('VERSUCHTER MORD', 450, 300, t, C('mord'), -0.12, { size: 70, fadeAt: E('o3') + 0.1 });
  stamp('KEIN TÜV', 690, 470, t, C('tuev'), 0.1, { size: 54, fadeAt: E('o5') + 0.1 });
  stamp('KEINE BREMSEN', 450, 250, t, C('bremsen'), -0.1, { size: 66, fadeAt: E('o5') + 0.1 });
  if (t >= C('gelenkig') && t < E('o8') + 0.4) at(250, 200, pop(t, C('gelenkig'), 0.3), -0.1, () => txt('*zwinker*', 0, 0, 50, WHITE, { stroke: 10 }));
  // VHS-Effekte
  ctx.fillStyle = 'rgba(0,0,0,0.12)'; for (let yy = 0; yy < 780; yy += 6) ctx.fillRect(0, yy, 900, 2);
  const band = ((t * 120) % 1100) - 160;
  ctx.fillStyle = 'rgba(255,255,255,0.08)'; ctx.fillRect(0, band, 900, 26);
  for (let i = 0; i < 20; i++) { ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(rnd(i + Math.floor(t * 30)) * 900, band + rnd(i) * 26, 30, 2); }
  if ((t * 1.5) % 1 < 0.7) txt('PLAY ▶', 60, 60, 44, '#b2f2bb', { align: 'left', weight: 800, stroke: 6, sc: '#000' });
  ctx.font = `700 34px ${MONO3}`; ctx.textAlign = 'right'; ctx.textBaseline = 'middle'; ctx.lineWidth = 6; ctx.strokeStyle = '#000';
  ctx.strokeText('SA 12.03.2022  21:47', 860, 730); ctx.fillStyle = WHITE; ctx.fillText('SA 12.03.2022  21:47', 860, 730);
  const vg = ctx.createRadialGradient(450, 390, 250, 450, 390, 620); vg.addColorStop(0, 'rgba(0,0,0,0)'); vg.addColorStop(1, 'rgba(0,0,0,0.55)');
  ctx.fillStyle = vg; ctx.fillRect(0, 0, 900, 780);
  ctx.restore();
}
function gLineAt2(t) { const l = TL.lines.find(l => t >= l.start - 0.04 && t <= l.end + 0.04); return l ? l.spk : null; }

/* ---------- Einstellungen ---------- */
function roomWall() {
  bg('#efe2c6', '#e3d2ad');
  ctx.save(); ctx.globalAlpha = 0.12; for (let x = 0; x < W; x += 54) { ctx.fillStyle = '#b08d57'; ctx.fillRect(x, 0, 8, 1000); } ctx.restore();
  ctx.fillStyle = '#7a4e2d'; ctx.fillRect(-80, 980, W + 160, 1000);
  for (let x = 0; x < W; x += 180) seg(x, 980, x, 1920, 5, '#5c3a20');
  seg(-80, 980, W + 80, 980, 10, '#5c3a20');
}
function shotNotar(t) {
  roomWall();
  for (let i = 0; i < 14; i++) { const c = ['#c92a2a', '#1864ab', '#2b8a3e', '#e67700', '#5f3dc4'][i % 5]; rr(120 + i * 60, 420 - (i % 3) * 16, 48, 220 + (i % 3) * 16, 4); fs(c, 4); }
  rr(100, 640, 880, 24, 4); fs('#5c3a20', 5);
  at(820, 500, 1, 0.04, () => { rr(-80, -100, 160, 200, 6); fs('#fff9db', 6, '#8d6e63'); txt('§', 0, -10, 90, '#8d6e63'); });
  person(540, 1500, 1.5, { t, mood: 'bored', mouth: mouthOf('N', t), skin: SKIN1, shirt: '#343a40', collar: WHITE, tie: '#1c3d5a', hair: 'sides', hairCol: '#868e96', glasses: true, noLegs: true,
    handR: t >= E('n1') - 0.4 && t < C('vhsOn') + 0.2 ? [150, -300] : [140, -40], holdR: (hx, hy) => { if (t >= E('n1') - 0.4 && t < C('vhsOn') + 0.2) { rr(hx - 14, hy - 70, 28, 80, 8); fs('#212529', 4); circ(hx, hy - 54, 6); fs(RED, 0); } } });
  ctx.fillStyle = '#6b4226'; ctx.fillRect(-80, 1330, W + 160, 600); seg(-80, 1330, W + 80, 1330, 8, '#4a2c17');
  if (t >= C('salat2') - 0.3) { /* Ende: Notar bleibt trocken */ }
}
function shotTV(t) {
  ctx.fillStyle = '#2b1d14'; ctx.fillRect(-80, -80, W + 160, H + 160);
  rr(30, 290, 1020, 990, 60); fs('#4a3b2c', 10, '#1a120c');
  rr(30, 290, 1020, 990, 60); ctx.strokeStyle = '#8d6e4d'; ctx.lineWidth = 4; ctx.stroke();
  tvContent(t, 70, 330, 940, 815);
  for (let i = 0; i < 3; i++) { circ(250 + i * 90, 1215, 22); fs('#212529', 5, '#8d6e4d'); }
  rr(700, 1196, 260, 40, 8); fs('#1a120c', 4, '#8d6e4d');
}
function shotWide(t) {
  roomWall();
  rr(260, 360, 560, 470, 40); fs('#4a3b2c', 8, '#1a120c');
  tvContent(t, 290, 390, 500, 410);
  limb(320, 830, 320, 1020, 12, '#343a40'); limb(760, 830, 760, 1020, 12, '#343a40');
  rr(330, 880, 420, 70, 8); fs('#212529', 5); circ(700, 915, 7); fs(RED, 0);
  rr(60, 1080, 960, 300, 60); fs('#5f3d24', 8);
  for (const [px, c] of [[300, CAST.U.hairCol], [540, CAST.S.hairCol], [790, CAST.K.hairCol]]) {
    ell(px, 1040, 100, 112); fs(c, 7);
    rr(px - 120, 1120, 240, 220, 70); fs('#495057', 7);
  }
}
function couchReaction(t) {
  const moods = { U: 'neutral', S: 'bored', K: 'bored' };
  if (t >= T('u1') - 0.1) moods.U = 'sad';
  if (t >= T('o3')) moods.S = 'angry';
  if (t >= T('s1') - 0.1) moods.S = 'sabShock';
  if (t >= E('s1') + 0.3) moods.S = 'furious';
  if (t >= T('k1') - 0.1) moods.K = 'excited';
  if (t >= TOK('o5', 7) - 0.1) moods.K = 'shocked';
  if (t >= E('o6')) { moods.U = 'shocked'; moods.K = 'shocked'; moods.S = 'shocked'; }
  if (t >= T('s2') - 0.1) moods.S = 'furious';
  if (t >= T('k2') - 0.1) moods.K = 'sick';
  if (t >= C('salat2')) { moods.U = 'shocked'; moods.K = 'sick'; moods.S = 'smug'; }
  return moods;
}
function shotCouch(t, focus, fStart) {
  const targets = { all: [540, 1000, 1], U: [280, 760, 2.0], S: [540, 760, 2.0], K: [800, 760, 2.0] };
  const [fx, fy, fz] = targets[focus];
  const p = eOut(prog(t, fStart, 0.18));
  const z = lerp(focus === 'all' ? 1.08 : 1.6, fz, p);
  roomWall();
  ctx.save();
  ctx.translate(540, 960); ctx.scale(z, z); ctx.translate(-fx, -fy);
  at(870, 560, 1, 0.05, () => { rr(-70, -90, 140, 180, 6); fs('#fff9db', 6, '#8d6e63'); txt('Erbe?', 0, 0, 40, '#8d6e63'); });
  rr(40, 860, 1000, 440, 90); fs('#6b8e23', 8, '#3b5114');
  rr(40, 1060, 1000, 140, 40); fs('#7aa12a', 6, '#3b5114');
  const moods = couchReaction(t);
  const lean = t >= E('o6') && t < T('o7') ? 0.06 : 0;
  person(280, 1110, 0.92, Object.assign({ t, mood: moods.U, mouth: mouthOf('U', t), rot: -lean }, CAST.U));
  person(540, 1110, 0.92, Object.assign({ t, mood: moods.S, mouth: mouthOf('S', t), rot: 0,
    handR: t >= C('salat2') ? [150, -200] : undefined, holdR: t >= C('salat2') ? (hx, hy) => bowl(hx + 10, hy - 30, 0.7) : undefined }, CAST.S));
  person(800, 1110, 0.92, Object.assign({ t, mood: moods.K, mouth: mouthOf('K', t), rot: lean,
    handR: moods.K === 'excited' ? [140, -380] : (moods.K === 'sick' ? [40, -300] : [130, -60]), holdL: (hx, hy) => phone(hx, hy) }, CAST.K));
  ctx.restore();
  if (moods.K === 'sick' && focus === 'K') at(760, 520, pop(t, T('k2'), 0.3), -0.1, () => txt('*würg*', 0, 0, 70, '#8ce99a', { stroke: 12 }));
  if (focus === 'all' && t >= E('o6') && t < T('o7')) at(540, 420, 1 + 0.05 * Math.sin(t * 30), 0, () => txt('…', 0, 0, 160, INK, { stroke: 0 }));
}

/* ---------- Schnittliste ---------- */
function shots() {
  return [
    [0, 'notar'], [C('vhsOn') - 0.3, 'wide'], [T('o1') - 0.05, 'tv'],
    [T('u1') - 0.05, 'couch:U'], [T('o3') - 0.05, 'tv'], [T('s1') - 0.05, 'couch:S'],
    [T('o4') - 0.05, 'tv'], [T('k1') - 0.05, 'couch:K'], [T('o5') - 0.05, 'tv'], [TOK('o5', 7) - 0.05, 'couch:K'],
    [T('o6') - 0.05, 'tv'], [E('o6') + 0.05, 'couch:all'], [T('o7') - 0.05, 'tv'], [T('s2') - 0.05, 'couch:S'],
    [T('o8') - 0.05, 'tv'], [T('k2') - 0.05, 'couch:K'], [T('o10') - 0.05, 'tv'],
    [C('vhsOff') + 0.7, 'notar'], [C('salat2') - 0.05, 'couch:all'],
  ];
}
function sceneRoom(t) {
  const list = shots();
  let cur = list[0];
  for (const s of list) if (t >= s[0]) cur = s;
  const [st, name] = cur;
  if (name === 'notar') shotNotar(t);
  else if (name === 'tv') shotTV(t);
  else if (name === 'wide') shotWide(t);
  else shotCouch(t, name.split(':')[1], st);
  if (t - st < 0.06 && st > 0.1) { ctx.fillStyle = 'rgba(255,255,255,0.35)'; ctx.fillRect(-80, -80, W + 160, H + 160); }
  // Titel (Hook) und Abspann
  alpha(1 - fade(t, C('vhsOn') - 0.4, 0.3), () => at(540, 300, 1, -0.03, () => {
    rr(-420, -90, 840, 180, 24); fs('#212529', 0);
    txt('OPAS TESTAMENT', 0, -12, 92, '#ffd43b', { maxW: 800 });
    txt('(Videobotschaft · ungeschnitten)', 0, 56, 30, WHITE, { weight: 700 });
  }));
  const end = E('n2') + 0.4;
  if (t >= end) alpha(fade(t, end, 0.3), () => {
    ctx.fillStyle = 'rgba(0,0,0,0.55)'; ctx.fillRect(-80, -80, W + 160, H + 160);
    at(540, 760, pop(t, end, 0.45), 0, () => { txt('OPAS', 0, -70, 150, '#ffd43b', { stroke: 18 }); txt('TESTAMENT', 0, 80, 150, '#ffd43b', { stroke: 18, maxW: 980 }); });
    at(540, 1010, pop(t, end + 0.3, 0.4), 0, () => txt('Folg mir. Oma hätte es gewollt.', 0, 0, 50, WHITE, { stroke: 10, weight: 800 }));
  });
}
window.EP_SCENES = { room: sceneRoom };
