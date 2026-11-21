'use strict';
/* der drang #10: dem sonnenfleck hinterherzurutschen */
const EV = TL.data.ev;
const FL = 1300, CY = 1390, S = 0.58;
const HOPS = ['h2', 'h3', 'h4'];
const patchX = t => lerp(240, 700, clamp(t / EV.sunset));
const catTarget = tt => patchX(tt) + 60;
function catX(t) {
  // Startposition (nach "again" wieder links) und Hüpfer zu den Sonnenfleck-Positionen
  let x = catTarget(0), from = x, hopT = -9;
  for (const h of HOPS) if (t >= EV[h]) { from = x; x = catTarget(EV[h]); hopT = EV[h]; }
  if (t >= EV.again) { from = x; x = catTarget(0); hopT = EV.again; }
  const u = prog(t, hopT, 0.42);
  return { x: lerp(from, x, eIO(u)), y: -Math.sin(Math.PI * u) * (hopT === EV.again ? 160 : 90), hop: u > 0 && u < 1, land: hopT + 0.42 };
}
function room(t, dim) {
  const g = ctx.createLinearGradient(0, 0, 0, FL); g.addColorStop(0, '#f6e7cf'); g.addColorStop(1, '#ecd4b0'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, FL);
  ctx.fillStyle = '#a97b52'; ctx.fillRect(0, FL, W, H - FL); for (let y = FL + 40; y < H; y += 80) seg(0, y, W, y, 3, '#956a43');
  seg(0, FL, W, FL, 10, '#7a5536');
  // Fenster links oben
  const sky = ctx.createLinearGradient(0, 470, 0, 860);
  const k = clamp(t / EV.sunset);
  const k2 = clamp((k - 0.5) / 0.5), mix = (a, b) => `rgb(${a.map((v, i) => Math.round(lerp(v, b[i], k2))).join(',')})`;
  sky.addColorStop(0, dim > 0.5 ? '#1d2b53' : mix([116, 192, 252], [255, 146, 43])); sky.addColorStop(1, dim > 0.5 ? '#3b3f73' : mix([208, 235, 255], [255, 212, 140]));
  rr(70, 470, 360, 400, 10); ctx.fillStyle = sky; ctx.fill(); ctx.lineWidth = 16; ctx.strokeStyle = WHITE; ctx.stroke();
  seg(250, 470, 250, 870, 12, WHITE); seg(70, 670, 430, 670, 12, WHITE);
  if (dim < 0.5) { circ(lerp(380, 120, k), lerp(540, 820, k), 34); ctx.fillStyle = k > 0.7 ? '#ff922b' : '#ffe066'; ctx.fill(); }
  else { circ(360, 540, 26); ctx.fillStyle = '#f1f3f5'; ctx.fill(); }
  // Wanduhr
  const hrs = t < EV.again ? lerp(10, 18, clamp(t / EV.sunset)) + 0.4 * clamp((t - EV.sunset) / 2) : lerp(19, 34, prog(t, EV.again, 0.5));
  at(800, 600, 1, 0, () => {
    circ(0, 0, 92); fs(WHITE, 8, '#5c4033');
    for (let i = 0; i < 12; i++) { const a = i / 12 * Math.PI * 2; seg(Math.cos(a) * 72, Math.sin(a) * 72, Math.cos(a) * 82, Math.sin(a) * 82, 5, '#5c4033'); }
    const ha = (hrs % 12) / 12 * Math.PI * 2 - Math.PI / 2, ma = (hrs % 1) * Math.PI * 2 - Math.PI / 2;
    seg(0, 0, Math.cos(ha) * 46, Math.sin(ha) * 46, 9, INK); seg(0, 0, Math.cos(ma) * 68, Math.sin(ma) * 68, 6, INK); circ(0, 0, 8); ctx.fillStyle = INK; ctx.fill();
  });
  const hh = Math.floor(hrs) % 24; pill(`${String(hh).padStart(2, '0')}:00`, 800, 735, 30, '#5c4033', WHITE, { lw: 0 });
}
function patch(t, a) {
  if (a <= 0) return;
  const px = patchX(t), k = clamp(t / EV.sunset), w = lerp(380, 240, k);
  alpha(a, () => {
    // Lichtstrahl vom Fenster
    P(); ctx.moveTo(250 - 100, 870); ctx.lineTo(250 + 100, 870); ctx.lineTo(px + w / 2 + 40, CY - 20); ctx.lineTo(px - w / 2 - 40, CY - 20); ctx.closePath();
    ctx.fillStyle = `rgba(255,${Math.round(lerp(236, 190, k))},120,0.16)`; ctx.fill();
    P(); ctx.moveTo(px - w / 2, CY - 70); ctx.lineTo(px + w / 2 + 50, CY - 70); ctx.lineTo(px + w / 2, CY + 70); ctx.lineTo(px - w / 2 - 50, CY + 70); ctx.closePath();
    ctx.fillStyle = `rgba(255,${Math.round(lerp(226, 160, k))},${Math.round(lerp(110, 60, k))},0.62)`; ctx.fill();
  });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const dim = clamp(prog(t, EV.sunset, 0.6) - prog(t, EV.again, 0.4));
  room(t, dim);
  const pa = t < EV.again ? 1 - prog(t, EV.sunset, 0.5) : prog(t, EV.again, 0.4);
  patch(t < EV.again ? t : 0, pa);
  const c = catX(t);
  const glare = t >= EV.glare && t < EV.again;
  const inSun = !glare && !c.hop && dim < 0.5;
  const dl = t - c.land, sq = c.hop || dl < 0 ? 1 : 1 - 0.14 * Math.exp(-dl * 7) * Math.cos(dl * 18);
  ctx.save(); ctx.translate(c.x, CY + 60); ctx.scale(1, sq); ctx.translate(-c.x, -(CY + 60));
  catLoaf(c.x, CY + 60 + c.y, S, { t, lid: inSun ? 0.72 : glare ? 0.38 : 0.1, pupil: glare ? 9 : 14, gaze: glare ? [0, 0] : [0, 0], tilt: glare ? -0.1 : 0.06 * Math.sin(t) });
  ctx.restore();
  if (inSun) for (let i = 0; i < 3; i++) { const u = (t * 0.6 + i / 3) % 1; alpha(Math.sin(u * Math.PI), () => txt('z', c.x - 60 + u * 70 + i * 10, CY - 160 - u * 120, 36 + i * 10, '#5c4033', { weight: 900 })); }
  if (c.hop) at(c.x - 60, CY - 360, 1, 0, () => txt('*rutsch*', 0, 0, 44, INK, { stroke: 7, sc: WHITE, weight: 900 }));
  // Abend-Overlay
  if (dim > 0) alpha(dim * 0.5, () => { ctx.fillStyle = '#1b2350'; ctx.fillRect(0, 0, W, H); });
  if (glare) { at(c.x - 30, CY - 290, pop(t, EV.glare, 0.3), 0, () => emo('💢', 0, 0, 80)); }
  if (t >= EV.sunset + 0.3 && t < EV.again) at(540, 980, pop(t, EV.sunset + 0.3, 0.35), 0, () => pill('sonne: weg.', 0, 0, 44, WHITE, INK, { lw: 6 }));
  drangBadge(10);
  drangCaption(['der drang, dem sonnenfleck', 'hinterherzurutschen 😼']);
  shareBand(t, EV.band);
};
window.EP_SCENES = {};
