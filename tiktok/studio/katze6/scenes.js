'use strict';
/* der drang, den weihnachtsbaum zu erklimmen */
const EV = TL.data.ev;
const TXC = 520, TB = 1440, THt = 860, FL = 1460;
const ORNS = [[-160, 0.85, '#e03131', 'o1'], [140, 0.7, '#fcc419', 'o2'], [-90, 0.5, '#4dabf7', 'o3'], [100, 0.35, '#e64980', 'o4'], [-200, 0.95, '#fcc419'], [60, 0.82, '#4dabf7'], [-30, 0.62, '#e03131'], [20, 0.2, '#fcc419']];
function room(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#3a2433'); g.addColorStop(1, '#24151f'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rr(760, 440, 230, 300, 12); ctx.save(); rr(760, 440, 230, 300, 12); ctx.clip(); ctx.fillStyle = '#16264a'; ctx.fillRect(760, 440, 230, 300);
  for (let i = 0; i < 30; i++) { circ(760 + rnd(i) * 230, 440 + ((rnd(i + 3) * 300 + t * 40) % 300), 3); ctx.fillStyle = WHITE; ctx.fill(); } ctx.restore();
  rr(760, 440, 230, 300, 12); fs(null, 10, '#5a3a4a');
  for (let i = 0; i < 9; i++) { const x = 40 + i * 120; P(); ctx.arc(x + 60, 400, 60, 0, Math.PI); ctx.lineWidth = 10; ctx.strokeStyle = '#2b8a3e'; ctx.stroke(); circ(x + 60, 455, 10); ctx.fillStyle = ['#ff6b6b', '#ffd43b', '#74c0fc'][i % 3]; ctx.fill(); }
  ctx.fillStyle = '#5c3d30'; ctx.fillRect(0, FL - 10, W, H); for (let x = -40; x < W; x += 130) seg(x, FL - 10, x + 50, H, 3, '#4a3026');
}
function tierPath(cx, yb, yt, hw, jag) { P(); ctx.moveTo(cx, yt); ctx.lineTo(cx + hw, yb); for (let i = 8; i >= -8; i--) ctx.lineTo(cx + hw * i / 8, yb + (i % 2 ? -jag : 0)); ctx.closePath(); }
function ornPos(o) { const y = TB - 80 - o[1] * (THt - 160); const hw = 300 * (1 - (TB - y) / THt); return [TXC + clamp(o[0], -hw * 0.8, hw * 0.8), y]; }
function tree(t, wob) {
  ctx.save(); ctx.translate(TXC, TB); ctx.rotate(wob); ctx.translate(-TXC, -TB);
  ctx.fillStyle = '#6b4226'; ctx.fillRect(TXC - 24, TB - 90, 48, 100);
  rr(TXC - 95, TB - 20, 190, 60, 14); fs('#c92a2a', 7, '#5c1a1a');
  [[TB - 60, TB - 320, 320], [TB - 250, TB - 490, 250], [TB - 410, TB - 640, 180], [TB - 570, TB - THt, 115]].forEach(([yb, yt, hw]) => {
    tierPath(TXC, yb, yt, hw, 18); ctx.fillStyle = '#2b8a3e'; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = '#173d1f'; ctx.stroke();
    tierPath(TXC + hw * 0.25, yb - 8, yt + 40, hw * 0.55, 10); ctx.fillStyle = '#237032'; ctx.fill();
  });
  for (let r = 0; r < 4; r++) { const y0 = TB - 150 - r * 160, hw = 270 - r * 55; for (let i = 1; i < 18; i += 2) { const u = i / 18, x = TXC - hw + u * 2 * hw, y = y0 - u * 60 + Math.sin(u * Math.PI) * 30; const on = Math.sin(t * 5 + i + r) > -0.3; const c = ['#ffd43b', '#ff6b6b', '#74c0fc', '#8ce99a'][(i + r) % 4]; ctx.save(); if (on) { ctx.shadowColor = c; ctx.shadowBlur = 16; } ell(x, y, 7, 10); ctx.fillStyle = on ? c : '#495057'; ctx.fill(); ctx.restore(); } }
  ORNS.forEach(o => { if (o[3] && t >= EV[o[3]]) return; const [x, y] = ornPos(o); seg(x, y - 26, x, y - 14, 3, '#adb5bd'); circ(x, y, 20); fs(o[2], 4, '#2b2b2b'); circ(x - 6, y - 6, 6); ctx.fillStyle = 'rgba(255,255,255,0.7)'; ctx.fill(); });
  if (t < EV.star) { ctx.save(); ctx.shadowColor = '#ffd43b'; ctx.shadowBlur = 30; starP(TXC, TB - THt - 10, 52, 22); fs('#ffd43b', 5, '#e67700'); ctx.restore(); }
  const eyes = [[2.6, 3.3, -40, 0.25], [3.4, 4.1, 50, 0.48], [4.2, 4.9, -30, 0.66], [5.0, 5.45, 10, 0.86]];
  for (const [a, b, dx, h] of eyes) if (t >= a && t < b) { const y = TB - 80 - h * (THt - 160); for (const sd of [-1, 1]) { ctx.save(); ctx.shadowColor = '#c0ff60'; ctx.shadowBlur = 20; ell(TXC + dx + sd * 22, y, 12, 15 * (Math.sin((t - a) * 10) > -0.9 ? 1 : 0.2)); ctx.fillStyle = '#d8ff8a'; ctx.fill(); ctx.restore(); ell(TXC + dx + sd * 22, y, 4, 12); ctx.fillStyle = '#111'; ctx.fill(); } }
  ctx.restore();
}
function starP(cx, cy, r1, r2) { P(); for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, r = i % 2 ? r2 : r1; const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); } ctx.closePath(); }
function falling(t) {
  ORNS.forEach((o, i) => {
    if (!o[3] || t < EV[o[3]]) return;
    const [x0, y0] = ornPos(o), u = t - EV[o[3]], T1 = Math.sqrt(2 * (FL - 20 - y0) / 2600);
    if (o[3] === 'o3' && u > T1) { for (let k = 0; k < 10; k++) { const a = -Math.PI * rnd(k + i), v = 200 + rnd(k) * 300, w = Math.min(u - T1, 0.6); at(x0 + Math.cos(a) * v * w, Math.min(FL, FL - 20 + Math.sin(a) * v * w + 1500 * w * w), 1, k + w * 8, () => { P(); ctx.moveTo(0, -10); ctx.lineTo(9, 8); ctx.lineTo(-8, 6); ctx.closePath(); ctx.fillStyle = o[2]; ctx.fill(); }); } return; }
    const y = u < T1 ? y0 + 1300 * u * u : FL - 20 - Math.abs(Math.sin((u - T1) * 8)) * 60 * Math.exp(-(u - T1) * 3);
    const x = x0 + (u > T1 ? (u - T1) * 80 * (i % 2 ? 1 : -1) : 0);
    circ(x, y, 20); fs(o[2], 4, '#2b2b2b');
  });
  if (t >= EV.star) { const u = t - EV.star, y0 = TB - THt - 10, T1 = 0.55; const y = u < T1 ? y0 + (FL - 30 - y0) * (u / T1) ** 2 : FL - 30; at(TXC + 140 * Math.min(1, u / T1), y, 1, u * 4, () => { starP(0, 0, 46, 20); fs('#ffd43b', 5, '#e67700'); }); }
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  room(t);
  const wob = t > EV.jump && t < EV.top + 0.6 ? 0.035 * Math.sin(t * 16) * Math.min(1, (t - EV.jump) * 2) : 0;
  tree(t, wob);
  if (t < EV.jump + 0.4) {
    const jp = kk(t, EV.jump, EV.jump + 0.4);
    const x = lerp(830, 620, jp), y = FL - Math.sin(jp * Math.PI) * 260 - jp * 120;
    alpha(1 - jp, () => catSit(x, y, 0.5 * (1 - 0.3 * jp), { t, tail: 1, gaze: t < EV.look ? [0, 0] : [-0.6, -1], pupil: t < EV.dil ? 12 : 40 }));
  }
  falling(t);
  if (t >= EV.top) {
    const p = pop(t, EV.top, 0.45);
    at(TXC, TB - THt + 40, p, 0, () => {
      catHead(0, -60, 0.42, { t, pupil: lerp(36, 12, kk(t, EV.top + 0.6, EV.top + 1.2)), lid: blinkLid(t, EV.blink), tilt: -0.06 });
      for (const sd of [-1, 1]) { ell(sd * 70, 40, 34, 22); fs(CAT.belly, 4, CAT.line); }
    });
    confetti(t, EV.top, TXC, TB - THt, 50);
  }
  drangCaption(['der drang, den weihnachts-', 'baum zu erklimmen 🎄😼']);
};
window.EP_SCENES = {};
