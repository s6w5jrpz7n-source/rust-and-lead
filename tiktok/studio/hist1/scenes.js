'use strict';
/* GESCHICHTE · TEIL 1 – Charles Joughin, der betrunkene Bäcker der Titanic */
const WY = 1010;
const JO = { role: 'baker' };
function clipAbove(y, fn) { ctx.save(); ctx.beginPath(); ctx.rect(0, 0, W, y); ctx.clip(); fn(); ctx.restore(); }
function swimJ(x, y, s, t, o = {}) {
  const pa = Math.sin(t * 4) * 0.4;
  clipAbove(y + 18, () => person(x, y + 300 * s, s, Object.assign({}, JO, { pose: 'swim', aF: [2.5 + pa, 0.3], aB: [-2.5 + pa, -0.3] }, o)));
  ell(x, y + 10, 150 * s, 18 * s); ctx.strokeStyle = 'rgba(220,240,255,0.7)'; ctx.lineWidth = 5; ctx.stroke();
}
function deck(t) {
  nightSky(t); seaSurface(900, t);
  ctx.fillStyle = '#8a5a32'; ctx.fillRect(0, 1060, W, 600); for (let y = 1080; y < 1600; y += 40) seg(0, y, W, y, 3, '#6d4423');
  seg(0, 960, W, 960, 10, '#f1f3f5'); seg(0, 1010, W, 1010, 6, '#f1f3f5'); for (let x = 20; x < W; x += 80) seg(x, 960, x, 1062, 6, '#f1f3f5');
}
function hook(t, lt) {
  nightSky(t); seaSurface(WY, t);
  swimJ(540, WY, 1.0, t, { eye: t > C('betr') ? 'drunk' : 'open', blush: t > C('betr') });
  thermo(170, 760, '−2 °C', pop(t, 0.4, 0.4));
  clockH(900, 700, 2 * clamp((t - 0.4) / 3.5), pop(t, 0.6, 0.4), '2 Std.');
  if (t >= C('betr') - 0.05) { const b = Math.sin(t * 3) * 8; at(790, WY - 10 + b, pop(t, C('betr') - 0.05, 0.35), 0.5, () => heldItem('bottle', 0, 0)); if (!TL.cues.sagt || t < C('sagt') - 0.05) at(380, 640, pop(t, C('betr'), 0.3), -0.1, () => stxtH('hicks!', 0, 0, 56, PAPER, { stroke: 8 })); }
  stampH('ÜBERLEBT', 540, 520, prog(t, C('ueber') - 0.05, 0.3), '#69db7c', -0.08, 84);
  if (TL.cues.sagt && t >= C('sagt') - 0.05) tag('… sagt er zumindest.', 560, 650, pop(t, C('sagt') - 0.05, 0.35), { rot: 0.05, size: 36 });
}
function intro(t, lt) {
  nightSky(t); seaSurface(1000, t);
  liner(720, 1000, 0.55, { t });
  person(300, 1300, 1.2, Object.assign({}, JO, { aF: [0.3, 1.8], aB: [-0.2, 0.3], eye: 'open' }));
  tag('Charles Joughin', 690, 520, pop(t, T('j2') + 0.2, 0.4), { size: 50 });
  tag('Chefbäcker der Titanic', 690, 610, pop(t, T('j2') + 0.6, 0.4), { size: 34, bg: GOLDH });
  if (t >= C('datum') - 0.05) tag('14. April 1912', 690, 710, pop(t, C('datum') - 0.05, 0.4), { mono: true, size: 40, rot: -0.04 });
}
function eis(t, lt) {
  const [sx, sy] = shakeAt(t, [C('eis')]);
  ctx.save(); ctx.translate(sx, sy);
  nightSky(t);
  iceberg(880, 1000, 0.9);
  const x = lerp(250, 430, clamp((t - T('j3')) / Math.max(0.1, C('eis') - T('j3'))));
  liner(x, 1000, 0.62, { t });
  seaSurface(995, t);
  ctx.restore();
  if (t >= C('eis') - 0.05 && t < C('brot')) at(760, 620, pop(t, C('eis') - 0.05, 0.3), 0.1, () => stxtH('KRRRRZ!', 0, 0, 80, PAPER, { stroke: 12, weight: 900 }));
  if (t >= C('brot') - 0.05) {
    at(540, 760, pop(t, C('brot') - 0.05, 0.4), 0, () => {
      rr(-420, -270, 840, 540, 20); fs(PAPER, 8, OUT); rr(-400, -250, 800, 500, 12); ctx.fillStyle = '#d8c7a3'; ctx.fill();
      for (let i = 0; i < 3; i++) person(-250 + i * 250, 220, 0.62, { role: 'baker', pose: 'walk', ph: t * 1.4 + i * 0.3, aF: [1.3, 1.6], hold: 'bread', eye: 'open' });
      stxtH('4 Brote pro Mann – für die Boote', 0, -205, 36, OUT, { maxW: 760 });
    });
  }
}
function boot(t, lt) {
  deck(t);
  const lo = eOut(prog(t, T('j4') + 0.6, 2.0));
  // Davit + Boot
  for (const dx of [640, 980]) { P(); ctx.moveTo(dx, 1000); ctx.quadraticCurveTo(dx, 700, dx + 80, 720); ctx.lineWidth = 16; ctx.strokeStyle = '#dee2e6'; ctx.stroke(); seg(dx + 80, 720, dx + 80, 820 + lo * 120, 3, '#ced4da'); }
  lifeboat(800, 860 + lo * 120, 1.0, { people: t > C('platz') ? 6 : 4, num: 10 });
  person(560, 1300, 0.95, { role: 'woman', dir: 1, aF: [1.6, 0.2], eye: 'open', hair: '#3b2a1a' });
  person(330, 1320, 1.0, Object.assign({}, JO, { aF: t < C('platz') ? [1.6, -0.1] : [2.6, 0.4], eye: 'open' }));
  if (t >= C('platz') - 0.05) tag('steigt selbst nicht ein', 360, 640, pop(t, C('platz') - 0.05, 0.4), { size: 40, bg: GOLDH, rot: -0.04 });
}
function kabine(t, lt) {
  ctx.fillStyle = '#5c3b22'; ctx.fillRect(0, 0, W, H); for (let x = 0; x < W; x += 120) seg(x, 380, x, 1300, 4, '#4a2f1b');
  circ(800, 700, 120); fs('#0f2238', 14, '#b08d57'); for (let i = 0; i < 12; i++) { circ(760 + rnd(i) * 90, 640 + rnd(i + 3) * 110, 2); ctx.fillStyle = '#fff'; ctx.fill(); }
  rr(80, 1050, 520, 120, 10); fs('#7a5232', 6, OUT); rr(100, 1000, 470, 60, 20); fs('#e9ecef', 5, OUT);
  ctx.fillStyle = '#3d2716'; ctx.fillRect(0, 1180, W, 500);
  const drink = prog(t, C('kabine') + 0.4, 0.5) * (1 - prog(t, C('kabine') + 1.6, 0.4));
  const tipsy = t > C('kabine') + 1.2;
  ctx.save(); ctx.translate(540, 1290); ctx.rotate(tipsy ? Math.sin(t * 2.2) * 0.05 : 0);
  person(0, 0, 1.15, Object.assign({}, JO, { aF: [lerp(1.0, 2.5, drink), lerp(1.4, 1.9, drink)], hold: 'glass', eye: tipsy ? 'drunk' : 'open', blush: tipsy }));
  ctx.restore();
  tag('ein großes Glas Likör', 300, 560, pop(t, C('kabine') + 0.6, 0.4), { size: 40, rot: -0.05 });
  if (tipsy) at(700, 880, pop(t, C('kabine') + 1.3, 0.3), 0.1, () => stxtH('hicks!', 0, 0, 60, PAPER, { stroke: 9 }));
}
function stuehle(t, lt) {
  deck(t);
  const t0 = C('stuehle') - 0.1, n = Math.floor(clamp((t - t0) / 3.2) * 50);
  for (let i = 0; i < 10; i++) {
    const st = t0 + i * 0.32, u = (t - st) / 1.1;
    if (u > 0 && u < 1) deckChair(lerp(420, 900 + rnd(i) * 120, u), lerp(1080, 1040, u) - Math.sin(u * Math.PI) * 360 + u * u * 200, 1.0, u * 7);
  }
  person(340, 1320, 1.0, Object.assign({}, JO, { aF: [2.4 + Math.sin(t * 9) * 0.5, 0.3], eye: 'open' }));
  tag(`Liegestühle über Bord: ${n}`, 540, 560, pop(t, t0 + 0.2, 0.4), { mono: true, size: 38 });
  tag('als Schwimmhilfen', 540, 650, pop(t, t0 + 1.2, 0.4), { size: 32, bg: GOLDH });
}
function heck(t, lt) {
  nightSky(t);
  const lift = TL.cues.lift ? prog(t, C('lift'), 3.2) : 0;
  const tilt = lerp(0.55, 1.15, eIO(clamp((t - T('j7')) / 1.6))) ;
  const sy = 980 + eIn(lift) * 520;
  liner(660, sy, 0.7, { t, tilt, smoke: false, lights: lift > 0.5 ? 'off' : true });
  // Heckspitze in Weltkoordinaten
  const c = Math.cos(tilt), s = Math.sin(tilt), lx = -490 * 0.7, ly = -112 * 0.7;
  const hx = 660 + lx * c - ly * s, hy = sy + lx * s + ly * c;
  person(hx + 10, hy, 0.22, Object.assign({}, JO, { aF: [2.4, 0.3], eye: 'open' }));
  seaSurface(980, t);
  at(hx + 120, hy - 70, pop(t, T('j7') + 0.8, 0.3), 0, () => { seg(0, 0, -80, 50, 6, GOLDH); arrowHead(-80, 50, Math.PI * 0.82, 16, GOLDH); stxtH('Joughin', 40, -20, 34, GOLDH, { stroke: 6 }); });
  if (TL.cues.lift && t >= C('lift') - 0.05) {
    at(870, 820, pop(t, C('lift') - 0.05, 0.4), 0, () => { seg(0, -120, 0, 120, 14, PAPER); arrowHead(0, 130, Math.PI / 2, 30, PAPER); });
    tag('wie in einem Aufzug', 760, 560, pop(t, C('lift'), 0.4), { size: 40, bg: GOLDH });
  }
}
function kopf(t, lt) {
  nightSky(t); seaSurface(1080, t);
  swimJ(540, 1080, 1.5, t, { eye: 'open' });
  tag('Kopf nicht mal untergegangen', 540, 560, pop(t, C('kopf') - 0.05, 0.4), { size: 42 });
  tag('(sagte er)', 540, 650, pop(t, C('kopf') + 0.8, 0.4), { size: 32, bg: GOLDH });
}
function kalt(t, lt) {
  nightSky(t); seaSurface(1040, t, { c1: '#1d4e6e' });
  for (let i = 0; i < 30; i++) { const x = rnd(i) * W, y = 380 + ((rnd(i + 3) * 700 + t * 60) % 700); circ(x, y, 3); ctx.fillStyle = 'rgba(255,255,255,0.7)'; ctx.fill(); }
  swimJ(560, 1040, 0.9, t, { eye: 'open' });
  thermo(170, 820, '−2 °C', pop(t, C('grad') - 0.05, 0.4));
  const hrs = TL.cues.zwei ? 2 * eIO(clamp((t - C('paddel')) / Math.max(0.5, C('zwei') - C('paddel') + 0.6))) : 0;
  if (t >= C('paddel') - 0.05) clockH(890, 720, hrs, pop(t, C('paddel') - 0.05, 0.4), `${(hrs).toFixed(1).replace('.', ',')} Std.`);
  if (TL.cues.zwei && t >= C('zwei') - 0.05) tag('nach eigener Aussage', 760, 520, pop(t, C('zwei') - 0.05, 0.4), { size: 34, bg: GOLDH });
}
function morgen(t, lt) {
  dawnSky(); seaSurface(1050, t, { c1: '#3d5a80', c2: '#1b2a41' });
  // umgekipptes Faltboot mit Männern
  at(470, 1040, 1, 0, () => { P(); ctx.moveTo(-230, 0); ctx.quadraticCurveTo(0, -70, 230, 0); ctx.closePath(); fs('#e9ecef', 6, OUT); for (let i = 0; i < 6; i++) person(-170 + i * 68, -36, 0.2, { role: i % 2 ? 'man' : 'officer', eye: 'open' }); });
  swimJ(740, 1050, 0.7, t, { eye: 'open', aF: [2.0, 0.6] });
  const r = prog(t, C('morgen') + 1.2, 2.0);
  if (r > 0) lifeboat(lerp(1300, 900, eOut(r)), 1040, 0.8, { people: 5 });
  if (t > C('morgen') + 2.8) stampH('GERETTET', 540, 600, prog(t, C('morgen') + 2.8, 0.3), '#69db7c', -0.06, 76);
}
function alk(t, lt) {
  sky('#0a1220', '#1d2b3a');
  at(540, 1000, 3.0 * pop(t, T('j11'), 0.4), Math.sin(t * 2) * 0.08, () => heldItem('bottle', 0, 0));
  tag('Alkohol = Rettung?', 540, 560, pop(t, C('alk') - 0.05, 0.4), { size: 50 });
  stampH('HISTORIKER ZWEIFELN', 540, 760, prog(t, C('mythos') - 0.05, 0.3), '#ff6b6b', -0.1, 58);
  if (t >= C('mythos') + 0.8 && t < C('raetsel')) tag('Alkohol → schneller unterkühlt', 540, 1180, pop(t, C('mythos') + 0.8, 0.4), { size: 34, bg: GOLDH });
  if (t >= C('raetsel') - 0.05) at(800, 960, pop(t, C('raetsel') - 0.05, 0.4), 0, () => stxtH('?', 0, 0, 260, GOLDH, { stroke: 14, weight: 900 }));
}
function teaser(t, lt) {
  nightSky(t); seaSurface(900, t);
  const ships = [['Olympic', {}], ['Titanic', {}], ['Britannic', { hull: 'white', crosses: true }]];
  ships.forEach(([n, o], i) => { const x = 200 + i * 340; liner(x, 800, 0.28, Object.assign({ t, smoke: false }, o)); tag(n, x, 855, 1, { size: 26 });
    if (TL.cues.drei && t >= C('drei') + i * 0.25) at(x, 660, pop(t, C('drei') + i * 0.25, 0.3), 0, () => stxtH('!', 0, 0, 90, '#ff6b6b', { stroke: 10, weight: 900 })); });
  person(540, 1370, 0.92, { role: 'stew', eye: 'open', aF: [0.3, 0.6], hair: '#7a3b1e' });
  if (TL.cues.teil2 && t >= C('teil2') - 0.05) { const p = pop(t, C('teil2') - 0.05, 0.45); at(540, 490, p, 0, () => { pill('TEIL 2 ▶', 0, 0, 56, GOLDH, OUT, { lw: 0 }); }); at(540, 575, p, 0, () => stxtH('„die Unsinkbare“', 0, 0, 56, PAPER, { stroke: 9, italic: true })); }
  else tag('eine junge Stewardess …', 540, 520, pop(t, T('j12') + 1.0, 0.4), { size: 40 });
}
const SCN = [['j1', hook], ['j2', intro], ['j3', eis], ['j4', boot], ['j5', kabine], ['j6', stuehle], ['j7', heck], ['j8', kopf], ['j9', kalt], ['j10', morgen], ['j11', alk], ['j12', teaser]];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  sceneAtH(t, SCN);
  grain(t);
  headerH('GESCHICHTE · TEIL 1', 'Der betrunkene Bäcker der Titanic');
  drawCaptions(t);
};
window.EP_SCENES = {};
