'use strict';
/* der drang, um 5 uhr frühstück zu verlangen */
const EV = TL.data.ev;
function dawnRoom(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#3a3466'); g.addColorStop(1, '#6b5a8c'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rr(80, 430, 300, 340, 12); ctx.save(); rr(80, 430, 300, 340, 12); ctx.clip();
  const sg = ctx.createLinearGradient(0, 430, 0, 770); sg.addColorStop(0, '#5b4b8a'); sg.addColorStop(1, '#ffb36b'); ctx.fillStyle = sg; ctx.fillRect(80, 430, 300, 340);
  circ(230, 770, 60); ctx.fillStyle = '#ffd8a8'; ctx.fill(); ctx.restore();
  rr(80, 430, 300, 340, 12); fs(null, 10, '#2d2650'); seg(230, 430, 230, 770, 8, '#2d2650');
  ctx.fillStyle = '#2d2650'; ctx.fillRect(0, 1480, W, H);
  rr(0, 1180, W, 320, 30); ctx.fillStyle = '#7d8fd1'; ctx.fill();
  rr(-20, 1200, W + 40, 300, 40); ctx.fillStyle = '#93a3e0'; ctx.fill();
  rr(40, 960, 130, 70, 12); ctx.fillStyle = '#111'; ctx.fill();
  ctx.save(); ctx.shadowColor = '#ff2d2d'; ctx.shadowBlur = 12; ctx.font = `700 40px "JetBrains Mono", monospace`; ctx.fillStyle = '#ff4040'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('05:00', 105, 996); ctx.restore();
  rr(20, 1030, 170, 150, 8); ctx.fillStyle = '#4a3f78'; ctx.fill();
}
function sleeper(t) {
  ell(430, 1170, 230, 80); ctx.fillStyle = '#f1f3f5'; ctx.fill();
  circ(430, 1090, 110); fs('#f2c7a5', 6, '#7a4a2a');
  for (let i = 0; i < 8; i++) { const a = Math.PI * (1.05 + i * 0.12); circ(430 + Math.cos(a) * 100, 1090 + Math.sin(a) * 100, 34); ctx.fillStyle = '#5a3a24'; ctx.fill(); }
  const open = t >= EV.eye && t < EV.close ? kk(t, EV.eye, EV.eye + 0.15) : 0;
  P(); ctx.arc(385, 1085, 18, Math.PI * 0.1, Math.PI * 0.9); fs(null, 5, '#5a3a24');
  if (open > 0.05) { ell(475, 1080, 20, 18 * open); fs(WHITE, 4, '#5a3a24'); circ(485, 1082, 8 * open); ctx.fillStyle = '#222'; ctx.fill(); seg(452, 1050, 498, 1044, 6, '#5a3a24'); }
  else { P(); ctx.arc(475, 1085, 18, Math.PI * 0.1, Math.PI * 0.9); fs(null, 5, '#5a3a24'); }
  ell(440, 1112, 9, 7); ctx.fillStyle = '#e0a080'; ctx.fill();
  if (!open) { ell(432, 1150, 14, 10 + 4 * Math.sin(t * 3)); ctx.fillStyle = '#7a1f2b'; ctx.fill(); }
  else seg(415, 1150, 450, 1146, 5, '#7a1f2b');
  if (!open) for (let i = 0; i < 3; i++) { const u = (t * 0.6 + i / 3) % 1; alpha((1 - u) * 0.8, () => txt('z', 330 - u * 60, 990 - u * 140, 34 + i * 8, WHITE, { stroke: 6 })); }
  P(); ctx.moveTo(180, 1210); ctx.quadraticCurveTo(430, 1160, 700, 1215); ctx.lineTo(700, 1300); ctx.lineTo(180, 1300); ctx.closePath(); ctx.fillStyle = '#93a3e0'; ctx.fill();
}
function bump(t, t0, d = 0.4) { const u = (t - t0) / d; return u > 0 && u < 1 ? Math.sin(u * Math.PI) : 0; }
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  dawnRoom(t); sleeper(t);
  const CX = 760, CY = 1300, S = 0.6;
  const nose = [(450 - CX) / S, (1112 - CY) / S];
  let e = Math.max(bump(t, EV.boop1 - 0.15), bump(t, EV.boop2 - 0.15), bump(t, EV.boop3 - 0.15));
  if (t >= EV.again) e = Math.max(e, 0.7 * kk(t, EV.again, EV.again + 0.8));
  const innocent = t >= EV.eye && t < EV.close;
  const paw = e > 0.02 ? [lerp(-70, nose[0], e), lerp(-14, nose[1], e)] : undefined;
  const meowing = (t >= EV.meow1 && t < EV.meow1 + 0.55) || (t >= EV.meow2 && t < EV.meow2 + 0.8);
  catSit(CX, CY, S, {
    t, tail: 1, pawL: paw, mouth: meowing ? 'meow' : 'w',
    gaze: innocent ? [1, -0.6] : (t < EV.meow1 ? [0, 0] : [-0.9, 0.4]), lid: innocent ? 0.4 : 0, tilt: innocent ? 0.1 : (meowing ? -0.05 : 0),
    pupil: innocent ? 10 : (t > EV.again ? 30 : 16),
  });
  if (t >= EV.meow1 && t < EV.meow1 + 0.9) at(820, 760, pop(t, EV.meow1, 0.3), 0.08, () => { rr(-90, -40, 180, 80, 30); fs(WHITE, 5, INK); txt('miau', 0, 2, 38, INK, { weight: 900 }); });
  if (t >= EV.meow2 && t < EV.meow2 + 1.1) at(800, 740, pop(t, EV.meow2, 0.3), -0.06, () => { rr(-170, -55, 340, 110, 36); fs(WHITE, 6, INK); txt('MIAAAU!', 0, 3, 60, '#c92a2a', { weight: 900 }); });
  for (const b of [EV.boop1, EV.boop2, EV.boop3]) if (t >= b && t < b + 0.5) at(450, 1060, pop(t, b, 0.2), 0, () => txt('boop', 0, -40 - (t - b) * 60, 34, '#ffd43b', { stroke: 7, weight: 900 }));
  if (innocent) at(560, 980, pop(t, EV.eye, 0.25), 0, () => txt('…', 0, 0, 80, WHITE, { stroke: 8 }));
  drangCaption(['der drang, um 5 uhr früh', 'frühstück zu verlangen 😼']);
};
window.EP_SCENES = {};
