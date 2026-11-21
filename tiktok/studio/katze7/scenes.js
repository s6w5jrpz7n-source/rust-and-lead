'use strict';
/* der drang #7: raus wollen – und dann doch nicht */
const EV = TL.data.ev;
const FL = 1470, DX0 = 560, DX1 = 950, DY0 = 600;
function hall(t, open) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#efe3d0'); g.addColorStop(1, '#e2cfb3'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rr(70, 470, 200, 260, 8); fs('#fff', 6, '#a68a64'); txt('🌻', 170, 600, 110, INK);
  ctx.fillStyle = '#b98b5e'; ctx.fillRect(0, FL - 10, W, H); for (let x = -40; x < W; x += 130) seg(x, FL - 10, x + 50, H, 3, '#a47a50');
  rr(DX0 - 30, DY0 - 30, DX1 - DX0 + 60, FL - DY0 + 30, 8); ctx.fillStyle = '#8d6e63'; ctx.fill();
  ctx.save(); ctx.beginPath(); ctx.rect(DX0, DY0, DX1 - DX0, FL - DY0); ctx.clip();
  const sg = ctx.createLinearGradient(0, DY0, 0, FL); sg.addColorStop(0, '#8a96a8'); sg.addColorStop(1, '#5f6d63'); ctx.fillStyle = sg; ctx.fillRect(DX0, DY0, DX1 - DX0, FL - DY0);
  ctx.fillStyle = '#4f6b45'; ctx.fillRect(DX0, FL - 220, DX1 - DX0, 220);
  ctx.strokeStyle = 'rgba(220,230,245,0.7)'; ctx.lineWidth = 3;
  for (let i = 0; i < 50; i++) { const x = DX0 + rnd(i) * (DX1 - DX0), y = DY0 + ((rnd(i + 9) * (FL - DY0) + t * 900) % (FL - DY0)); ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x - 8, y + 34); ctx.stroke(); }
  ctx.restore();
  const pw = (DX1 - DX0) * (1 - open);
  if (pw > 2) { rr(DX1 - pw, DY0, pw, FL - DY0, 4); fs('#c08a5b', 6, '#6d4c41'); if (pw > 60) { rr(DX1 - pw + 30, DY0 + 60, pw - 60, 280, 8); fs('#b07a4c', 4, '#6d4c41'); rr(DX1 - pw + 30, DY0 + 420, pw - 60, 360, 8); fs('#b07a4c', 4, '#6d4c41'); circ(DX1 - pw + 40, DY0 + 400, 14); fs(YELLOW, 4); } }
  if (open > 0.02) { P(); ctx.moveTo(DX1, DY0); ctx.lineTo(DX1 + 70 * open, DY0 - 30); ctx.lineTo(DX1 + 70 * open, FL + 10); ctx.lineTo(DX1, FL); ctx.closePath(); fs('#a8703f', 5, '#6d4c41'); }
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const open = kk(t, EV.open, EV.open + 0.5) * (1 - kk(t, EV.close, EV.close + 0.35));
  hall(t, open);
  const meow = (t < 0.5) || (t >= EV.m2 && t < EV.m2 + 0.6);
  let gaze = [0, 0], lid = 0, tilt = 0;
  if (t >= EV.look && t < EV.turn) gaze = [1, 0.1];
  if (t >= EV.turn && t < EV.glare) { gaze = [0, 0]; lid = 0.45; tilt = 0.08; }
  if (t >= EV.glare && t < EV.m2) gaze = [1, -0.2];
  catSit(380, FL, 0.62, { t, mouth: meow ? 'meow' : 'w', gaze, lid, tilt, pupil: t > EV.look && t < EV.turn ? 26 : 12, flick: t > EV.look + 0.4 && t < EV.turn ? Math.sin(t * 9) : 0, tail: -1 });
  if (meow) at(560, 760, 1, t < 0.5 ? 0.06 : -0.06, () => { rr(-120, -46, 240, 92, 34); fs(WHITE, 6, INK); txt(t < 0.5 ? 'miau!' : 'MIAU!', 0, 3, 46, INK, { weight: 900 }); });
  if (t >= EV.think && t < EV.turn) at(560, 760, pop(t, EV.think, 0.3), 0, () => { circ(0, 0, 54); fs(WHITE, 5, INK); txt('…', 0, -8, 70, INK); circ(-60, 70, 14); fs(WHITE, 4, INK); circ(-88, 100, 8); fs(WHITE, 3, INK); });
  if (t >= EV.turn + 0.2 && t < EV.glare) at(560, 760, pop(t, EV.turn + 0.2, 0.3), 0, () => txt('nö.', 0, 0, 70, INK, { stroke: 8, sc: WHITE, weight: 900 }));
  drangBadge(7);
  drangCaption(['der drang, raus zu wollen', '– und dann doch nicht 😼']);
  shareBand(t, EV.band);
};
window.EP_SCENES = {};
