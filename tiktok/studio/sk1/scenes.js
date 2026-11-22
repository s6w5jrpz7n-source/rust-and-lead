'use strict';
/* SKETCH 1 – „Ein letztes Mal“ ⚰️ */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { S: '#74c0fc', B: '#ced4da' };
const SON = { stand: true, shirt: '#212529', collar: WHITE, tie: '#343a40', pants: '#212529', hair: 'slick', hairCol: '#4a3426' };
const UND = { stand: true, shirt: '#2b2b33', collar: '#e9ecef', pants: '#2b2b33', hair: 'bun', hairCol: '#3b2a20', browCol: '#3b2a20', lips: '#a61e4d' };
const SIS = { stand: true, shirt: '#1a1a1f', pants: '#1a1a1f', skirt: '#1a1a1f', hair: 'long', hairCol: '#f2d16b', browCol: '#a07c3c', glasses: true, lips: '#c2255c', earrings: true };
function hall(t) {
  bg('#3a2f52', '#1d1729');
  for (const x of [200, 540, 880]) { P(); ctx.moveTo(x - 90, 760); ctx.lineTo(x - 90, 420); ctx.arc(x, 420, 90, Math.PI, 0); ctx.lineTo(x + 90, 760); ctx.closePath(); fs('#5c4d7d', 8, '#140f1e'); for (let i = 0; i < 3; i++) seg(x - 90 + i * 60 + 30, 380, x - 90 + i * 60 + 30, 760, 4, '#140f1e'); }
  ctx.fillStyle = '#2a1f1a'; ctx.fillRect(-80, 1060, W + 160, 900); P(); ctx.moveTo(380, 1060); ctx.lineTo(700, 1060); ctx.lineTo(900, 1920); ctx.lineTo(180, 1920); ctx.closePath(); ctx.fillStyle = '#7a1f2b'; ctx.fill();
  for (const x of [80, 1000]) { seg(x, 1100, x, 760, 10, '#c9a227'); rr(x - 16, 700, 32, 60, 6); fs('#fff9db', 4); const f = 1 + 0.15 * Math.sin(t * 13 + x); ell(x, 682, 10 * f, 22 * f); fs('#ffd43b', 0); }
}
function coffin(t, front) {
  const x = 600, y = 1080;
  if (!front) {
    P(); ctx.moveTo(x - 300, y - 120); ctx.lineTo(x + 300, y - 120); ctx.lineTo(x + 320, y - 330); ctx.lineTo(x - 280, y - 330); ctx.closePath(); fs('#5c3317', 7, '#2b1608');
    rr(x - 280, y - 300, 560, 200, 30); fs('#f8f0e3', 5, '#c9b99a');
    ell(x, y - 240, 120, 40); fs('#fff', 4, '#c9b99a');
    // Vater liegt aufgebahrt, Gesicht nach vorn, Augen zu
    figur(x, y - 40, 0.5, { t, mood: 'dead', shirt: '#343a40', collar: WHITE, tie: '#c92a2a', hair: 'receding', hairCol: '#adb5bd', mustache: '#ced4da', noLegs: true, skin: SKIN_OLD, handL: [-40, -120], handR: [40, -120] });
  } else {
    P(); ctx.moveTo(x - 300, y - 150); ctx.lineTo(x + 300, y - 150); ctx.lineTo(x + 280, y + 80); ctx.lineTo(x - 280, y + 80); ctx.closePath(); fs('#6b3d1e', 7, '#2b1608');
    for (const dx of [-230, 230]) { rr(x + dx - 30, y - 40, 60, 24, 10); fs('#c9a227', 4, '#7a5c00'); }
    for (let i = 0; i < 7; i++) { circ(x - 240 + i * 80, y - 150, 26); fs(i % 2 ? '#fff' : '#ffe3e3', 3, '#c9b99a'); }
    rr(x - 260, y + 80, 520, 40, 6); fs('#3b2314', 5, '#2b1608');
  }
}
function wide(t, lt, o = {}) {
  hall(t);
  if (o.sister !== false) figur(965, 900, 0.6, Object.assign({ t, mood: 'bored', mouth: 0, lookX: -1, handR: t >= C('sister') ? [60, -360] : [120, -40], holdR: t >= C('sister') ? (hx, hy) => phoneR(hx, hy - 20, 0.7, 0.1) : undefined }, SIS));
  coffin(t, false);
  const reach = o.reach ?? 1;
  figur(260, 1150, 0.82, Object.assign({ t, mood: o.sonMood || 'sad', mouth: mouthOf('S', t), lookX: 1, handR: [lerp(130, 300, reach), lerp(-40, -260, reach)],
    holdR: (hx, hy) => phoneR(hx + 20, hy - 30, 0.8, -0.3, t > C('fail') && t < C('fail') + 0.6 ? '#ff6b6b' : '#4dabf7') }, SON));
  coffin(t, true);
  if (t >= C('sister') && o.sister !== false) at(965, 470, pop(t, C('sister'), 0.3), 0, () => emo('👀', 0, 0, 80));
}
function faceCU(t, lt) {
  cam(520, 860, 2.0, () => wide(t, lt, { sister: false }));
  const scan = (t * 1.2) % 1;
  at(600, 858, 0.75, 0, () => { ctx.strokeStyle = 'rgba(77,171,247,0.9)'; ctx.lineWidth = 8; for (const [sx, sy] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) { P(); ctx.moveTo(sx * 150, sy * 110); ctx.lineTo(sx * 150, sy * 60); ctx.moveTo(sx * 150, sy * 110); ctx.lineTo(sx * 100, sy * 110); ctx.stroke(); } seg(-140, -100 + scan * 200, 140, -100 + scan * 200, 4, 'rgba(77,171,247,0.7)'); });
}
function twoShot(t, lt) {
  cam(300, 820, 1.55, () => {
    hall(t); coffin(t, false);
    const inn = eOut(prog(t, T('s2') - 0.3, 0.5));
    figur(lerp(-200, 60, inn), 1150, 0.82, Object.assign({ t, mood: 'calm', mouth: mouthOf('B', t), handR: [180, -230] }, UND));
    figur(300, 1150, 0.82, Object.assign({ t, mood: 'sad', mouth: mouthOf('S', t), lookX: 1, handR: [300, -260], holdR: (hx, hy) => phoneR(hx + 20, hy - 30, 0.8, -0.3) }, SON));
    if (inn > 0.6) { circ(205, 860, 24); fs(SKIN1, 6); }
    coffin(t, true);
  });
}
function sonCU(t, lt) {
  cam(300, 760, 2.2, () => {
    hall(t);
    figur(60, 1150, 0.82, Object.assign({ t, mood: 'calm', mouth: 0, handR: [130, -40] }, UND));
    figur(300, 1150, 0.82, Object.assign({ t, mood: 'angry', mouth: mouthOf('S', t), lookX: -1, rot: -0.05, handR: [120, -380], holdR: (hx, hy) => phoneR(hx, hy - 40, 0.8, 0.1) }, SON));
  });
}
function phoneCU(t, lt) {
  ctx.fillStyle = '#1d1729'; ctx.fillRect(0, 0, W, H);
  const f = TL.cues.fail, sh = t > f ? Math.sin(t * 70) * 14 * Math.exp(-(t - f) * 4) : 0;
  at(540 + sh, 900, 1, 0, () => {
    rr(-300, -560, 600, 1120, 70); fs('#212529', 10, '#000'); rr(-270, -520, 540, 1040, 40); fs('#f8f9fa', 0);
    txt('Face ID', 0, -380, 54, INK, { weight: 800 });
    const fail = t > f;
    at(0, -120, 1, 0, () => { ctx.strokeStyle = fail ? '#e03131' : '#4dabf7'; ctx.lineWidth = 14; for (const [sx, sy] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) { P(); ctx.moveTo(sx * 110, sy * 60); ctx.lineTo(sx * 110, sy * 110); ctx.lineTo(sx * 60, sy * 110); ctx.stroke(); }
      if (fail) { seg(-40, -40, 40, 40, 14, '#e03131'); seg(40, -40, -40, 40, 14, '#e03131'); } else { circ(-30, -20, 8); fs(INK, 0); circ(30, -20, 8); fs(INK, 0); P(); ctx.arc(0, 10, 40, 0.2, Math.PI - 0.2); fs(null, 8); } });
    if (fail) { txt('Gesicht nicht', 0, 120, 62, '#e03131', { weight: 900 }); txt('erkannt', 0, 190, 62, '#e03131', { weight: 900 }); }
    else txt('Wird gescannt …', 0, 140, 48, '#868e96', { weight: 700 });
  });
}
function finale(t, lt) {
  wide(t, lt, { sonMood: 'bored', reach: 0.2 });
}
const SHOTS = () => [
  [0, (t, lt) => wide(t, lt, { reach: eOut(prog(t, 0.3, 0.8)) })], [TOK('s1', 6) - 0.05, faceCU], [T('s2') - 0.35, twoShot],
  [T('s3') - 0.05, sonCU], [E('s3') + 0.15, phoneCU], [C('fail') + 0.9, finale],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  sketchTitle(t, 'Ein letztes Mal', '⚰️', 2.2);
  endCard(t, TL.duration - 1.3, 'Ein letztes Mal ⚰️', 'Folg für mehr schwarzen Humor');
  drawCaptions(t);
};
window.EP_SCENES = {};
