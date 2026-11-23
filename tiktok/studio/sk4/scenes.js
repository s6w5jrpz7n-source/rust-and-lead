'use strict';
/* SKETCH 4 – „Omas Lieblingsenkel“ 👵 */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { E: '#74c0fc', O: '#ffd43b' };
const OMA = { shirt: '#9c36b5', collar: '#f3d9fa', pants: '#5f3dc4', hair: 'bun', hairCol: '#dee2e6', browCol: '#adb5bd', glasses: true, skin: SKIN_OLD, earrings: true, noLegs: true };
const ENK = { shirt: '#15aabf', pants: '#343a40', hair: 'long', hairCol: '#212529', browCol: '#212529', lips: '#e64980', noLegs: true };
const CALLERS = ['Neffe Dennis', 'Tante Gabi', 'Schwiegersohn Ralf', 'Cousine Mandy', 'Onkel Bernd'];
function kitchen(t) {
  bg('#fff3bf', '#ffe8a1');
  for (let x = 0; x < W; x += 60) for (let y = 360; y < 980; y += 60) if (((x + y) / 60) % 2 === 0) { ctx.fillStyle = 'rgba(255,255,255,0.35)'; ctx.fillRect(x, y, 60, 60); }
  // Fenster
  rr(620, 420, 380, 360, 10); fs('#a5d8ff', 10, '#f8f9fa'); seg(810, 420, 810, 780, 8, '#f8f9fa'); seg(620, 600, 1000, 600, 8, '#f8f9fa');
  rr(100, 450, 220, 160, 10); fs('#fff', 6, '#c9a227'); txt('Zuhause', 210, 515, 30, '#e8590c', { weight: 900 }); txt('ist wo Oma ist', 210, 555, 20, '#e8590c', { weight: 700 });
}
function relatives(t, p) {
  if (p <= 0) return;
  ctx.save(); rr(620, 420, 380, 360, 10); ctx.clip();
  const items = ['💐', '🛍️', '🎂', '💐', '🍾'];
  for (let i = 0; i < 5; i++) {
    const x = 650 + i * 80, y = 820 - eOut(clamp(p * 1.4 - i * 0.12)) * 280 + Math.sin(t * 5 + i) * 6;
    circ(x, y, 46); fs(['#f2c7a5', '#e8b894', '#efc9b0', '#f2c7a5', '#d9a383'][i], 5); circ(x - 14, y - 6, 6); ctx.fillStyle = INK; ctx.fill(); circ(x + 14, y - 6, 6); ctx.fill();
    P(); ctx.arc(x, y + 10, 18, 0.2, Math.PI - 0.2); fs(null, 5); emo(items[i], x + 30, y + 70, 50);
  }
  ctx.restore();
}
function phoneOnTable(t, x, y, s) {
  const ringing = t < T('o2') + 0.5 || (t > E('o3') && t < TL.duration);
  const vib = ringing ? Math.sin(t * 80) * 4 : 0;
  at(x + vib, y, s, 0.08, () => { rr(-70, -120, 140, 240, 20); fs('#212529', 6); rr(-60, -104, 120, 208, 12); fs('#e7f5ff', 0);
    const name = CALLERS[Math.floor(t * 0.9) % CALLERS.length];
    txt('📞', 0, -60, 40, INK); txt(name, 0, 0, 16, INK, { weight: 900, maxW: 110 }); txt('ruft an …', 0, 30, 14, '#495057', { weight: 700 });
    rr(-50, 60, 40, 30, 15); fs('#40c057', 0); rr(10, 60, 40, 30, 15); fs('#fa5252', 0); });
  if (ringing) for (let i = 0; i < 2; i++) { const u = (t * 2 + i / 2) % 1; alpha(1 - u, () => { P(); ctx.arc(x, y, 150 + u * 80, -0.5, 0.5); ctx.lineWidth = 6; ctx.strokeStyle = '#fa5252'; ctx.stroke(); }); }
}
function tableScene(t, o = {}) {
  kitchen(t);
  relatives(t, o.rel || 0);
  figur(260, 1150, 0.95, Object.assign({ t, mood: o.omaMood || 'smug', mouth: mouthOf('O', t), lookX: 1, handR: o.keks ? [140, -260] : [150, -40],
    holdR: o.keks ? (hx, hy) => { circ(hx + 10, hy - 30, 30); fs('#d9a066', 5); for (let i = 0; i < 4; i++) { circ(hx - 2 + i * 8, hy - 36 + (i % 2) * 12, 4); ctx.fillStyle = '#5c3317'; ctx.fill(); } } : undefined }, OMA));
  figur(820, 1150, 0.95, Object.assign({ t, mood: o.enkMood || 'shocked', mouth: mouthOf('E', t), lookX: -1, handL: o.hold ? [-120, -260] : [-150, -40] }, ENK));
  rr(40, 1110, 1000, 70, 14); fs('#e8590c', 7, '#a03a06'); ctx.fillStyle = '#fff4e6'; ctx.fillRect(60, 1180, 960, 600);
  for (let i = 0; i < 12; i++) seg(60 + i * 80, 1180, 60 + i * 80, 1780, 3, '#ffd8a8');
  at(400, 1060, 1, 0, () => { rr(-40, -50, 80, 70, 14); fs('#fff', 6); P(); ctx.arc(44, -16, 18, -Math.PI / 2, Math.PI / 2); fs(null, 8, INK); for (let i = 0; i < 2; i++) { const u = (t * 0.5 + i / 2) % 1; alpha(1 - u, () => seg(-10 + i * 20, -60 - u * 60, -4 + i * 20, -90 - u * 60, 4, '#adb5bd')); } });
  if (!o.hold) phoneOnTable(t, 640, 1090, 0.7);
}
function phoneScreen(t, lt) {
  ctx.fillStyle = '#ffe8a1'; ctx.fillRect(0, 0, W, H);
  at(540, 900, 1, 0, () => {
    rr(-330, -560, 660, 1120, 70); fs('#212529', 10, '#000'); rr(-300, -520, 600, 1040, 40); fs('#ece5dd', 0);
    rr(-300, -520, 600, 110, 40); fs('#1864ab', 0); txt('Familie 👪 (23)', 0, -460, 34, WHITE, { weight: 800 });
    const msgs = [['Oma', '📄 Testament_ENTWURF.pdf'], ['Oma', '📄 Testament_ENTWURF_v2.pdf'], ['Oma', '🗳️ Umfrage: Wer kriegt das Haus?'], ['Oma', '⏳ Abstimmung endet am 24.12.']];
    msgs.forEach(([who, m], i) => { const p = pop(t, T('o3') + 0.15 + i * 0.35, 0.3); at(-40, -330 + i * 130, p, 0, () => { rr(-230, -50, 470, 100, 18); fs('#fff', 0); txt(who, -200, -24, 22, '#e8590c', { align: 'left', weight: 800 }); txt(m, -200, 14, 26, INK, { align: 'left', weight: 700, maxW: 420 }); }); });
    if (t > C('handy') + 0.4) at(0, 280, pop(t, C('handy') + 0.4, 0.35), -0.08, () => { rr(-210, -60, 420, 120, 14); fs(null, 10, '#e03131'); txt('ENTWURF', 0, 4, 76, '#e03131', { weight: 900 }); });
  });
}
const SHOTS = () => [
  [0, (t, lt) => tableScene(t, { enkMood: 'shocked' })],
  [T('o2') - 0.1, (t, lt) => cam(260, 760, 1.7, () => tableScene(t, { omaMood: 'smug' }))],
  [T('o3') - 0.15, phoneScreen],
  [T('o4') - 0.1, (t, lt) => cam(260, 760, 1.7, () => tableScene(t, { omaMood: 'smug', keks: true, hold: true }))],
  [C('bell') - 0.1, (t, lt) => tableScene(t, { omaMood: 'smug', enkMood: 'shocked', keks: true, hold: true, rel: prog(t, C('bell'), 1.2) })],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  sketchTitle(t, 'Omas Lieblingsenkel', '👵', 2.0);
  endCard(t, TL.duration - 1.3, 'Omas Lieblingsenkel 👵', 'Schick das in deine Familiengruppe');
  drawCaptions(t);
};
window.EP_SCENES = {};
