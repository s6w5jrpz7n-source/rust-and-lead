'use strict';
/* der drang, in jeden karton zu passen */
const EV = TL.data.ev;
const FL = 1470;
function living(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#f3e3cf'); g.addColorStop(1, '#e6cfb2'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rr(640, 430, 320, 400, 14); ctx.fillStyle = '#fff6e6'; ctx.fill(); seg(800, 430, 800, 830, 10, '#d8c2a2'); seg(640, 630, 960, 630, 10, '#d8c2a2');
  rr(90, 460, 260, 200, 8); fs('#c5a880', 6, '#8d6e63'); txt('♥', 220, 560, 90, '#e8590c');
  ctx.fillStyle = '#b98b5e'; ctx.fillRect(0, FL - 10, W, H); for (let x = -40; x < W; x += 130) seg(x, FL - 10, x + 50, H, 3, '#a47a50');
}
function boxBack(x, w, h) { P(); ctx.moveTo(x - w / 2, FL - h); ctx.lineTo(x - w / 2 + 30, FL - h - 30); ctx.lineTo(x + w / 2 + 30, FL - h - 30); ctx.lineTo(x + w / 2, FL - h); ctx.closePath(); fs('#8a5a2b', 5, '#5c3a1a'); }
function boxFront(x, w, h, label, t, bulge = 0) {
  P(); ctx.moveTo(x + w / 2, FL - h); ctx.lineTo(x + w / 2 + 30, FL - h - 30); ctx.lineTo(x + w / 2 + 30, FL - 30); ctx.lineTo(x + w / 2, FL); ctx.closePath(); fs('#b57a3e', 5, '#5c3a1a');
  P(); ctx.moveTo(x - w / 2 - bulge, FL - h); ctx.quadraticCurveTo(x, FL - h - bulge * 0.5, x + w / 2 + bulge, FL - h); ctx.lineTo(x + w / 2 + bulge * 0.6, FL); ctx.lineTo(x - w / 2 - bulge * 0.6, FL); ctx.closePath(); fs('#d29a5a', 6, '#5c3a1a');
  for (const sd of [-1, 1]) at(x + sd * w / 2, FL - h, 1, sd * (0.5 + 0.1 * Math.sin(t * 3)), () => { rr(sd > 0 ? 0 : -w * 0.45, -12, w * 0.45, 24, 4); fs('#c88f50', 4, '#5c3a1a'); });
  if (label) txt(label, x, FL - h / 2, Math.min(34, w * 0.11), '#7a3e10', { weight: 900 });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  living(t);
  const B1 = [560, 320, 170], B2 = [850, 170, 90];
  const b2 = pop(t, EV.box2, 0.4);
  boxBack(B1[0], B1[1], B1[2]);
  if (b2 > 0) at(B2[0], FL, b2, 0, () => { ctx.translate(-B2[0], -FL); boxBack(B2[0], B2[1], B2[2]); });
  // Katze
  let cx = 330, sx = 1, sy = 1, lift = 0;
  const inn = kk(t, EV.step, EV.settle);
  cx = lerp(330, B1[0], inn); lift = Math.sin(inn * Math.PI) * 160;
  sx = lerp(1, 1.4, inn); sy = lerp(1, 0.55, inn);
  const wob = t > EV.settle ? 0.04 * Math.exp(-(t - EV.settle) * 5) * Math.sin((t - EV.settle) * 25) : 0;
  const jp = kk(t, EV.jump, EV.land);
  if (t >= EV.jump) { cx = lerp(B1[0], B2[0], jp); lift = Math.sin(jp * Math.PI) * 260; sx = lerp(1.4, 1.7, jp); sy = lerp(0.55, 0.42, jp); }
  const look = t < EV.look ? [0, 0] : t < EV.step ? [0.8, 0.7] : t < EV.box2 + 0.2 ? [0, 0] : t < EV.jump ? [1, 0.5] : [0, 0];
  const pupil = t < EV.box2 + 0.3 ? 12 : t < EV.land + 0.6 ? 40 : lerp(40, 12, kk(t, EV.land + 0.6, EV.land + 1.2));
  catSit(cx, FL - lift - (inn > 0.9 ? 20 : 0), 0.6, { t, sx: sx * (1 + wob), sy: sy * (1 - wob), pupil, gaze: look, lid: blinkLid(t, EV.blink), tail: 1, tilt: t > EV.land ? -0.06 : 0 });
  boxFront(B1[0], B1[1], B1[2], 'ZERBRECHLICH', t, t > EV.settle && t < EV.jump ? 18 : 0);
  if (b2 > 0) at(B2[0], FL, b2, 0, () => { ctx.translate(-B2[0], -FL); boxFront(B2[0], B2[1], B2[2], 'MINI', t, t > EV.land ? 26 : 0); });
  if (t >= EV.box2 && t < EV.jump) at(B2[0], FL - 200, pop(t, EV.box2 + 0.3, 0.3), 0, () => txt('!!', 0, 0, 80, '#e8590c', { stroke: 10 }));
  drangCaption(['der drang, in jeden', 'karton zu passen 😼']);
};
window.EP_SCENES = {};
