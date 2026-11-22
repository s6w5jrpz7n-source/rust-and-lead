'use strict';
/* SKETCH 3 – „Gemeinsame Interessen“ 🍷 */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { F: '#f783ac', M: '#ced4da' };
const SHE = { shirt: '#c2255c', pants: '#343a40', hair: 'long', hairCol: '#5c3317', browCol: '#3b2314', lips: '#c92a2a', earrings: true, noLegs: true };
const HE = { shirt: '#495057', collar: WHITE, tie: '#212529', pants: '#343a40', hair: 'slick', hairCol: '#2b2b2b', noLegs: true };
function resto(t, dark) {
  bg('#5c2a1a', '#2b120a');
  for (let i = 0; i < 9; i++) { const x = 60 + i * 120; circ(x, 420 + (i % 2) * 30, 10); ctx.fillStyle = 'rgba(255,212,59,0.9)'; ctx.fill(); const g = ctx.createRadialGradient(x, 430, 0, x, 430, 90); g.addColorStop(0, 'rgba(255,200,80,0.35)'); g.addColorStop(1, 'rgba(255,200,80,0)'); ctx.fillStyle = g; ctx.fillRect(x - 90, 340, 180, 180); }
  rr(380, 480, 320, 220, 10); fs('#2b120a', 8, '#c9a227'); txt('🍷 Ristorante', 540, 590, 30, '#ffd43b', { weight: 800 });
  if (dark) alpha(dark, () => { ctx.fillStyle = '#0b0b12'; ctx.fillRect(-80, -80, W + 160, H + 160); });
}
function table(t, o = {}) {
  rr(40, 1120, 1000, 80, 16); fs('#f8f9fa', 7, '#adb5bd'); ctx.fillStyle = '#e9ecef'; ctx.fillRect(60, 1200, 960, 500);
  // Kerze, Wein, Teller
  rr(525, 1000, 30, 120, 6); fs('#fff9db', 4); const f = 1 + 0.12 * Math.sin(t * 15); ell(540, 984, 10 * f, 22 * f); fs('#ffd43b', 0);
  for (const [x, c] of [[330, '#8b1e2d'], [760, '#8b1e2d']]) { P(); ctx.moveTo(x - 34, 990); ctx.quadraticCurveTo(x, 1060, x + 34, 990); ctx.closePath(); fs(c, 5); seg(x, 1050, x, 1110, 6); seg(x - 26, 1112, x + 26, 1112, 6); }
  ell(250, 1140, 120, 30); fs('#fff', 5); ell(830, 1140, 120, 30); fs('#fff', 5); ell(830, 1132, 60, 16); fs('#8d5524', 0);
  if (o.bread) { const bx = lerp(700, 420, eOut(clamp(o.bread))); at(bx, 1110, 1, 0, () => { P(); ctx.moveTo(-90, -20); ctx.lineTo(90, -20); ctx.lineTo(70, 30); ctx.lineTo(-70, 30); ctx.closePath(); fs('#c8963e', 6); for (let i = 0; i < 3; i++) { ell(-50 + i * 50, -34, 34, 20); fs('#e8b96a', 5); } }); }
}
function couple(t, o = {}) {
  figur(250, 1120, 0.95, Object.assign({ t, mood: o.sheMood || 'excited', mouth: mouthOf('F', t), lookX: 1, handR: [140, -60] }, SHE));
  const cut = o.cutting ? Math.sin(t * 10) * 16 : 0;
  figur(830, 1120, 0.95, Object.assign({ t, mood: o.heMood || 'neutral', mouth: mouthOf('M', t), lookX: -1, handL: [-150 + cut, -40], handR: o.push ? [-160, -40] : [150 - cut, -40],
    holdL: (hx, hy) => seg(hx, hy, hx + 50, hy + 40, 8, '#adb5bd'), holdR: o.push ? undefined : (hx, hy) => seg(hx, hy - 50, hx, hy + 10, 8, '#adb5bd') }, HE));
}
function wide(t, lt, o = {}) { resto(t, o.dark); couple(t, o); table(t, o); }
function sheCU(t, lt, o = {}) { cam(250, 770, 1.8, () => wide(t, lt, o)); }
function heCU(t, lt, o = {}) { cam(830, 770, 1.8, () => wide(t, lt, o)); }
const SHOTS = () => [
  [0, (t, lt) => wide(t, lt)],
  [T('d2') - 0.1, (t, lt) => heCU(t, lt, { cutting: true })],
  [T('d3') - 0.1, (t, lt) => sheCU(t, lt, { sheMood: 'neutral' })],
  [T('d4') - 0.1, (t, lt) => { heCU(t, lt, { heMood: 'bored', dark: 0.45 * prog(t, T('d4'), 0.4) }); }],
  [E('d4') + 0.2, (t, lt) => sheCU(t, lt, { sheMood: 'shocked', dark: 0.45 })],
  [T('d5') - 0.2, (t, lt) => wide(t, lt, { sheMood: 'shocked', heMood: 'neutral', push: true, bread: prog(t, T('d5') - 0.2, 0.6), dark: 0.3 })],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  if (t > E('d4') + 0.2 && t < T('d5') - 0.2) at(250, 430, 1, 0, () => emo('😶', 0, 0, 90));
  sketchTitle(t, 'Gemeinsame Interessen', '🍷', 2.0);
  endCard(t, TL.duration - 1.3, 'Gemeinsame Interessen 🍷', 'Schick das deinem nächsten Date');
  drawCaptions(t);
};
window.EP_SCENES = {};
