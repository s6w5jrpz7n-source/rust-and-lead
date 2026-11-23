'use strict';
/* PARODIE – „Wie Infinity War hätte enden sollen“ (eigene Cartoon-Figuren) */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { M: '#8ce99a', I: '#ffa94d', S: '#ff8787', Q: '#ffd43b', D: '#74c0fc', T: '#b197fc', R: '#ffe066' };
const THA = { shirt: '#3b4a6b', pants: '#2b3550', pads: '#e8b923', skin: '#9775c4', chin: true, browCol: '#5a3d7a', lips: '#4b2a6b' };
const MAN = { shirt: '#2f9e44', pants: '#2b8a3e', hair: 'bob', hairCol: '#111', browCol: '#111', antennae: true, bugEyes: true, skin: '#f3e6cc' };
const TON = { stand: true, shirt: '#b5121b', pants: '#b5121b', shoes: '#f6c445', reactor: true, hair: 'slick', hairCol: '#2b1d14', goatee: '#2b1d14', mustache: '#2b1d14', browCol: '#2b1d14' };
const SPI = { stand: true, shirt: '#d62828', pants: '#1c4fa1', shoes: '#d62828', spidersuit: true, mask: 'spider' };
const QUI = { stand: true, shirt: '#8b2e16', collar: '#5a1d0d', pants: '#495057', hair: 'slick', hairCol: '#a0703c', browCol: '#7a5230' };
const STR = { stand: true, shirt: '#1c3d7a', pants: '#1c3d7a', cape: '#c92a2a', hair: 'slick', hairCol: '#2b2b2b', goatee: '#3a3a3a', mustache: '#3a3a3a', browCol: '#2b2b2b' };
const THO = { stand: true, shirt: '#495057', pants: '#343a40', cape: '#c92a2a', hair: 'long', hairCol: '#e0b84f', beard: '#d4a73a', browCol: '#b8902a' };
const GY = 1300;
function titan(t) {
  bg('#ff9f43', '#7a2a12');
  circ(820, 520, 150); fs('#f4c27a', 6, '#9c5a2a'); ell(820, 520, 260, 40, -0.25); ctx.lineWidth = 10; ctx.strokeStyle = 'rgba(255,230,180,0.7)'; ctx.stroke();
  for (let i = 0; i < 9; i++) { const x = (i * 137 + t * 8) % 1200 - 60, y = 420 + (i % 4) * 90 + Math.sin(t + i) * 8; at(x, y, 0.6 + rnd(i) * 0.6, rnd(i) * 3, () => { P(); ctx.moveTo(-40, -10); ctx.lineTo(-10, -34); ctx.lineTo(36, -16); ctx.lineTo(30, 20); ctx.lineTo(-30, 24); ctx.closePath(); fs('#8c4a24', 5, '#4a2410'); }); }
  P(); ctx.moveTo(-80, GY - 60); for (let x = -80; x <= W + 80; x += 90) ctx.lineTo(x, GY - 60 - (rnd(x) * 50)); ctx.lineTo(W + 80, H); ctx.lineTo(-80, H); ctx.closePath(); fs('#a0522d', 7, '#4a2410');
  for (let i = 0; i < 7; i++) { ell(80 + i * 160, GY + 120 + (i % 2) * 60, 50, 16); ctx.fillStyle = 'rgba(74,36,16,0.5)'; ctx.fill(); }
}
function axe(hx, hy) {
  seg(hx, hy + 60, hx, hy - 230, 14, '#6b4423');
  at(hx, hy - 220, 1, 0, () => { P(); ctx.moveTo(0, -20); ctx.quadraticCurveTo(110, -60, 120, 30); ctx.quadraticCurveTo(60, 10, 0, 30); ctx.closePath(); fs('#ced4da', 6); rr(-50, -30, 50, 60, 8); fs('#adb5bd', 6); });
}
/* Thanos sitzend; o.ko = liegt; o.bare = ohne Handschuh; o.mantis = Mantis auf dem Kopf */
function thanos(t, x, y, s, o = {}) {
  if (o.ko) {
    figur(x, y, s, Object.assign({ t, rot: -Math.PI / 2, mood: 'dead', mouth: 0, noLegs: true }, THA));
    for (let i = 0; i < 5; i++) { const a = t * 4 + i * 1.25; emo('⭐', x - 380 * s + Math.cos(a) * 90 * s, y - 20 + Math.sin(a) * 30, 46); }
    return;
  }
  if (o.mantis) figur(x, y - 360 * s, s * 0.42, Object.assign({ t, mood: 'calm', mouth: mouthOf('M', t), handL: [-90, -60], handR: [90, -60] }, MAN));
  figur(x, y, s, Object.assign({ t, mood: o.mood || 'calm', mouth: mouthOf('T', t), lookX: o.lookX || 0, rot: o.rot || 0,
    handR: o.handR || [300, -60], gauntlet: !o.bare }, THA));
  if (o.mantis) for (const sd of [-1, 1]) { circ(x + sd * 50 * s, y - 455 * s, 11); fs('#f3e6cc', 5); }
}
function wide(t, o = {}) {
  titan(t);
  const bob = Math.sin(t * 2) * 12;
  figur(150, 1060 + bob, 0.6, Object.assign({ t, mood: o.strMood || 'neutral', mouth: mouthOf('D', t), lookX: 1, handR: o.magic ? [210, -200] : [130, -40] }, STR));
  if (o.magic) { ctx.save(); ctx.translate(390, 964); ctx.rotate(t * 2); for (let k = 0; k < 2; k++) { circ(0, 0, 70 - k * 22); ctx.lineWidth = 6; ctx.strokeStyle = '#ff922b'; ctx.stroke(); } for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; seg(Math.cos(a) * 48, Math.sin(a) * 48, Math.cos(a) * 70, Math.sin(a) * 70, 5, '#ffd43b'); } ctx.restore(); }
  const fist = o.fist ? [150, -420] : [130, -40];
  figur(270, GY, 0.8, Object.assign({ t, mood: o.quiMood || 'neutral', mouth: mouthOf('Q', t), lookX: 1, handR: fist }, QUI));
  if (o.ko) thanos(t, 640, GY - 40, 0.9, { ko: true });
  else thanos(t, 580, 1190, 1.0, { mantis: !o.noMantis, bare: o.bare, mood: o.thaMood, handR: o.thaHand });
  const pull = o.pull ? Math.sin(t * 12) * 8 : 0;
  if (o.gauntletUp) {
    figur(860, GY, 0.72, Object.assign({ t, mood: 'excited', mouth: mouthOf('S', t), handR: [100, -470], holdR: (hx, hy) => { circ(hx, hy - 30, 40); fs('#e8b923', 7, '#7a5c00'); } }, SPI));
  } else figur(860 + pull, GY, 0.72, Object.assign({ t, mood: 'neutral', mouth: mouthOf('S', t), handL: [-20 - pull, -236], handR: [40, -220] }, SPI));
  figur(1015, GY, 0.75, Object.assign({ t, mood: o.tonMood || 'angry', mouth: mouthOf('I', t), lookX: -1, handL: o.gauntletUp ? [-130, -40] : [-180, -227] }, TON));
  if (o.thor) {
    const land = eOut(prog(t, T('a17') - 0.3, 0.35));
    figur(560, lerp(400, GY + 20, land), 0.85, Object.assign({ t, mood: o.thorMood || 'angry', mouth: mouthOf('R', t), handR: [140, -330], holdR: (hx, hy) => axe(hx, hy) }, THO));
  }
}
function freezeFX(t, tf, text) {
  ctx.save(); ctx.filter = 'grayscale(1) contrast(1.2)'; quiCU(tf, { fist: true, quiMood: 'furious' }); ctx.restore();
  ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.fillRect(0, 0, W, H);
  at(540, 520, pop(t, C('freeze'), 0.35), -0.05, () => { rr(-440, -90, 880, 180, 24); fs('#e03131', 0); txt('Genau hier ging', 0, -34, 62, WHITE, { weight: 900 }); txt('alles schief.', 0, 40, 62, WHITE, { weight: 900 }); });
}
function quiCU(t, o = {}) { cam(270, 980, 2.0, () => wide(t, Object.assign({}, o))); }
function rewindFX(t) {
  const tr = C('freeze') - (t - C('rewind')) * 4;
  wide(Math.max(T('a4'), tr), { fist: tr > T('a6') });
  for (let i = 0; i < 6; i++) { const y = (t * 900 + i * 320) % H; ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(0, y, W, 14); }
  at(540, 480, 1, 0, () => txt('⏪ ZURÜCKSPULEN', 0, 0, 70, WHITE, { stroke: 12 }));
}
function twoShot(t) {
  titan(t);
  thanos(t, 760, GY + 120, 0.5, { ko: true });
  figur(320, GY + 60, 0.95, Object.assign({ t, mood: 'neutral', mouth: mouthOf('I', t), lookX: 1 }, TON));
  figur(760, GY + 60 + Math.sin(t * 2) * 10, 0.95, Object.assign({ t, mood: t > T('a16') ? 'smug' : 'neutral', mouth: mouthOf('D', t), lookX: -1, handR: t > T('a16') + 0.6 ? [60, -380] : [130, -40] }, STR));
}
function punchFX(t) {
  wide(t, { noMantis: true, bare: true, quiMood: 'furious', fist: true, thaMood: 'shocked' });
  at(580, 760, pop(t, C('punch') - 0.03, 0.25), 0.1, () => { P(); for (let i = 0; i < 16; i++) { const r = i % 2 ? 90 : 190, a = i / 16 * Math.PI * 2; ctx.lineTo(Math.cos(a) * r, Math.sin(a) * r); } ctx.closePath(); fs('#ffd43b', 8, '#e8590c'); txt('POW!', 0, 6, 80, '#c92a2a', { weight: 900 }); });
}
const SHOTS = () => [
  [0, (t) => wide(t, { pull: true })],
  [T('a2') - 0.1, (t) => cam(940, 1000, 1.7, () => wide(t, { pull: true }))],
  [T('a3') - 0.1, (t) => cam(860, 950, 2.3, () => wide(t, { pull: true }))],
  [T('a4') - 0.1, (t) => quiCU(t)],
  [T('a5') - 0.1, (t) => cam(580, 760, 2.0, () => wide(t, { pull: true }))],
  [T('a6') - 0.1, (t) => quiCU(t, { fist: t > C('fist') + 0.2, quiMood: 'furious' })],
  [C('freeze') - 0.02, (t) => freezeFX(t, C('freeze'))],
  [C('rewind') - 0.02, (t) => rewindFX(t)],
  [T('a8') - 0.15, (t) => cam(260, 960, 1.6, () => wide(t, { fist: true, magic: true, quiMood: 'angry', strMood: 'angry' }))],
  [T('a9') - 0.05, (t) => cam(860, 950, 2.3, () => wide(t, { magic: true, fist: true }))],
  [T('a10') - 0.05, (t) => quiCU(t, { magic: true, fist: true, quiMood: 'shocked' })],
  [T('a11') - 0.1, (t) => cam(150, 760, 2.3, () => wide(t, { magic: true, fist: true }))],
  [T('a12') - 0.1, (t) => wide(t, { gauntletUp: true, bare: true, thaHand: [200, -60], tonMood: 'excited' })],
  [T('a13') - 0.1, (t) => cam(580, 760, 2.0, () => wide(t, { gauntletUp: true, bare: true, thaMood: 'shocked', thaHand: [60, -330] }))],
  [T('a14') - 0.1, (t) => quiCU(t, { quiMood: 'smug', fist: true })],
  [C('punch') - 0.05, punchFX],
  [C('punch') + 0.6, (t) => wide(t, { ko: true, quiMood: 'excited', tonMood: 'excited' })],
  [T('a15') - 0.1, twoShot],
  [T('a17') - 0.35, (t) => wide(t, { ko: true, thor: true, quiMood: 'neutral', tonMood: 'neutral' })],
  [T('a18') - 0.1, (t) => cam(560, 1000, 1.25, () => wide(t, { ko: true, thor: true, thorMood: 'shocked', quiMood: 'smug', tonMood: 'smug' }))],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  if (TL.cues.thor && t >= T('a17') - 0.35 && t < T('a17') - 0.15) { ctx.fillStyle = 'rgba(255,255,255,0.8)'; ctx.fillRect(0, 0, W, H); seg(620, 0, 520, 600, 18, '#74c0fc'); seg(520, 600, 600, 1200, 14, '#74c0fc'); }
  sketchTitle(t, 'Wie Infinity War hätte enden sollen', '🧤', 2.2);
  if (t < 2.2) at(540, 420, 1, 0, () => pill('PARODIE', 0, 0, 30, '#e03131', WHITE, { lw: 0 }));
  endCard(t, TL.duration - 1.4, 'Wie Infinity War hätte enden sollen', 'Welchen Film soll ich als Nächstes fixen? 👇');
  drawCaptions(t);
};
window.EP_SCENES = {};
