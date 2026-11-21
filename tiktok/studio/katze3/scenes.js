'use strict';
/* der drang, sich genau auf die tastatur zu legen */
const EV = TL.data.ev;
const DOC = ['Sehr geehrter Herr Krause,', 'anbei wie besprochen der', 'Quartalsbericht. Die Zahlen', 'sind leider etwas'];
function office(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#e7eef7'); g.addColorStop(1, '#cfdbe9'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rr(70, 420, 220, 260, 10); fs('#fff', 6, '#9fb3c8'); txt('TO-DO', 180, 470, 34, '#c92a2a'); for (let i = 0; i < 3; i++) seg(110, 520 + i * 44, 250, 520 + i * 44, 4, '#adb5bd');
  ctx.fillStyle = '#b07d4f'; ctx.fillRect(0, 1250, W, 50); ctx.fillStyle = '#8c5f37'; ctx.fillRect(0, 1300, W, 620);
  at(940, 1250, 1, 0, () => { rr(-40, -110, 80, 110, 12); fs('#fff', 5, '#495057'); P(); ctx.arc(46, -60, 24, -Math.PI / 2, Math.PI / 2); ctx.lineWidth = 10; ctx.strokeStyle = '#fff'; ctx.stroke(); });
}
function laptop(t) {
  rr(170, 540, 740, 480, 26); fs('#2b2f3a', 8, '#1a1d24');
  ctx.save(); rr(196, 566, 688, 428, 10); ctx.clip();
  ctx.fillStyle = WHITE; ctx.fillRect(196, 566, 688, 428);
  ctx.fillStyle = '#2b579a'; ctx.fillRect(196, 566, 688, 44); txt('Bericht_FINAL_v7.docx', 540, 588, 24, WHITE, { weight: 700 });
  const typed = Math.floor(clamp(t / 2.2) * DOC.join('').length);
  let used = 0;
  ctx.font = `500 30px ${FONT}`; ctx.fillStyle = INK; ctx.textBaseline = 'middle';
  DOC.forEach((ln, i) => { const take = clamp(typed - used, 0, ln.length); ctx.fillText(ln.slice(0, take), 226, 650 + i * 44); used += ln.length; });
  if (t >= 3.6) {
    const n = Math.floor((Math.min(t, 6.0) - 3.6) * 70);
    ctx.font = `500 30px ${FONT}`; ctx.fillStyle = INK;
    for (let i = 0; i < Math.ceil(n / 34); i++) { const c = Math.min(34, n - i * 34); ctx.fillText('j'.repeat(c) + (i === 1 ? 'ölkk' : ''), 226, 826 + i * 40); }
  }
  if (t >= EV.send) {
    const p = pop(t, EV.send, 0.35);
    at(540, 780, p, 0, () => { rr(-280, -80, 560, 160, 20); fs('#ffffff', 6, '#2f9e44'); txt('E-Mail an Chef gesendet', 0, -20, 34, INK, { weight: 900 }); txt('Betreff: jjjjjjjjjjjjjj', 0, 30, 26, '#868e96', { weight: 700 }); circ(-240, -20, 0); });
  }
  ctx.restore();
  P(); ctx.moveTo(120, 1040); ctx.lineTo(960, 1040); ctx.lineTo(1010, 1200); ctx.lineTo(70, 1200); ctx.closePath(); fs('#c5ccd6', 7, '#868e96');
  for (let r = 0; r < 4; r++) for (let c = 0; c < 14; c++) { const x = 150 + r * 12 + c * 54, y = 1058 + r * 30; rr(x, y, 44, 22, 5); ctx.fillStyle = '#e9ecef'; ctx.fill(); }
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  office(t);
  if (t >= EV.pop - 0.1 && t < EV.flop) {
    const rise = kk(t, EV.pop, EV.pop + 0.5);
    catHead(560, lerp(760, 500, rise), 0.42, { t, pupil: lerp(10, 34, kk(t, EV.pop + 0.6, EV.pop + 1.0)), gaze: t < EV.pop + 0.6 ? [-0.8, 0.5] : [0, 0] });
  }
  laptop(t);
  if (t >= EV.flop) {
    const sq = 1 - 0.18 * Math.exp(-(t - EV.flop) * 8) * Math.cos((t - EV.flop) * 20);
    ctx.save(); ctx.translate(560, 1200); ctx.scale(1, sq); ctx.translate(-560, -1200);
    catLoaf(600, 1200, 0.72, { t, pupil: lerp(30, 12, kk(t, 6.2, 6.8)), lid: blinkLid(t, EV.blink), gaze: [0, 0], tilt: -0.05 });
    ctx.restore();
  }
  drangCaption(['der drang, sich genau auf', 'die tastatur zu legen 😼']);
};
window.EP_SCENES = {};
