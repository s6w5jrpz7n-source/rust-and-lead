'use strict';
/* der drang #9: den neuen kratzbaum zu ignorieren */
const EV = TL.data.ev;
const FL = 1450, SOFA_X = 320, POST_X = 830;
function room(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#f3ead9'); g.addColorStop(1, '#e6d6bb'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  for (let x = 60; x < W; x += 140) seg(x, 420, x, FL - 20, 3, 'rgba(160,130,90,0.12)');
  ctx.fillStyle = '#c49a6c'; ctx.fillRect(0, FL - 10, W, H); for (let x = -40; x < W; x += 150) seg(x, FL - 10, x + 60, H, 3, '#b08656');
  rr(90, 520, 300, 210, 8); fs('#fff', 6, '#a68a64'); txt('HOME', 240, 600, 54, '#c0864a', { weight: 900 }); txt('sweet home', 240, 660, 30, '#a68a64', { weight: 700 });
}
function sofa(t, dmg, stuff) {
  rr(30, 860, 600, 340, 60); fs('#4f9ea6', 7, '#245a60');
  rr(10, 1040, 110, 300, 40); fs('#468f97', 7, '#245a60'); rr(540, 1040, 110, 300, 40); fs('#468f97', 7, '#245a60');
  rr(100, 1150, 460, 130, 30); fs('#5bb0b8', 7, '#245a60');
  rr(40, 1270, 580, 110, 24); fs('#3f8890', 7, '#245a60');
  for (const x of [80, 580]) { rr(x - 14, 1380, 28, FL - 1380, 6); ctx.fillStyle = '#5d4037'; ctx.fill(); }
  // Kratzspuren
  for (let i = 0; i < dmg; i++) {
    const x = 210 + (i % 6) * 38 + rnd(i) * 14, y = 900 + Math.floor(i / 6) * 70 + rnd(i + 3) * 20;
    for (let k = 0; k < 3; k++) seg(x + k * 10, y, x + k * 10 + 6, y + 60, 4, '#1f4a4f');
  }
  if (stuff > 0) for (let i = 0; i < 9; i++) { const u = clamp(stuff * 1.4 - i * 0.07); if (u <= 0) continue; const a = rnd(i + 20) * Math.PI * 2; circ(330 + Math.cos(a) * 80 * u, 990 + Math.sin(a) * 60 * u - 30 * u, 26 + rnd(i) * 16); fs('#fffdf6', 4, '#d6cdb8'); }
}
function post(t, sniffed) {
  const x = POST_X;
  rr(x - 130, FL - 40, 260, 40, 12); fs('#e9ddc8', 6, '#8d7b62');
  rr(x - 45, 880, 90, FL - 920, 8); ctx.fillStyle = '#d8b878'; ctx.fill();
  for (let y = 890; y < FL - 40; y += 18) seg(x - 45, y, x + 45, y + 8, 4, '#b8954e');
  rr(x - 45, 880, 90, FL - 920, 8); fs(null, 6, '#8d6e3f');
  rr(x - 120, 840, 240, 46, 14); fs('#e9ddc8', 6, '#8d7b62');
  // Ball an der Schnur
  const sw = Math.sin(t * 2.4) * 0.25; at(x + 90, 886, 1, sw, () => { seg(0, 0, 0, 120, 3, '#555'); circ(0, 136, 18); fs('#ff6b6b', 4, '#a61e1e'); });
  // Preisschild + NEU-Stern
  at(x - 70, 960, 1, -0.18 + Math.sin(t * 2) * 0.03, () => { seg(0, -30, 22, 0, 3, '#555'); rr(-10, 0, 150, 66, 10); fs(WHITE, 4, '#555'); txt('89,99 €', 65, 34, 32, '#c92a2a', { weight: 900 }); });
  at(x + 10, 780, 1 + 0.05 * Math.sin(t * 6), 0.12, () => {
    P(); for (let i = 0; i < 16; i++) { const r = i % 2 ? 52 : 74, a = i / 16 * Math.PI * 2; ctx.lineTo(Math.cos(a) * r, Math.sin(a) * r); } ctx.closePath(); fs(YELLOW, 5, '#c28c00');
    txt('NEU!', 0, 2, 34, '#c92a2a', { weight: 900 });
  });
}
/* Katze von hinten am Sofa, Vorderpfoten hoch */
function scratcher(t, x, s, speed, eye) {
  const ph = t * speed * Math.PI * 2;
  for (const sd of [-1, 1]) {
    const py = -800 + Math.sin(ph + (sd > 0 ? Math.PI : 0)) * 60;
    ctx.save(); ctx.translate(x, FL); ctx.scale(s, s);
    limb(sd * 120, -420, sd * 150, py, 56, CAT.fur);
    ell(sd * 150, py - 20, 44, 36); fs(CAT.belly, 5, CAT.line);
    for (const dx of [-16, 0, 16]) seg(sd * 150 + dx, py - 52, sd * 150 + dx * 1.3, py - 74, 4, '#ffffff');
    ctx.restore();
  }
  catBack(x, FL, s, { t: t * 2 });
  if (eye > 0) catHead(x, FL - 560 * s, s * 0.98, { t, tilt: 0.12 * Math.sin(t * 1.5), pupil: 12, lid: 0.25, gaze: [0, 0] });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  room(t);
  const s = 0.58;
  const dmg = 6 + Math.floor(clamp(t / 2.4) * 6) + (t > EV.scratch2 ? Math.floor(clamp((t - EV.scratch2) / 1.6) * 6) : 0);
  sofa(t, Math.min(18, dmg), t > 6.6 ? prog(t, 6.6, 0.8) : 0);
  post(t);
  const scratching = t < EV.point + 0.3 || (t >= EV.scratch2 && t < EV.end + 1);
  if (scratching) {
    const speed = t >= EV.scratch2 ? 3.2 : 2.2;
    scratcher(t, SOFA_X, s, speed, t >= EV.eye && t < 8.3);
    for (let i = 0; i < 5; i++) { const u = ((t * 1.6 + i / 5) % 1); alpha(1 - u, () => { circ(SOFA_X - 120 + rnd(i) * 240, 960 - u * 120 + rnd(i + 5) * 40, 9); ctx.fillStyle = '#8fd0d6'; ctx.fill(); }); }
  } else if (t < EV.walk) {
    catSit(SOFA_X, FL, s * 0.85, { t, gaze: [0.9, -0.3], pupil: 16 });
  } else if (t < EV.sniff) {
    const u = prog(t, EV.walk, EV.sniff - EV.walk);
    catRun(lerp(SOFA_X, POST_X - 210, eIO(u)), FL, 0.5, t * 1.6, 1);
  } else if (t < EV.back) {
    const sniff = Math.sin(t * 20) * 0.04;
    catSit(POST_X - 200, FL, s * 0.75, { t, gaze: [1, 0.1], pupil: 14, tilt: 0.15 + sniff, lid: t > 4.4 ? 0.5 : 0 });
    if (t < 4.4) for (let i = 0; i < 3; i++) { const u = (t * 2 + i / 3) % 1; alpha(1 - u, () => txt('~', POST_X - 110 + u * 60, 1020 - i * 30, 46, '#868e96', { weight: 700 })); }
    if (t >= 4.4) at(POST_X - 220, 900, pop(t, 4.4, 0.3), 0, () => txt('pff.', 0, 0, 64, INK, { stroke: 8, sc: WHITE, weight: 900 }));
  } else {
    const u = prog(t, EV.back, EV.scratch2 - EV.back);
    catRun(lerp(POST_X - 210, SOFA_X, eIO(u)), FL, 0.5, t * 2.4, -1, { lines: true });
  }
  if (t >= EV.point && t < EV.sniff + 0.4) {
    const a = pop(t, EV.point, 0.35) * (1 - prog(t, EV.sniff, 0.4));
    at(560, 450, a, 0, () => {
      pill('da ist dein kratzbaum!', 0, 0, 44, WHITE, INK, { lw: 6 });
      P(); ctx.moveTo(150, 40); ctx.quadraticCurveTo(330, 60, 280, 225); ctx.lineWidth = 10; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.stroke();
      arrowHead(280, 235, Math.PI * 0.6, 28, INK);
    });
  }
  if (t >= 6.6 && t < 7.6) at(560, 760, pop(t, 6.6, 0.3), -0.08, () => txt('*ratsch*', 0, 0, 60, INK, { stroke: 8, sc: WHITE, weight: 900 }));
  drangBadge(9);
  drangCaption(['der drang, den neuen', 'kratzbaum zu ignorieren 😼']);
  shareBand(t, EV.band);
};
window.EP_SCENES = {};
