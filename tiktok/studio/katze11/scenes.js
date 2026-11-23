'use strict';
/* SÜSSES KATZENVIDEO – „Ihr erster Schnee“ ❄️ (Schleife) */
const EV = TL.data.ev;
function flakes(t, x0, y0, w, h, n = 60, sp = 70, seed = 1) {
  ctx.save(); ctx.beginPath(); ctx.rect(x0, y0, w, h); ctx.clip();
  for (let i = 0; i < n; i++) { const x = x0 + ((rnd(i * 3 + seed) * w + Math.sin(t * 1.3 + i) * 20) % w), y = y0 + ((rnd(i * 7 + seed) * h + t * sp * (0.6 + rnd(i))) % h); circ(x, y, 3 + rnd(i * 5) * 5); ctx.fillStyle = 'rgba(255,255,255,0.95)'; ctx.fill(); }
  ctx.restore();
}
/* Kätzchen: kleiner Körper, großer Kopf */
function kitten(x, y, s, o = {}) {
  catSit(x, y, s * 0.72, Object.assign({}, o, { head: false }));
  const hy = y - 330 * s + (o.headDy || 0);
  catHead(x + (o.headDx || 0), hy, s * 1.02 * (o.headScale || 1), o);
  if (o.snowCap > 0) at(x + (o.headDx || 0), hy - 150 * s, s * o.snowCap, 0, () => { for (const [dx, dy, r] of [[-60, 10, 50], [0, -12, 62], [60, 8, 48], [30, 30, 40], [-30, 30, 40]]) { circ(dx, dy, r); fs('#fff', 0); } P(); ctx.arc(0, 0, 90, Math.PI * 1.1, Math.PI * 1.9); fs(null, 5, '#ced4da'); });
}
function room(t) {
  bg('#f6dcc8', '#e9c4a6');
  rr(110, 400, 860, 700, 18); fs('#ffffff', 16, '#b08968');
  ctx.save(); rr(126, 416, 828, 668, 8); ctx.clip();
  const g = ctx.createLinearGradient(0, 416, 0, 1084); g.addColorStop(0, '#a5b8d0'); g.addColorStop(1, '#e7eef6'); ctx.fillStyle = g; ctx.fillRect(126, 416, 828, 668);
  P(); ctx.moveTo(126, 900); ctx.quadraticCurveTo(400, 820, 700, 880); ctx.quadraticCurveTo(860, 910, 954, 860); ctx.lineTo(954, 1084); ctx.lineTo(126, 1084); ctx.closePath(); ctx.fillStyle = '#fff'; ctx.fill();
  for (const [x, s] of [[260, 1], [760, 0.8], [880, 1.1]]) at(x, 900, s, 0, () => { P(); ctx.moveTo(0, -260); ctx.lineTo(90, 0); ctx.lineTo(-90, 0); ctx.closePath(); ctx.fillStyle = '#2f6f4f'; ctx.fill(); P(); ctx.moveTo(0, -260); ctx.lineTo(40, -150); ctx.lineTo(-40, -150); ctx.closePath(); ctx.fillStyle = '#fff'; ctx.fill(); });
  flakes(t, 126, 416, 828, 668, 70, 60);
  ctx.restore();
  seg(540, 400, 540, 1100, 14, '#ffffff'); seg(110, 750, 970, 750, 14, '#ffffff');
  rr(60, 1090, 960, 60, 14); fs('#c9a27e', 6, '#8d6e4d');
  ctx.fillStyle = '#d9b38c'; ctx.fillRect(-80, 1150, W + 160, 900);
}
function outside(t) {
  const g = ctx.createLinearGradient(0, 0, 0, 1200); g.addColorStop(0, '#9fb6d3'); g.addColorStop(1, '#e9f0f8'); ctx.fillStyle = g; ctx.fillRect(-80, -80, W + 160, H + 160);
  for (const [x, s] of [[120, 1.2], [380, 0.9], [900, 1.3], [700, 0.8]]) at(x, 1000, s, 0, () => { for (let k = 0; k < 3; k++) { P(); ctx.moveTo(0, -380 + k * 110); ctx.lineTo(120 - k * 10, -150 + k * 110); ctx.lineTo(-120 + k * 10, -150 + k * 110); ctx.closePath(); ctx.fillStyle = '#2f6f4f'; ctx.fill(); P(); ctx.moveTo(0, -380 + k * 110); ctx.lineTo(50, -300 + k * 110); ctx.lineTo(-50, -300 + k * 110); ctx.closePath(); ctx.fillStyle = '#fff'; ctx.fill(); } });
  P(); ctx.moveTo(-80, 1060); ctx.quadraticCurveTo(300, 980, 600, 1040); ctx.quadraticCurveTo(900, 1090, W + 80, 1020); ctx.lineTo(W + 80, H + 80); ctx.lineTo(-80, H + 80); ctx.closePath(); ctx.fillStyle = '#ffffff'; ctx.fill();
  for (let i = 0; i < 6; i++) { ell(160 + i * 50, 1250 + (i % 2) * 30, 14, 9); ctx.fillStyle = 'rgba(160,180,210,0.6)'; ctx.fill(); }
  flakes(t, -80, -80, W + 160, H, 90, 80, 7);
}
function pile(x, y, s, wiggle) { at(x, y, s, Math.sin(wiggle * 40) * 0.04 * (wiggle > 0 ? 1 : 0), () => { ell(0, 90, 260, 40); ctx.fillStyle = 'rgba(120,150,190,0.25)'; ctx.fill(); for (const [dx, dy, r] of [[-130, 0, 110], [0, -50, 150], [130, 0, 110], [-60, 40, 120], [70, 40, 120]]) { circ(dx, dy, r); fs('#f4f8fd', 6, '#b9cbe2'); } for (const [dx, dy, r] of [[-130, 0, 104], [0, -50, 144], [130, 0, 104], [-60, 40, 114], [70, 40, 114]]) { circ(dx, dy, r); ctx.fillStyle = '#f4f8fd'; ctx.fill(); } P(); ctx.arc(-30, -90, 90, Math.PI * 1.1, Math.PI * 1.5); fs(null, 10, '#ffffff'); }); }
function puff(t, t0, x, y, n = 16) { const u = prog(t, t0, 0.8); if (u <= 0 || u >= 1) return; for (let i = 0; i < n; i++) { const a = -Math.PI * rnd(i + 3), v = 180 + 160 * rnd(i); circ(x + Math.cos(a) * v * u, y + Math.sin(a) * v * u + 300 * u * u, 14 * (1 - u) + 4); ctx.fillStyle = '#dbe7f5'; ctx.fill(); ctx.lineWidth = 2; ctx.strokeStyle = '#b9cbe2'; ctx.stroke(); } }
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  if (t < EV.out) {
    room(t);
    const tapA = Math.max(0, 1 - Math.abs(t - EV.tap1) * 5), tapB = Math.max(0, 1 - Math.abs(t - EV.tap2) * 5), tap = Math.max(tapA, tapB);
    const gx = Math.sin(t * 1.3) * 0.4, gy = -0.7 + Math.sin(t * 0.9) * 0.2;
    kitten(540, 1100, 0.9, { t, gaze: [gx, gy], pupil: 38, shine: false, tilt: Math.sin(t * 1.1) * 0.08, mouth: t > EV.look && t < EV.look + 0.35 ? 'meow' : 'w',
      pawR: tap > 0 ? [lerp(70, 330, tap), lerp(-14, -380, tap)] : undefined });
    for (const tt0 of [EV.tap1, EV.tap2]) if (t > tt0) alpha(1 - prog(t, tt0, 1.2), () => { at(770, 830, 0.8, 0, () => { ell(0, 10, 26, 22); ctx.fillStyle = 'rgba(255,255,255,0.7)'; ctx.fill(); for (const dx of [-24, 0, 24]) { circ(dx, -24, 9); ctx.fill(); } }); });
  } else if (t < EV.inside) {
    outside(t);
    const step = prog(t, EV.out, 1.6);
    const sneezeK = t > EV.sneeze ? Math.exp(-(t - EV.sneeze) * 6) : 0;
    const flakeOn = t > EV.flake && t < EV.sneeze + 0.05;
    const pounce = prog(t, EV.pounce, EV.dive - EV.pounce);
    const hidden = t >= EV.dive && t < EV.pop;
    pile(820, 1320, 1.2, hidden ? t - EV.dive : 0);
    if (t < EV.dive) {
      const kx = lerp(260, 340, step) + pounce * 470, ky = 1400 - Math.sin(Math.PI * pounce) * 380 + Math.abs(Math.sin(step * Math.PI * 4)) * -14 * (step < 1 ? 1 : 0);
      kitten(kx, ky, 0.95, { t, pupil: t > EV.flake ? 30 : 36, gaze: flakeOn ? [0, -0.4] : [0.4, -0.2], lid: sneezeK > 0.3 ? 1 : 0, mouth: sneezeK > 0.5 ? 'o' : 'w',
        headDy: sneezeK * 40, headScale: 1 + sneezeK * 0.08, tilt: pounce * 0.3, pawL: step < 1 && Math.sin(t * 12) > 0 ? [-80, -80] : undefined });
      // Schneeflocke auf der Nase
      const fy = lerp(300, ky - 330 * 0.95 + 60, eIO(prog(t, EV.flake - 1.0, 1.0)));
      if (t > EV.flake - 1.0 && t < EV.sneeze) at(kx + 4, fy, 1, t * 0.8, () => { for (let k = 0; k < 6; k++) { ctx.rotate(Math.PI / 3); seg(0, 0, 0, -18, 4, '#fff'); } circ(0, 0, 5); ctx.fillStyle = '#fff'; ctx.fill(); });
      if (t > EV.sneeze && t < EV.sneeze + 0.9) { at(kx + 160, ky - 420, pop(t, EV.sneeze, 0.25), -0.1, () => txt('hatschi!', 0, 0, 56, '#4a6fa5', { stroke: 10, sc: WHITE })); puff(t, EV.sneeze, kx, ky - 230, 10); }
    }
    puff(t, EV.dive, 820, 1160, 22);
    if (t >= EV.pop) {
      const up = eBack(prog(t, EV.pop, 0.45));
      ctx.save(); ctx.beginPath(); ctx.rect(0, 0, W, 1290); ctx.clip();
      kitten(820, 1560 - up * 300, 0.85, { t, pupil: 38, gaze: [-0.3, 0], snowCap: 1, lid: blinkLid(t, EV.pop + 0.7) * 0.8, mouth: t > 9.9 && t < 10.25 ? 'meow' : 'w' });
      ctx.restore();
      pile(820, 1320, 1.2, 0);
    }
  } else {
    room(t);
    rr(180, 1060, 720, 120, 50); fs('#ffc9de', 6, '#e599b8'); for (let i = 0; i < 6; i++) circ(240 + i * 120, 1120, 16), ctx.fillStyle = '#fff0f6', ctx.fill();
    const melt = 1 - prog(t, EV.inside, 3.0);
    catLoaf(600, 1100, 0.62, { t, pupil: 16, lid: Math.max(0.55, blinkLid(t, EV.blink)), gaze: [0, 0.2] });
    if (melt > 0.05) at(600 - 200 * 0.62, 1100 - 230 * 0.62 - 150 * 0.55, 0.55 * melt, 0, () => { for (const [dx, dy, r] of [[-60, 10, 50], [0, -12, 62], [60, 8, 48]]) { circ(dx, dy, r); fs('#fff', 0); } });
    for (let i = 0; i < 5; i++) { const u = ((t - EV.inside) * 0.35 + i / 5) % 1; alpha(Math.sin(u * Math.PI), () => emo(['🤍', '💛', '🤍', '✨', '🤍'][i], 380 + i * 70, 860 - u * 260, 46)); }
  }
  drangCaption(['ihr erster schnee ❄️']);
  shareBand(t, EV.band, 'schick das jemandem, der heute ein lächeln braucht 🤍');
};
window.EP_SCENES = {};
