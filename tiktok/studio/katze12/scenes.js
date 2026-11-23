'use strict';
/* SÜSSES KATZENVIDEO (lang) – „ein tag mit mimi“ 🐱 (6 Kapitel, ~63 s) */
const EV = TL.data.ev;
const CHAP = [['c1', 'aufwachen ☀️'], ['c2', 'frühstück 🥣'], ['c3', 'spielzeit 🧶'], ['c4', 'erster schnee ❄️'], ['c5', 'kuscheln 🤍'], ['c6', 'gute nacht 🌙']];
function flakes(t, x0, y0, w, h, n = 60, sp = 70, seed = 1) {
  ctx.save(); ctx.beginPath(); ctx.rect(x0, y0, w, h); ctx.clip();
  for (let i = 0; i < n; i++) { const x = x0 + ((rnd(i * 3 + seed) * w + Math.sin(t * 1.3 + i) * 20) % w), y = y0 + ((rnd(i * 7 + seed) * h + t * sp * (0.6 + rnd(i))) % h); circ(x, y, 3 + rnd(i * 5) * 5); ctx.fillStyle = 'rgba(255,255,255,0.95)'; ctx.fill(); }
  ctx.restore();
}
function kitten(x, y, s, o = {}) {
  catSit(x, y, s * 0.72, Object.assign({}, o, { head: false }));
  const hy = y - 330 * s * (o.sy || 1) + (o.headDy || 0);
  catHead(x + (o.headDx || 0), hy, s * 1.02 * (o.headScale || 1), o);
  if (o.crumbs) for (const [dx, dy] of [[-70, 60], [-50, 80], [60, 70], [80, 50]]) { circ(x + dx * s, hy + dy * s, 6); ctx.fillStyle = '#8d5524'; ctx.fill(); }
  if (o.snowCap > 0) at(x + (o.headDx || 0), hy - 150 * s, s * o.snowCap, 0, () => { for (const [dx, dy, r] of [[-60, 10, 50], [0, -12, 62], [60, 8, 48], [30, 30, 40], [-30, 30, 40]]) { circ(dx, dy, r); fs('#fff', 0); } P(); ctx.arc(0, 0, 90, Math.PI * 1.1, Math.PI * 1.9); fs(null, 5, '#ced4da'); });
}
function wallRoom(t, o = {}) {
  bg(o.night ? '#2c2f5a' : '#f6dcc8', o.night ? '#1d1f3d' : '#e9c4a6');
  rr(340, 400, 400, 420, 14); fs(o.night ? '#121638' : '#bde0fe', 14, '#ffffff');
  if (o.night) { circ(620, 520, 50); fs('#fff3bf', 0); circ(640, 505, 44); ctx.fillStyle = '#121638'; ctx.fill(); for (let i = 0; i < 12; i++) { const tw2 = 0.5 + 0.5 * Math.sin(t * 3 + i); circ(370 + rnd(i) * 340, 430 + rnd(i + 4) * 360, 2 + tw2 * 2); ctx.fillStyle = '#fff'; ctx.fill(); } }
  else { circ(640, 500, 44); fs('#ffd43b', 0); for (let i = 0; i < 2; i++) { const x = 380 + ((t * 20 + i * 200) % 340); at(x, 600 + i * 90, 1, 0, () => { for (const [dx, r] of [[-26, 24], [0, 34], [28, 24]]) { circ(dx, 0, r); fs('#fff', 0); } }); } }
  if (o.snow) flakes(t, 354, 414, 372, 392, 30, 50);
  seg(540, 400, 540, 820, 10, '#fff'); seg(340, 610, 740, 610, 10, '#fff');
  ctx.fillStyle = o.night ? '#3b3466' : '#d9b38c'; ctx.fillRect(-80, 1150, W + 160, 900);
  if (o.night) { const g = ctx.createRadialGradient(880, 900, 10, 880, 900, 400); g.addColorStop(0, 'rgba(255,214,120,0.35)'); g.addColorStop(1, 'rgba(255,214,120,0)'); ctx.fillStyle = g; ctx.fillRect(400, 400, 800, 1000); rr(860, 900, 40, 250, 8); fs('#e9c46a', 4); P(); ctx.moveTo(800, 900); ctx.lineTo(960, 900); ctx.lineTo(920, 800); ctx.lineTo(840, 800); ctx.closePath(); fs('#ffe8a1', 5); }
}
function basket(x, y, s, front) {
  at(x, y, s, 0, () => {
    if (!front) { ell(0, -40, 300, 120); fs('#c08552', 8, '#7a4a24'); ell(0, -50, 250, 80); fs('#ffc9de', 0); }
    else { P(); ctx.moveTo(-300, -40); ctx.quadraticCurveTo(0, 140, 300, -40); ctx.lineTo(300, 0); ctx.quadraticCurveTo(0, 170, -300, 0); ctx.closePath(); fs('#c08552', 8, '#7a4a24'); for (let i = -5; i <= 5; i++) seg(i * 50, 10 + Math.abs(i) * -4, i * 50 + 10, 90 - Math.abs(i) * 8, 4, '#9c6a3c'); }
  });
}
function outside(t) {
  const g = ctx.createLinearGradient(0, 0, 0, 1200); g.addColorStop(0, '#9fb6d3'); g.addColorStop(1, '#e9f0f8'); ctx.fillStyle = g; ctx.fillRect(-80, -80, W + 160, H + 160);
  for (const [x, s] of [[120, 1.2], [380, 0.9], [900, 1.3], [700, 0.8]]) at(x, 1000, s, 0, () => { for (let k = 0; k < 3; k++) { P(); ctx.moveTo(0, -380 + k * 110); ctx.lineTo(120 - k * 10, -150 + k * 110); ctx.lineTo(-120 + k * 10, -150 + k * 110); ctx.closePath(); ctx.fillStyle = '#2f6f4f'; ctx.fill(); P(); ctx.moveTo(0, -380 + k * 110); ctx.lineTo(50, -300 + k * 110); ctx.lineTo(-50, -300 + k * 110); ctx.closePath(); ctx.fillStyle = '#fff'; ctx.fill(); } });
  P(); ctx.moveTo(-80, 1060); ctx.quadraticCurveTo(300, 980, 600, 1040); ctx.quadraticCurveTo(900, 1090, W + 80, 1020); ctx.lineTo(W + 80, H + 80); ctx.lineTo(-80, H + 80); ctx.closePath(); ctx.fillStyle = '#ffffff'; ctx.fill();
  for (let i = 0; i < 6; i++) { ell(160 + i * 50, 1290 + (i % 2) * 30, 14, 9); ctx.fillStyle = 'rgba(160,180,210,0.6)'; ctx.fill(); }
  flakes(t, -80, -80, W + 160, H, 90, 80, 7);
}
function pile(x, y, s, wiggle) { at(x, y, s, Math.sin(wiggle * 40) * 0.04 * (wiggle > 0 ? 1 : 0), () => { ell(0, 90, 260, 40); ctx.fillStyle = 'rgba(120,150,190,0.25)'; ctx.fill(); for (const [dx, dy, r] of [[-130, 0, 110], [0, -50, 150], [130, 0, 110], [-60, 40, 120], [70, 40, 120]]) { circ(dx, dy, r); fs('#f4f8fd', 6, '#b9cbe2'); } for (const [dx, dy, r] of [[-130, 0, 104], [0, -50, 144], [130, 0, 104], [-60, 40, 114], [70, 40, 114]]) { circ(dx, dy, r); ctx.fillStyle = '#f4f8fd'; ctx.fill(); } }); }
function puff(t, t0, x, y, n = 16, col = '#dbe7f5') { const u = prog(t, t0, 0.8); if (u <= 0 || u >= 1) return; for (let i = 0; i < n; i++) { const a = -Math.PI * rnd(i + 3), v = 180 + 160 * rnd(i); circ(x + Math.cos(a) * v * u, y + Math.sin(a) * v * u + 300 * u * u, 14 * (1 - u) + 4); ctx.fillStyle = col; ctx.fill(); } }
function zzz(t, x, y) { for (let i = 0; i < 3; i++) { const u = (t * 0.5 + i / 3) % 1; alpha(Math.sin(u * Math.PI), () => txt('z', x + u * 60 + i * 12, y - u * 160, 34 + i * 12, '#8d6e9e', { weight: 900 })); } }
function hearts(t, x, y, t0) { for (let i = 0; i < 5; i++) { const u = ((t - t0) * 0.4 + i / 5) % 1; alpha(Math.sin(u * Math.PI), () => emo(['🤍', '💛', '🤍', '✨', '💗'][i], x - 140 + i * 70, y - u * 240, 46)); } }
function yarn(x, y, s, rot) { at(x, y, s, rot, () => { circ(0, 0, 60); fs('#e64980', 6, '#a61e4d'); for (let i = -2; i <= 2; i++) { P(); ctx.arc(i * 14, 0, 58, -1.2, 1.2); fs(null, 4, '#c2255c'); } }); }
/* ---------- Kapitel ---------- */
function ch1(t) {
  wallRoom(t); basket(540, 1290, 1, false);
  if (t < EV.stretch) {
    const open = t < EV.wake ? 1 : t < EV.yawn ? lerp(1, 0.15, prog(t, EV.wake, 1.2)) : 0.15;
    const yawning = t > EV.yawn && t < EV.yawn + 1.4;
    catLoaf(600, 1270, 0.66, { t, lid: yawning ? 0.7 : open, mouth: yawning ? 'meow' : 'w', pupil: 30, tilt: yawning ? -0.15 : 0 });
    if (t < EV.wake) zzz(t, 380, 980);
  } else {
    const st = prog(t, EV.stretch, 1.6), sy = 1 + 0.18 * Math.sin(Math.PI * st);
    kitten(540, 1260, 0.92, { t, sy, sx: 1 - 0.08 * Math.sin(Math.PI * st), pupil: t > EV.sit ? 40 : 26, gaze: [0, 0], lid: st < 1 ? 0.6 : 0, mouth: t > EV.m1 && t < EV.m1 + 0.35 ? 'meow' : 'w', tilt: Math.sin(t * 1.2) * 0.06 });
  }
  basket(540, 1290, 1, true);
}
function ch2(t) {
  bg('#e3f2fd', '#cfe3f5'); for (let x = 0; x < W; x += 90) for (let y = 380; y < 1150; y += 90) { rr(x + 4, y + 4, 82, 82, 6); ctx.fillStyle = 'rgba(255,255,255,0.55)'; ctx.fill(); }
  ctx.fillStyle = '#b5838d'; ctx.fillRect(-80, 1150, W + 160, 900);
  const eating = t > EV.eat && t < EV.look2, bob = eating ? Math.abs(Math.sin(t * 5)) : 0;
  const licking = t > EV.lick && t < EV.happy2;
  kitten(540, 1240, 0.92, { t, pupil: t > EV.look2 ? 40 : 24, gaze: eating ? [0, 0.8] : [0, 0], headDy: eating ? 70 + bob * 30 : 0, tilt: licking ? 0.15 : 0,
    lid: licking ? 0.7 : (t > EV.happy2 ? 0.45 : 0), crumbs: t > EV.look2, mouth: licking ? 'o' : (t > EV.happy2 && t < EV.happy2 + 0.3 ? 'meow' : 'w'),
  });
  if (licking) { const py = 1240 - 330 * 0.92 + 80 + Math.sin(t * 8) * 18; ell(560, py + 30, 14, 18); fs('#ff8fab', 4, CAT.line); ell(575, py + 60, 46, 34); fs(CAT.belly, 5, CAT.line); for (const dx of [-16, 0, 16]) seg(575 + dx, py + 76, 575 + dx, py + 62, 3, '#d9b38c'); }
  at(540, 1300, 1, 0, () => { P(); ctx.moveTo(-170, -40); ctx.lineTo(170, -40); ctx.lineTo(130, 40); ctx.lineTo(-130, 40); ctx.closePath(); fs('#4dabf7', 7, '#1864ab'); const left = t < EV.eat ? 1 : 1 - prog(t, EV.eat, 3.6) * 0.7; for (let i = 0; i < 14 * left; i++) { circ(-120 + (i % 7) * 40, -46 - Math.floor(i / 7) * 16, 14); fs('#a0522d', 3, '#6b3a1e'); } txt('MIMI', 0, 6, 34, '#fff', { weight: 900 }); });
  if (t > EV.happy2) hearts(t, 540, 760, EV.happy2);
}
function ch3(t) {
  wallRoom(t); ell(540, 1330, 460, 120); fs('#ffd8a8', 8, '#f08c00'); ell(540, 1330, 330, 80); fs('#ffe8cc', 0);
  const bx = t < EV.pounce ? lerp(-120, 420, eOut(prog(t, EV.ball, 1.6))) : t < EV.chase ? 420 : lerp(420, 900, eIO(prog(t, EV.chase, 2.0)));
  if (t < EV.tangle) {
    P(); ctx.moveTo(bx, 1280); ctx.bezierCurveTo(bx - 200, 1340, bx - 300, 1220, -100, 1300); fs(null, 5, '#e64980');
    yarn(bx, 1250, 1, (bx / 60));
    if (t < EV.pounce) kitten(760, 1260, 0.9, { t, pupil: 40, gaze: [-0.8, 0.4], tilt: -0.12, tailWag: Math.sin(t * 10) * 0.3 });
    else { const u = prog(t, EV.pounce, 0.6), kx = t < EV.chase ? lerp(760, 520, eOut(u)) : lerp(520, bx - 180, prog(t, EV.chase, 2.0)); catRun(kx, 1300 - Math.sin(Math.PI * Math.min(1, u)) * 160 * (t < EV.chase ? 1 : 0), 0.72, t * 2.2, t < EV.chase ? -1 : 1, { lines: t > EV.chase }); }
  } else {
    catBelly(560, 1300, 0.85, { t, pupil: t > EV.huh ? 40 : 30, lid: 0 });
    ctx.strokeStyle = '#e64980'; ctx.lineWidth = 6; for (let i = 0; i < 7; i++) { P(); ctx.moveTo(300 + i * 60, 1060 + (i % 2) * 40); ctx.bezierCurveTo(400 + i * 30, 1300, 600 - i * 20, 1150, 820 - i * 40, 1280 - (i % 3) * 30); ctx.stroke(); }
    yarn(880, 1300, 0.7, t);
    if (t > EV.huh) at(330, 900, pop(t, EV.huh, 0.3), 0, () => txt('?', 0, 0, 120, '#e64980', { stroke: 10, sc: WHITE }));
  }
}
function ch4(t) {
  if (t < EV.out) {
    wallRoom(t, { snow: true });
    ctx.save(); rr(354, 414, 372, 392, 6); ctx.clip(); P(); ctx.moveTo(354, 700); ctx.quadraticCurveTo(540, 660, 726, 700); ctx.lineTo(726, 806); ctx.lineTo(354, 806); ctx.closePath(); ctx.fillStyle = '#fff'; ctx.fill(); ctx.restore();
    rr(300, 820, 480, 40, 10); fs('#c9a27e', 5, '#8d6e4d');
    const tap = Math.max(0, 1 - Math.abs(t - EV.tap1) * 5, 1 - Math.abs(t - EV.tap2) * 5);
    kitten(540, 1200, 0.85, { t, gaze: [Math.sin(t * 1.3) * 0.4, -0.8], pupil: 40, tilt: Math.sin(t) * 0.07, pawR: tap > 0 ? [lerp(70, 330, tap), lerp(-14, -400, tap)] : undefined });
    return;
  }
  outside(t);
  const step = prog(t, EV.out, 1.4), sneezeK = t > EV.sneeze ? Math.exp(-(t - EV.sneeze) * 6) : 0;
  const pounce = prog(t, EV.pounce4, EV.dive - EV.pounce4), hidden = t >= EV.dive && t < EV.pop;
  pile(820, 1320, 1.2, hidden ? t - EV.dive : 0);
  if (t < EV.dive) {
    const kx = lerp(260, 340, step) + pounce * 470, ky = 1400 - Math.sin(Math.PI * pounce) * 380;
    kitten(kx, ky, 0.95, { t, pupil: 34, gaze: [0, -0.4], lid: sneezeK > 0.3 ? 1 : 0, mouth: sneezeK > 0.5 ? 'o' : 'w', headDy: sneezeK * 40, tilt: pounce * 0.3 });
    const fy = lerp(300, ky - 330 * 0.95 + 60, eIO(prog(t, EV.flake - 0.9, 0.9)));
    if (t > EV.flake - 0.9 && t < EV.sneeze) at(kx + 4, fy, 1, t * 0.8, () => { for (let k = 0; k < 6; k++) { ctx.rotate(Math.PI / 3); seg(0, 0, 0, -18, 4, '#fff'); } });
    if (t > EV.sneeze && t < EV.sneeze + 0.9) { at(kx + 160, ky - 420, pop(t, EV.sneeze, 0.25), -0.1, () => txt('hatschi!', 0, 0, 56, '#4a6fa5', { stroke: 10, sc: WHITE })); puff(t, EV.sneeze, kx, ky - 230, 10); }
  }
  puff(t, EV.dive, 820, 1160, 22);
  if (t >= EV.pop) { const up = eBack(prog(t, EV.pop, 0.45)); ctx.save(); ctx.beginPath(); ctx.rect(0, 0, W, 1290); ctx.clip(); kitten(820, 1560 - up * 300, 0.85, { t, pupil: 40, gaze: [-0.3, 0], snowCap: 1, lid: blinkLid(t, EV.pop + 0.8) * 0.8, mouth: t > 41.3 && t < 41.6 ? 'meow' : 'w' }); ctx.restore(); pile(820, 1320, 1.2, 0); }
}
function ch5(t) {
  wallRoom(t);
  rr(60, 900, 200, 260, 16); fs('#f1f3f5', 6, '#adb5bd'); for (let i = 0; i < 6; i++) seg(90 + i * 28, 920, 90 + i * 28, 1140, 8, '#ced4da');
  for (let i = 0; i < 3; i++) { const u = (t * 0.5 + i / 3) % 1; alpha(1 - u, () => { P(); ctx.moveTo(110 + i * 50, 880 - u * 160); ctx.quadraticCurveTo(130 + i * 50, 840 - u * 160, 110 + i * 50, 800 - u * 160); fs(null, 5, '#ffa8a8'); }); }
  rr(240, 1220, 660, 110, 50); fs('#c5f6fa', 6, '#66d9e8');
  const petting = t > EV.pet && t < EV.bump + 1.6, bump = t > EV.bump && t < EV.bump + 1.2 ? Math.sin(Math.PI * prog(t, EV.bump, 1.2)) : 0;
  catLoaf(600, 1240, 0.66, { t, pupil: 30, lid: petting ? 0.85 : 0, tilt: petting ? -0.2 - bump * 0.15 : 0, gaze: [0.6, -0.3] });
  const hin = eOut(prog(t, EV.hand, 0.8)), hx = lerp(1250, 520, hin) + (petting ? Math.sin(t * 3) * 60 : 0) - bump * 30, hy = 880 + (petting ? Math.abs(Math.sin(t * 3)) * 20 : 0);
  if (t > EV.hand) at(hx, hy, 1, -0.3, () => { rr(40, -50, 600, 100, 40); fs('#748ffc', 6, '#4263eb'); ell(0, 0, 90, 60); fs('#f2c7a5', 6, '#c98f6f'); for (let i = 0; i < 4; i++) { rr(-130 + i * 8, -54 + i * 28, 90, 30, 15); fs('#f2c7a5', 5, '#c98f6f'); } });
  if (petting) hearts(t, 460, 760, EV.pet);
}
function ch6(t) {
  wallRoom(t, { night: true });
  basket(540, 1290, 1, false);
  const sl = t > EV.sleep ? 1 : t > EV.blink ? blinkLid(t, EV.blink) : 0.2;
  catLoaf(600, 1270, 0.66, { t, lid: sl, pupil: 24, tilt: 0.05 });
  basket(540, 1290, 1, true);
  if (t > EV.sleep) { zzz(t, 380, 980); at(540, 760, pop(t, EV.sleep + 0.5, 0.45), 0, () => txt('gute nacht, mimi 🤍', 0, 0, 64, '#fff', { stroke: 12, sc: '#1d1f3d' })); }
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const fns = [ch1, ch2, ch3, ch4, ch5, ch6];
  let ci = 0; CHAP.forEach(([k], i) => { if (t >= EV[k]) ci = i; });
  fns[ci](t);
  const st = EV[CHAP[ci][0]];
  if (ci > 0 && t - st < 0.35) alpha(1 - (t - st) / 0.35, () => { ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, W, H); });
  drangCaption(['ein tag mit mimi 🐱']);
  at(540, 370, pop(t, st, 0.35), 0, () => pill(`${ci + 1}/6 · ${CHAP[ci][1]}`, 0, 0, 34, 'rgba(255,255,255,0.92)', INK, { lw: 0 }));
  shareBand(t, EV.band, 'schick das jemandem, der ein lächeln braucht 🤍');
};
window.EP_SCENES = {};
