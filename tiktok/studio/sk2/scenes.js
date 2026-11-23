'use strict';
/* SKETCH 2 – „Die Hölle hat sich verändert“ 🔥 */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { M: '#74c0fc', T: '#ff6b6b', P: '#f783ac' };
const MAN = { stand: true, shirt: '#f1f3f5', tie: '#1c7ed6', collar: WHITE, pants: '#495057', hair: 'receding', hairCol: '#6b4f3a', glasses: true };
const DEV = { stand: true, shirt: '#1a1a1a', collar: '#c92a2a', tie: '#c92a2a', pants: '#1a1a1a', hair: 'slick', hairCol: '#111', skin: '#e8443a', horns: true, tail: true, browCol: '#111', mustache: '#111' };
const HR = { stand: true, shirt: '#f783ac', pants: '#495057', skirt: '#ffd8e8', hair: 'bob', hairCol: '#ffd43b', browCol: '#a07c3c', lips: '#e64980', earrings: true };
function flames(t, y, h, a = 1) {
  for (let i = 0; i < 22; i++) {
    const x = (i * 53) % 1120 - 20, ph = t * 3 + i, hh = h * (0.6 + 0.4 * Math.sin(ph * 1.7)) * (0.7 + 0.3 * rnd(i));
    alpha(a, () => { P(); ctx.moveTo(x - 40, y); ctx.quadraticCurveTo(x - 30 + Math.sin(ph) * 20, y - hh * 0.6, x + Math.sin(ph * 1.3) * 18, y - hh); ctx.quadraticCurveTo(x + 30, y - hh * 0.5, x + 40, y); ctx.closePath(); ctx.fillStyle = i % 3 ? '#ff922b' : '#ffd43b'; ctx.fill(); });
  }
}
function hell(t) {
  bg('#2b0505', '#7a1405');
  flames(t, 900, 420, 0.55);
  ctx.fillStyle = '#3b0d06'; ctx.fillRect(-80, 900, W + 160, 1100);
  for (let i = 0; i < 6; i++) { const x = 100 + i * 180, y = 1500 + (i % 2) * 120; ell(x, y, 120, 30); fs('#ff6b00', 0); ell(x, y, 80, 18); fs('#ffd43b', 0); }
  flames(t + 1, 1960, 260, 0.9);
  // Tür
  rr(620, 420, 300, 520, 10); fs('#3b2314', 8, '#1a0d05'); circ(880, 700, 14); fs('#ffd43b', 4);
}
function office(x0, y0, w, h, t) {
  ctx.save(); rr(x0, y0, w, h, 6); ctx.clip();
  ctx.fillStyle = '#ced4da'; ctx.fillRect(x0, y0, w, h);
  for (let i = 0; i < 4; i++) { rr(x0 + 20 + i * (w / 4), y0 + 16, w / 4 - 40, 14, 4); ctx.fillStyle = '#f8f9fa'; ctx.fill(); }
  for (let r = 0; r < 3; r++) for (let c = 0; c < 4; c++) {
    const dx = x0 + 30 + c * (w / 4), dy = y0 + 120 + r * (h / 3.4);
    rr(dx, dy + 60, w / 4 - 40, 14, 3); fs('#adb5bd', 3, '#868e96'); rr(dx + 20, dy, 60, 46, 4); fs('#343a40', 3); rr(dx + 26, dy + 6, 48, 34, 2); ctx.fillStyle = '#74c0fc'; ctx.fill();
    circ(dx + 110, dy + 20, 16); fs('#dee2e6', 3, '#868e96');
  }
  rr(x0 + w - 150, y0 + 60, 120, 80, 4); fs('#fff', 3, '#868e96'); txt('TEAM-', x0 + w - 90, y0 + 88, 18, '#1c7ed6', { weight: 900 }); txt('GEIST!', x0 + w - 90, y0 + 112, 18, '#1c7ed6', { weight: 900 });
  ctx.restore();
}
function hellWide(t, lt, o = {}) {
  hell(t);
  const open = o.open || 0;
  if (open > 0) { ctx.save(); P(); ctx.rect(620, 420, 300 * open, 520); ctx.clip(); office(620, 420, 300, 520, t); ctx.restore(); alpha(open * 0.4, () => { ctx.fillStyle = '#e7f5ff'; P(); ctx.moveTo(620, 940); ctx.lineTo(920, 940); ctx.lineTo(1080, 1300); ctx.lineTo(500, 1300); ctx.closePath(); ctx.fill(); }); }
  if (open > 0 && open < 1) { P(); ctx.moveTo(620 + 300 * open, 420); ctx.lineTo(620 + 300 * open - 40 * (1 - open), 400); ctx.lineTo(620 + 300 * open - 40 * (1 - open), 960); ctx.lineTo(620 + 300 * open, 940); ctx.closePath(); fs('#3b2314', 6, '#1a0d05'); }
  figur(780, 1180, 0.9, Object.assign({ t, mood: o.devMood || 'smug', mouth: mouthOf('T', t), lookX: -1, handL: o.devHandL || [-130, -40], handR: open > 0 ? [170, -260] : [130, -40] }, DEV));
  figur(290, 1180, 0.85, Object.assign({ t, mood: o.manMood || 'sweat', mouth: mouthOf('M', t), lookX: 1, handR: o.grab ? [380, -230] : [130, -40] }, MAN));
}
function devCU(t, lt) {
  cam(780, 760, 1.9, () => hellWide(t, lt, { open: eIO(prog(t, C('door'), 0.8)) }));
}
function officeShot(t, lt) {
  ctx.fillStyle = '#ced4da'; ctx.fillRect(0, 0, W, H);
  office(0, 300, W, 900, t);
  ctx.fillStyle = '#adb5bd'; ctx.fillRect(0, 1200, W, 800);
  const inn = eOut(prog(t, C('hr') - 0.2, 0.5));
  figur(lerp(1300, 540, inn), 1300, 1.05, Object.assign({ t, mood: 'excited', mouth: mouthOf('P', t), handR: [170, -300], holdR: (hx, hy) => { at(hx + 10, hy - 50, 1, 0, () => { rr(-46, -60, 92, 110, 14); fs('#fff', 6); P(); ctx.arc(50, -6, 24, -Math.PI / 2, Math.PI / 2); fs(null, 10, INK); emo('❤️', 0, -10, 40); txt('WILLKOMMEN', 0, 32, 12, '#e64980', { weight: 900 }); }); } }, HR));
  for (let i = 0; i < 8; i++) { const u = (t * 0.6 + i / 8) % 1; alpha(Math.sin(u * Math.PI), () => emo(['🎉', '✨', '💼', '🥳'][i % 4], 120 + i * 120, 1250 - u * 700, 56)); }
}
function grabShot(t, lt) {
  cam(540, 860, 1.25, () => hellWide(t, lt, { open: 1, manMood: 'shocked', grab: true, devMood: 'smug' }));
  at(300, 560, 1 + 0.05 * Math.sin(t * 30), 0, () => emo('😰', 0, 0, 90));
}
const SHOTS = () => [[0, (t, lt) => hellWide(t, lt)], [T('h2') - 0.1, devCU], [T('h3') - 0.3, officeShot], [T('h4') - 0.1, grabShot]];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  sketchTitle(t, 'Die Hölle hat sich verändert', '🔥', 2.0);
  endCard(t, TL.duration - 1.3, 'Die Hölle hat sich verändert 🔥', 'Schick das an dein Team 😈');
  drawCaptions(t);
};
window.EP_SCENES = {};
