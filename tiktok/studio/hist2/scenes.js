'use strict';
/* GESCHICHTE · TEIL 2 – Violet Jessop, „die Unsinkbare“ */
const VI = { role: 'stew', hair: '#7a3b1e' };
const VN = { role: 'nurse', hair: '#7a3b1e' };
function clipAbove(y, fn) { ctx.save(); ctx.beginPath(); ctx.rect(0, 0, W, y); ctx.clip(); fn(); ctx.restore(); }
function hdr(t, s, col = GOLDH) { tag(s, 540, 470, pop(t, 0, 0.01), { mono: true, size: 34, bg: col }); }
function boom(x, y, p, t) {
  if (p <= 0 || p >= 1) return;
  for (let i = 0; i < 14; i++) { const a = rnd(i) * Math.PI * 2, r = 40 + p * (160 + rnd(i + 2) * 120); circ(x + Math.cos(a) * r, y + Math.sin(a) * r * 0.7, (1 - p) * (40 + rnd(i) * 30)); ctx.fillStyle = i % 3 ? '#ffa94d' : '#ffe066'; ctx.fill(); }
  circ(x, y, 120 * (1 - p) + 20); ctx.fillStyle = `rgba(255,255,200,${1 - p})`; ctx.fill();
}
function hook(t, lt) {
  nightSky(t);
  liner(760, 1010 + lt * 10, 0.6, { t, tilt: 0.38, smoke: false });
  seaSurface(1000, t);
  person(300, 1330, 1.15, Object.assign({}, VI, { aF: [0.4, 0.5], eye: 'open' }));
  tag('überlebte die Titanic', 640, 560, pop(t, T('v1') + 0.4, 0.4), { size: 40 });
  stampH('UNGLÜCK Nr. 2', 640, 700, prog(t, C('zwei') - 0.05, 0.3), '#ff6b6b', -0.08, 66);
}
function name(t, lt) {
  sky('#1b1410', '#3a2a1c');
  at(540, 860, pop(t, T('v2'), 0.45), -0.03, () => {
    rr(-340, -400, 680, 800, 16); fs(PAPER, 10, OUT); rr(-300, -360, 600, 560, 8); ctx.fillStyle = '#cdbb98'; ctx.fill();
    ctx.save(); rr(-300, -360, 600, 560, 8); ctx.clip(); person(0, 560, 1.35, Object.assign({}, VI, { aF: [0.3, 0.4], eye: 'open' })); ctx.restore();
    stxtH('Violet Jessop', 0, 268, 58, OUT); stxtH('Stewardess · 1887 – 1971', 0, 336, 32, SEPIA);
  });
  stampH('MISS UNSINKABLE', 600, 1130, prog(t, C('spitz') - 0.05, 0.3), '#c92a2a', -0.1, 60);
}
function u1(t, lt) {
  const [sx, sy] = shakeAt(t, [C('crash')]);
  ctx.save(); ctx.translate(sx, sy);
  daySky();
  const hit = C('crash'), wx = lerp(-260, 120, clamp((t - T('v3')) / Math.max(0.1, hit - T('v3'))));
  liner(640, 1000, 0.62, { t, lights: false, name: 'OLYMPIC' });
  warship(wx, 1010, 0.6);
  seaSurface(1000, t, { c1: '#2b7bb9', c2: '#164a72' });
  if (t > hit) { circ(330, 990, 22); ctx.fillStyle = '#111'; ctx.fill(); }
  ctx.restore();
  hdr(t, 'UNGLÜCK 1 · 1911 · OLYMPIC');
  if (t >= hit - 0.05 && t < C('alle')) at(400, 760, pop(t, hit - 0.05, 0.3), -0.1, () => stxtH('KRACH!', 0, 0, 90, PAPER, { stroke: 12, weight: 900 }));
  if (t >= C('alle') - 0.05) tag('alle überleben ✓', 540, 600, pop(t, C('alle') - 0.05, 0.4), { size: 46, bg: '#b2f2bb' });
}
function u2(t, lt) {
  nightSky(t);
  liner(800, 990 + lt * 8, 0.55, { t, tilt: 0.3, smoke: false });
  seaSurface(990, t);
  const by = 1090 + Math.sin(t * 1.5) * 8;
  clipAbove(by - 10, () => person(470, by + 210, 0.8, Object.assign({}, VI, { aF: t > C('baby') ? [1.2, 1.6] : [0.3, 0.4], hold: t > C('baby') ? 'baby' : null, eye: 'open' })));
  lifeboat(480, by, 1.15, { people: 0, num: 16 });
  hdr(t, 'UNGLÜCK 2 · 1912 · TITANIC');
  if (t >= C('baby') - 0.05) tag('ein fremdes Baby', 760, 620, pop(t, C('baby') - 0.05, 0.4), { size: 40, rot: 0.05 });
}
function morgen(t, lt) {
  dawnSky(); seaSurface(1010, t, { c1: '#3d5a80', c2: '#1b2a41' });
  smallShip(560, 1000, 0.75, { name: 'CARPATHIA' });
  ctx.fillStyle = '#8a5a32'; ctx.fillRect(0, 1130, W, 600); seg(0, 1130, W, 1130, 8, '#f1f3f5');
  const g = C('weg'), u = prog(t, g, 0.5), run = prog(t, g + 0.6, 1.2);
  person(330, 1360, 1.0, Object.assign({}, VI, { aF: t < g + 0.25 ? [1.2, 1.6] : [1.0, 0.2], hold: t < g + 0.25 ? 'baby' : null, eye: t > g ? 'wide' : 'open' }));
  if (t >= g - 0.4) person(lerp(1200, 560, eOut(prog(t, g - 0.4, 0.5))) + run * 800, 1360, 1.0, { role: 'woman', dir: -1, pose: run > 0 ? 'walk' : 'stand', ph: t * 2, aF: t > g + 0.25 ? [1.2, 1.6] : [1.6, 0], hold: t > g + 0.25 ? 'baby' : null, eye: 'open', hair: '#222' });
  if (t >= C('wort') - 0.05) tag('… ohne ein Wort.', 540, 560, pop(t, C('wort') - 0.05, 0.4), { size: 46 });
  else tag('am nächsten Morgen', 540, 560, pop(t, T('v5') + 0.2, 0.4), { mono: true, size: 34 });
}
function britannic(t, lt, o = {}) {
  const ex = TL.cues.boom ? C('boom') : 1e9;
  const sink = clamp((t - ex - 0.5) / 6);
  const [sx, sy] = shakeAt(t, [ex], 30);
  ctx.save(); ctx.translate(sx, sy);
  daySky();
  liner(560, 1000 + sink * 30, 0.62, { t, hull: 'white', crosses: true, tilt: sink * 0.12, lights: false, name: 'BRITANNIC' });
  if (t > ex) for (let i = 0; i < 8; i++) { const u = ((t - ex) * 0.4 + i / 8) % 1; circ(820 - u * 60, 960 - u * 380, 30 + u * 70); ctx.fillStyle = `rgba(60,60,60,${0.5 * (1 - u)})`; ctx.fill(); }
  boom(840, 980, prog(t, ex, 0.9), t);
  seaSurface(1000, t, { c1: '#1c7ed6', c2: '#0b4a85' });
  ctx.restore();
}
function u3(t, lt) {
  britannic(t, lt);
  hdr(t, 'UNGLÜCK 3 · 1916 · BRITANNIC');
  person(220, 1340, 0.85, Object.assign({}, VN, { aF: [0.3, 0.4], eye: 'open' }));
  if (t >= C('laz') - 0.05) tag('Lazarettschiff', 640, 600, pop(t, C('laz') - 0.05, 0.4), { size: 44 });
}
function datum(t, lt) {
  britannic(t, lt);
  hdr(t, 'UNGLÜCK 3 · 1916 · BRITANNIC');
  tag('21. November 1916', 540, 580, pop(t, C('datum') - 0.05, 0.4), { mono: true, size: 44 });
  if (t >= C('boom') + 0.4 && t < C('min')) tag('vermutlich eine Seemine', 540, 680, pop(t, C('boom') + 0.4, 0.4), { size: 36, bg: GOLDH });
  if (t >= C('min') - 0.05) { clockH(870, 760, 55 / 60 * eIO(prog(t, C('min'), 1.8)), pop(t, C('min') - 0.05, 0.4)); tag('sinkt in 55 Minuten', 540, 680, pop(t, C('min') - 0.05, 0.4), { size: 40, bg: '#ffc9c9' }); }
}
function zahn(t, lt) {
  sky('#e9ecef', '#ced4da', 1300);
  for (let x = 0; x < W; x += 140) seg(x, 380, x, 1300, 3, '#dee2e6');
  circ(820, 660, 110); fs('#74c0fc', 14, '#868e96');
  rr(60, 1060, 480, 100, 10); fs('#f8f9fa', 6, OUT);
  ctx.fillStyle = '#adb5bd'; ctx.fillRect(0, 1180, W, 500);
  const grab = prog(t, T('v8') + 1.0, 0.4);
  person(560, 1320, 1.1, Object.assign({}, VN, { pose: grab < 1 ? 'walk' : 'stand', ph: t * 2, aF: [lerp(0.3, 2.3, grab), 0.4], hold: grab > 0.6 ? 'toothbrush' : null, eye: 'open' }));
  if (grab > 0.6) at(300, 760, pop(t, T('v8') + 1.3, 0.4), -0.1, () => emo('🪥', 0, 0, 150));
  if (t >= C('vermisst') - 0.05) tag('nach der Titanic am meisten vermisst', 540, 560, pop(t, C('vermisst') - 0.05, 0.4), { size: 36 });
}
function sog(t, lt) {
  const sp = C('spring'), sg = C('sog'), kp = C('kopf');
  const under = t >= sg - 0.1;
  daySky();
  // Wasser mit Querschnitt
  const wy = 880;
  ctx.fillStyle = '#1864ab'; ctx.fillRect(0, wy, W, H);
  // Heck + Schrauben
  P(); ctx.moveTo(-40, 560); ctx.lineTo(380, 560); ctx.quadraticCurveTo(430, 760, 360, 1060); ctx.lineTo(-40, 1060); ctx.closePath(); fs('#f4f4f0', 6, OUT);
  ctx.fillStyle = '#2b8a3e'; ctx.fillRect(-40, wy, 410, 180);
  for (const [px, py] of [[400, 980], [330, 1120]]) at(px, py, 1, t * 9, () => { for (let k = 0; k < 3; k++) { ctx.rotate(Math.PI * 2 / 3); ell(0, -50, 22, 52); fs('#c9a227', 4, OUT); } circ(0, 0, 14); fs('#868e96', 4, OUT); });
  seaSurface(wy, t, { c1: '#1c7ed6', c2: '#1864ab' });
  // Boot wird angesogen
  const bx = lerp(900, 560, eIn(prog(t, T('v9'), Math.max(0.5, sp - T('v9') + 0.6))));
  lifeboat(bx, wy - 6, 0.9, { people: 3, rot: Math.sin(t * 6) * 0.06 });
  if (!under) { if (t >= sp - 0.05) { const u = prog(t, sp, 0.6); person(lerp(bx, bx + 180, u), wy - 200 + u * u * 400 - Math.sin(u * Math.PI) * 160, 0.45, Object.assign({}, VN, { aF: [2.8, 0.2], aB: [-2.8, -0.2], eye: 'wide' })); } }
  else {
    const d = eOut(prog(t, sg, 1.2));
    for (let i = 0; i < 10; i++) { const u = ((t - sg) * 0.9 + i / 10) % 1; circ(680 + rnd(i) * 120 - 40, lerp(1200, wy, u), 6 + rnd(i) * 8); ctx.strokeStyle = 'rgba(255,255,255,0.7)'; ctx.lineWidth = 3; ctx.stroke(); }
    at(lerp(720, 520, d), lerp(1000, 1180, d), 1, 1.6 + d * 0.8, () => person(0, 0, 0.5, Object.assign({}, VN, { aF: [2.6, 0.3], aB: [-2.6, -0.3], eye: t > kp ? 'closed' : 'wide' })));
    if (t >= kp - 0.05) { at(470, 1090, pop(t, kp - 0.05, 0.3), 0, () => stxtH('BONK!', 0, 0, 80, GOLDH, { stroke: 10, weight: 900 })); for (let i = 0; i < 5; i++) { const a = t * 4 + i * 1.25; emo('⭐', 520 + Math.cos(a) * 70, 1180 + Math.sin(a) * 30, 34); } }
  }
  if (t < sp) tag('in die Schiffsschrauben gezogen', 600, 560, pop(t, T('v9') + 0.3, 0.4), { size: 36, bg: '#ffc9c9' });
}
function ueberlebt(t, lt) {
  daySky(); seaSurface(1080, t, { c1: '#1c7ed6', c2: '#1864ab' });
  clipAbove(1098, () => person(540, 1080 + 380, 1.3, Object.assign({}, VN, { role: 'woman', pose: 'swim', hairLong: true, hair: '#7a3b1e', aF: [2.2, 0.5], eye: 'open' })));
  stampH('ÜBERLEBT', 540, 560, prog(t, C('ueberlebt') - 0.05, 0.3), '#2f9e44', -0.08, 84);
  if (t >= C('haare') - 0.05) tag('dicke Haare als Polster', 540, 700, pop(t, C('haare') - 0.05, 0.4), { size: 42, bg: GOLDH });
}
function danach(t, lt) {
  dawnSky(); seaSurface(1080, t, { c1: '#3d5a80', c2: '#1b2a41' });
  const u = prog(t, T('v11') + 0.3, 2.6);
  seg(120, 820, 960, 820, 10, PAPER);
  for (const [yr, x] of [[1916, 120], [1950, 960]]) { circ(x, 820, 16); fs(GOLDH, 5, OUT); stxtH(String(yr), x, 880, 38, PAPER, { stroke: 7 }); }
  liner(lerp(120, 960, u), 790, 0.12, { t, smoke: false, lights: false });
  tag('über 40 Jahre auf See', 540, 600, pop(t, T('v11') + 0.8, 0.4), { size: 44 });
  if (t >= C('tod') - 0.05) tag('† 1971 · mit 83 Jahren', 540, 1000, pop(t, C('tod') - 0.05, 0.4), { size: 40, bg: '#dee2e6' });
  if (t >= C('land') - 0.05) at(820, 1060, pop(t, C('land') - 0.05, 0.4), 0, () => { emo('🏡', 0, 0, 110); stxtH('an Land', 0, 90, 40, PAPER, { stroke: 7 }); });
}
function cta(t, lt) {
  nightSky(t); seaSurface(1000, t);
  [['Olympic', {}], ['Titanic', {}], ['Britannic', { hull: 'white', crosses: true }]].forEach(([n, o], i) => { const x = 200 + i * 340; liner(x, 900, 0.26, Object.assign({ t, smoke: false }, o)); tag(n + ' ✓', x, 955, 1, { size: 26, bg: '#b2f2bb' }); });
  person(540, 1330, 1.0, Object.assign({}, VI, { aF: [0.3, 0.5], eye: 'open' }));
  at(540, 560, pop(t, C('cta') - 0.05, 0.4), 0, () => { stxtH('Wärst du wieder', 0, 0, 62, PAPER, { stroke: 10 }); stxtH('an Bord gegangen? 👇', 0, 76, 62, PAPER, { stroke: 10 }); });
}
const SCN = [['v1', hook], ['v2', name], ['v3', u1], ['v4', u2], ['v5', morgen], ['v6', u3], ['v7', datum], ['v8', zahn], ['v9', sog], ['v10', ueberlebt], ['v11', danach], ['v12', cta]];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  sceneAtH(t, SCN);
  grain(t);
  headerH('GESCHICHTE · TEIL 2', 'Die Frau, die nicht sinken wollte');
  drawCaptions(t);
};
window.EP_SCENES = {};
