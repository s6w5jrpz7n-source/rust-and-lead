'use strict';
/* SKETCH 5 – „Bis dass der Tod uns scheidet“ 💍 */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { G: '#a5d8ff', M: '#ffd43b' };
const HUS = { shirt: '#5c7cfa', pants: '#364fc7', hair: 'receding', hairCol: '#6b4f3a', noLegs: true };
const GHO = { shirt: '#dbe4ff', skin: '#e7f5ff', hair: 'long', hairCol: '#c5d3f0', browCol: '#7c8db5', lips: '#748ffc' };
function room(t, light) {
  bg('#141b33', '#0b1020');
  rr(120, 420, 260, 320, 10); fs('#1f2a4d', 10, '#2b3a66'); circ(250, 520, 40); ctx.fillStyle = '#e7f5ff'; ctx.fill();
  // Schrank rechts
  const sl = TL.cues.slam, open = t >= sl ? eOut(prog(t, sl, 0.25)) : 0;
  rr(700, 380, 340, 760, 10); fs('#5c3d2e', 8, '#2b1a10');
  for (const [dx, sd] of [[700, -1], [870, 1]]) {
    if (open > 0) { ctx.fillStyle = '#1a0f08'; ctx.fillRect(dx + 6, 390, 164, 740); }
    at(dx + (sd < 0 ? 0 : 170), 760, 1, 0, () => { ctx.save(); ctx.scale(1 - open * 1.6, 1); rr(sd < 0 ? 0 : -170, -370, 170, 740, 8); fs('#7a5238', 6, '#2b1a10'); circ(sd < 0 ? 150 : -150, 0, 10); fs('#ffd43b', 3); ctx.restore(); });
  }
  if (open > 0) for (let i = 0; i < 6; i++) { const u = clamp((t - sl) * 1.5 - i * 0.05); at(860 + (rnd(i) - 0.5) * 300 * u, 760 - u * 300 * rnd(i + 3), 1, u * 6 * (rnd(i) - 0.5), () => emo(['👗', '👠', '👜', '🧥', '👚', '📦'][i], 0, 0, 70)); }
  if (light > 0) alpha(light, () => { const g = ctx.createRadialGradient(170, 900, 20, 170, 900, 700); g.addColorStop(0, 'rgba(255,214,120,0.55)'); g.addColorStop(1, 'rgba(255,214,120,0)'); ctx.fillStyle = g; ctx.fillRect(-80, 300, W + 160, 1400); });
}
function bed(t, o = {}) {
  rr(60, 1000, 640, 140, 30); fs('#e9ecef', 7, '#868e96');
  figur(380, 1120, 0.85, Object.assign({ t, mood: o.mood || 'neutral', mouth: mouthOf('M', t), lookX: o.lookX ?? 1, handL: o.handL || [-130, -40], handR: o.handR || [130, -40], holdR: o.phone ? (hx, hy) => phoneR(hx, hy - 30, 0.9, -0.1, '#ff6b9d') : undefined }, HUS));
  const bl = o.blanket ?? 0;
  P(); ctx.moveTo(40, 1100 - bl * 230); ctx.quadraticCurveTo(380, 1060 - bl * 250, 720, 1100 - bl * 230); ctx.lineTo(740, 1500); ctx.lineTo(20, 1500); ctx.closePath(); fs('#748ffc', 7, '#364fc7');
  for (let i = 0; i < 6; i++) seg(80 + i * 110, 1180 - bl * 180, 120 + i * 110, 1450, 4, '#5c7cfa');
  // Nachttisch + Lampe + Foto
  rr(740, 1100, 260, 300, 10); fs('#5c3d2e', 7, '#2b1a10');
  const on = o.lamp ?? 0;
  seg(930, 1100, 930, 960, 8, '#adb5bd'); P(); ctx.moveTo(870, 960); ctx.lineTo(990, 960); ctx.lineTo(960, 880); ctx.lineTo(900, 880); ctx.closePath(); fs(on > 0.5 ? '#ffe066' : '#868e96', 6);
  at(900, 1085, 1, 0.1, () => { rr(-30, -14, 60, 28, 6); fs('#212529', 3); rr(-24, -9, 48, 18, 3); ctx.fillStyle = '#ff6b9d'; ctx.fill(); });
  at(810, 1030, 1, -0.06, () => { rr(-60, -70, 120, 140, 6); fs('#c9a227', 6, '#7a5c00'); rr(-48, -58, 96, 116, 4); fs('#fff9db', 0); circ(-18, -10, 16); fs('#f2c7a5', 3); circ(18, -10, 16); fs('#f2c7a5', 3); txt('💍', 0, 34, 26, INK); });
}
function ghost(t, x, y, s, o = {}) {
  const fl = 0.55 + 0.1 * Math.sin(t * 5);
  ctx.save(); ctx.shadowColor = '#a5d8ff'; ctx.shadowBlur = 50;
  figur(x, y + Math.sin(t * 2) * 14, s, Object.assign({ t, ghost: fl, mood: o.mood || 'furious', mouth: mouthOf('G', t), lookX: o.lookX ?? -1, handR: o.point ? [200, -300] : [130, -60] }, GHO));
  ctx.restore();
}
function lampState(t) { if (t < C('lamp')) return 0; if (t >= C('flicker') && t < C('flicker') + 1.0) return rnd(Math.floor(t * 18)) > 0.45 ? 1 : 0; return 1; }
function wide(t, lt, o = {}) {
  const L = lampState(t);
  room(t, L * 0.9);
  const gi = eOut(prog(t, C('ghost') - 0.3, 0.9));
  if (gi > 0) alpha(gi, () => ghost(t, 560, 900, 0.85, o.ghost || {}));
  bed(t, Object.assign({ lamp: L }, o.bed || {}));
}
function phoneCU(t, lt) {
  ctx.fillStyle = '#0b1020'; ctx.fillRect(0, 0, W, H);
  at(540, 900, 1, 0, () => { rr(-300, -540, 600, 1080, 70); fs('#212529', 10, '#000'); rr(-270, -500, 540, 1000, 40); fs('#fff0f6', 0);
    txt('❤️ SwipeLove', 0, -430, 40, '#e64980', { weight: 900 });
    const sw = Math.sin(t * 2.2) * 40;
    at(sw, -60, 1, sw * 0.004, () => { rr(-220, -300, 440, 560, 30); fs('#f1f3f5', 6, '#dee2e6'); circ(0, -80, 110); fs('#ffd8a8', 5); txt('Jenny, 29', 0, 130, 40, INK, { weight: 900 }); txt('2 km entfernt', 0, 180, 26, '#868e96', { weight: 700 }); });
    for (const [x, e] of [[-120, '❌'], [120, '💚']]) { circ(x, 400, 60); fs('#fff', 5, '#dee2e6'); emo(e, x, 400, 56); } });
}
const SHOTS = () => [
  [0, (t, lt) => wide(t, lt, { bed: t < T('g1') + 0.7 ? { mood: 'calm' } : { mood: 'shocked', handL: [-170, -260], handR: [170, -260], lookX: 1 } })],
  [TOK('g1', 10) - 0.1, phoneCU],
  [E('g1') + 0.05, (t, lt) => wide(t, lt, { bed: { mood: 'shocked', lookX: 1 } })],
  [T('g2') - 0.1, (t, lt) => cam(380, 800, 1.6, () => wide(t, lt, { bed: { mood: 'calm', handL: [-130, -40], handR: [150, -60] } }))],
  [T('g3') - 0.1, (t, lt) => wide(t, lt, { bed: { mood: 'smug', handR: [330, -170] }, ghost: { mood: 'furious' } })],
  [T('g4') - 0.1, (t, lt) => cam(560, 700, 1.8, () => wide(t, lt, { ghost: { mood: 'angry', lookX: 0 } }))],
  [C('slam') - 0.15, (t, lt) => wide(t, lt, { bed: { mood: 'shocked', blanket: eOut(prog(t, C('slam') + 0.4, 1.2)), handL: [-60, -330], handR: [60, -330] }, ghost: { mood: 'smug', point: true } })],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  sketchTitle(t, 'Bis dass der Tod uns scheidet', '💍', 2.0);
  endCard(t, TL.duration - 1.3, 'Bis dass der Tod uns scheidet 💍', 'Markier jemanden, der das braucht');
  drawCaptions(t);
};
window.EP_SCENES = {};
