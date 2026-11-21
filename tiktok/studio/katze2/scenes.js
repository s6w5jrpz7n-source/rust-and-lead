'use strict';
/* der drang, um 3 uhr nachts durch die wohnung zu rennen */
const EV = TL.data.ev;
const FL = 1470;
function bedroom(t, shake) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#1d2244'); g.addColorStop(1, '#0d1028'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rr(700, 440, 280, 340, 12); ctx.fillStyle = '#0b1838'; ctx.fill();
  circ(880, 520, 40); ctx.fillStyle = '#fff6d6'; ctx.fill();
  for (let i = 0; i < 12; i++) { circ(720 + rnd(i) * 240, 460 + rnd(i + 4) * 300, 2); ctx.fillStyle = WHITE; ctx.fill(); }
  seg(840, 440, 840, 780, 8, '#2d3561'); seg(700, 610, 980, 610, 8, '#2d3561'); rr(700, 440, 280, 340, 12); fs(null, 10, '#2d3561');
  ctx.save(); ctx.globalAlpha = 0.12; P(); ctx.moveTo(700, 780); ctx.lineTo(980, 780); ctx.lineTo(700, FL); ctx.lineTo(260, FL); ctx.closePath(); ctx.fillStyle = '#cfe0ff'; ctx.fill(); ctx.restore();
  ctx.fillStyle = '#2a2140'; ctx.fillRect(0, FL - 10, W, H);
  // Bett
  rr(30, 1020, 530, 260, 20); ctx.fillStyle = '#3b2f5c'; ctx.fill(); rr(30, 900, 40, 380, 10); ctx.fillStyle = '#4a3a70'; ctx.fill();
  at(260, 1040, 1, shake * Math.sin(t * 60) * 0.03, () => {
    ell(-130, -30, 80, 40); ctx.fillStyle = '#d0d4f0'; ctx.fill();
    P(); ctx.arc(-150, -60, 34, Math.PI, Math.PI * 2); ctx.fillStyle = '#3d2a1a'; ctx.fill();
    P(); ctx.moveTo(-200, 0); ctx.quadraticCurveTo(-120, -110, 60, -70); ctx.quadraticCurveTo(250, -60, 300, 10); ctx.lineTo(300, 60); ctx.lineTo(-200, 60); ctx.closePath(); ctx.fillStyle = '#5b6fb5'; ctx.fill();
  });
  if (shake > 0.3) txt('?!', 250, 880, 80, '#ffd43b', { stroke: 10 });
  // Nachttisch + Uhr + Lampe
  rr(580, 1150, 150, 120, 8); ctx.fillStyle = '#4a3a70'; ctx.fill();
  rr(595, 1095, 120, 56, 10); ctx.fillStyle = '#111'; ctx.fill();
  ctx.save(); ctx.shadowColor = '#ff2d2d'; ctx.shadowBlur = 14; ctx.font = `700 40px "JetBrains Mono", monospace`; ctx.fillStyle = '#ff4040'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText(t < EV.p3 + 0.5 ? '03:00' : '03:01', 655, 1124); ctx.restore();
  const lp = prog(t, EV.lamp, 0.35);
  at(700, 1150 + lp * 300, 1, lp * 1.6, () => { seg(0, 0, 0, -70, 6, '#8e86b0'); P(); ctx.moveTo(-30, -70); ctx.lineTo(30, -70); ctx.lineTo(20, -110); ctx.lineTo(-20, -110); ctx.closePath(); ctx.fillStyle = '#ffd8a8'; ctx.fill(); });
}
function runPos(t) {
  const passes = [[EV.p1, EV.p1 + 0.7, -300, 1380, 1, 0], [EV.p2, EV.p2 + 0.75, 1300, -300, -1, 1], [EV.p3, EV.p3 + 0.65, -300, 1380, 1, 0], [EV.p4, EV.p4 + 0.8, 1380, 855, -1, 0]];
  for (const [a, b, x0, x1, dir, jump] of passes) if (t >= a && t < b) {
    const u = (t - a) / (b - a), x = lerp(x0, x1, u);
    const y = jump ? FL - Math.max(0, Math.sin(clamp((x - 650) / -700) * Math.PI)) * 430 * (x < 650 && x > -50 ? 1 : 0) : FL;
    return { x, y, dir, ph: (t - a) * 4.5 };
  }
  return null;
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const shake = t >= EV.p2 + 0.2 && t < EV.p2 + 1.2 ? 1 - prog(t, EV.p2 + 0.2, 1.0) : 0;
  bedroom(t, shake);
  const r = runPos(t);
  if (r) catRun(r.x, r.y, 0.55, r.ph, r.dir, { lines: true });
  else {
    const before = t < EV.go;
    const pupil = before ? lerp(26, 44, kk(t, EV.dil, EV.dil + 0.3)) : lerp(40, 14, kk(t, EV.stop + 0.6, EV.stop + 1.4));
    const wig = before && t > EV.dil ? Math.sin(t * 30) * 0.4 : 0;
    catSit(855, FL, 0.6, { t, pupil, shine: true, tailWag: wig, lid: blinkLid(t, EV.blink), tilt: t > EV.stop ? 0.04 : 0, gaze: t > EV.stop && t < EV.stop + 0.8 ? [-0.5, 0] : [0, 0] });
  }
  drangCaption(['der drang, um 3 uhr nachts', 'durch die wohnung zu rennen 😼']);
};
window.EP_SCENES = {};
