'use strict';
/* Die Rettungsflitzer – Baukasten: freundliche Autos (Seitenansicht), Räderstadt, Matsch, Wasser. Lädt nach engine.js. */
const OUTL = '#1d2340';
const GROUND = 1160;
function emo(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
function camA(fx, fy, z, fn) { ctx.save(); ctx.translate(540, 960); ctx.scale(z, z); ctx.translate(-fx, -fy); fn(); ctx.restore(); }

/* ---------- Welt ---------- */
function world(t, o = {}) {
  const g = ctx.createLinearGradient(0, 0, 0, GROUND); g.addColorStop(0, '#74c0fc'); g.addColorStop(1, '#d0ebff'); ctx.fillStyle = g; ctx.fillRect(-600, -800, W + 1200, GROUND + 800);
  // Sonne mit Gesicht
  at(880, 470, 1, 0, () => { ctx.save(); ctx.rotate(t * 0.3); for (let i = 0; i < 12; i++) { ctx.rotate(Math.PI / 6); P(); ctx.moveTo(90, -12); ctx.lineTo(140, 0); ctx.lineTo(90, 12); ctx.closePath(); fs('#ffd43b', 0); } ctx.restore(); circ(0, 0, 80); fs('#ffe066', 6, '#f59f00'); circ(-26, -12, 8); fs(OUTL, 0); circ(26, -12, 8); fs(OUTL, 0); P(); ctx.arc(0, 8, 30, 0.2, Math.PI - 0.2); fs(null, 6, OUTL); });
  for (let i = 0; i < 4; i++) { const x = ((i * 300 + t * 20) % 1500) - 200, y = 420 + (i % 2) * 120; at(x, y, 1, 0, () => { for (const [dx, r] of [[-50, 40], [0, 60], [55, 45]]) { circ(dx, 0, r); fs('#fff', 0); } }); }
  if (o.rainbow > 0) alpha(o.rainbow, () => { const cols = ['#ff6b6b', '#ffa94d', '#ffe066', '#69db7c', '#4dabf7', '#9775fa']; cols.forEach((c, i) => { P(); ctx.arc(540, 1000, 560 - i * 34, Math.PI, 0); ctx.lineWidth = 34; ctx.strokeStyle = c; ctx.stroke(); }); });
  // Hügel
  for (const [x, r, c] of [[-350, 400, '#69db7c'], [150, 380, '#8ce99a'], [620, 460, '#69db7c'], [1050, 400, '#8ce99a'], [1500, 420, '#69db7c']]) { circ(x, GROUND + 140, r); fs(c, 0); }
  for (const x of [120, 380, 820, 980]) { rr(x - 12, GROUND - 180, 24, 90, 6); fs('#a0522d', 4, OUTL); circ(x, GROUND - 200, 56); fs('#40c057', 5, OUTL); }
  // Straße
  ctx.fillStyle = '#868e96'; ctx.fillRect(-600, GROUND - 60, W + 1200, 170); seg(-600, GROUND - 60, W + 600, GROUND - 60, 6, '#495057');
  for (let x = -600 + ((o.scroll || 0) % 160); x < W + 600; x += 160) { rr(x, GROUND + 22, 80, 12, 6); ctx.fillStyle = '#f8f9fa'; ctx.fill(); }
  ctx.fillStyle = '#51cf66'; ctx.fillRect(-600, GROUND + 110, W + 1200, H); for (let i = 0; i < 30; i++) { const x = rnd(i) * W, y = GROUND + 150 + rnd(i + 5) * 600; seg(x, y, x - 6, y - 16, 4, '#40c057'); seg(x, y, x + 6, y - 16, 4, '#40c057'); }
  for (const p of (o.puddles || [])) { ell(p, GROUND + 50, 90, 16); fs('#4dabf7', 4, '#1c7ed6'); }
}
function mudPit(x, a = 1, soft = 0) {
  alpha(a, () => { ell(x, GROUND + 40, 230, 46); fs(soft > 0.5 ? '#a9744f' : '#7a4a24', 6, '#4a2c14'); for (let i = 0; i < 6; i++) { circ(x - 160 + i * 64, GROUND + 30 + (i % 2) * 14, 12 + (i % 3) * 4); ctx.fillStyle = soft > 0.5 ? 'rgba(165,216,255,0.6)' : '#5c3317'; ctx.fill(); } });
}
function splash(x, y, t, t0, col = '#4dabf7', n = 10, sp = 260) {
  const u = prog(t, t0, 0.6); if (u <= 0 || u >= 1) return;
  for (let i = 0; i < n; i++) { const a = -Math.PI * (0.15 + 0.7 * rnd(i + t0)), v = sp * (0.6 + 0.4 * rnd(i * 3 + t0)); circ(x + Math.cos(a) * v * u, y + Math.sin(a) * v * u + 400 * u * u, 10 * (1 - u) + 4); ctx.fillStyle = col; ctx.fill(); }
}
function sparkles(t, x, y, r) { for (let i = 0; i < 6; i++) { const a = t * 2 + i, u = (t * 1.5 + i / 6) % 1; alpha(Math.sin(u * Math.PI), () => emo('✨', x + Math.cos(a) * r, y + Math.sin(a * 1.3) * r * 0.5, 44)); } }

/* ---------- Autos ----------
   car(x, y, s, o): Ursprung = Boden unter Wagenmitte; o.type 'mini' | 'tow' | 'fire'; o.dir (1 = nach rechts);
   o.t, o.spin (Radumdrehung), o.mouth (0..1), o.mood ('happy'|'sad'|'worried'|'strain'|'surprised'|'proud'), o.look (-1..1),
   o.mud (0..1), o.lights (Blaulicht/Rundumleuchte an), o.sink (Räder im Matsch), o.bounce */
function wheel(x, y, r, spin, sink) {
  circ(x, y, r); fs('#343a40', 6, OUTL); circ(x, y, r * 0.55); fs('#ced4da', 5, OUTL);
  ctx.save(); ctx.translate(x, y); ctx.rotate(spin); for (let i = 0; i < 4; i++) { ctx.rotate(Math.PI / 2); seg(0, 0, r * 0.5, 0, 5, '#868e96'); } ctx.restore();
}
function eyes(cx, cy, r, o) {
  const t = o.t || 0, look = o.look ?? 0.6, mood = o.mood || 'happy';
  const blink = ((t + (o.blinkOff || 0)) % 3.4) > 3.27;
  for (const dx of [-r * 0.95, r * 0.95]) {
    const ex = cx + dx, big = mood === 'surprised' ? 1.15 : 1;
    ell(ex, cy, r * 0.82 * big, r * big); fs('#fff', 6, OUTL);
    if (blink || mood === 'strain') { seg(ex - r * 0.6, cy + (mood === 'strain' ? 0 : 4), ex + r * 0.6, cy + (mood === 'strain' ? 0 : 4), 7, OUTL); }
    else { circ(ex + look * r * 0.32, cy + r * 0.1, r * 0.42); fs(OUTL, 0); circ(ex + look * r * 0.32 - r * 0.14, cy - r * 0.12, r * 0.14); fs('#fff', 0); }
    // Brauen
    const by = cy - r * 1.25;
    if (mood === 'worried' || mood === 'sad') seg(ex - r * 0.5, by + (dx < 0 ? -10 : 8), ex + r * 0.5, by + (dx < 0 ? 8 : -10), 7, OUTL);
    else if (mood === 'strain') seg(ex - r * 0.5, by + (dx < 0 ? 10 : -6), ex + r * 0.5, by + (dx < 0 ? -6 : 10), 7, OUTL);
    else if (mood === 'surprised') seg(ex - r * 0.5, by - 12, ex + r * 0.5, by - 12, 7, OUTL);
    else { P(); ctx.arc(ex, by + 20, r * 0.55, Math.PI * 1.2, Math.PI * 1.8); fs(null, 7, OUTL); }
  }
}
function mouthA(x, y, w, o) {
  const m = o.mouth || 0, mood = o.mood || 'happy';
  if (m > 0.08) { ell(x, y + 6, w * (0.5 + 0.25 * m), 6 + 22 * m); fs('#c92a2a', 5, OUTL); ell(x, y + 10 + 12 * m, w * 0.3, 4 + 6 * m); ctx.fillStyle = '#ff8787'; ctx.fill(); }
  else if (mood === 'sad' || mood === 'worried') { P(); ctx.arc(x, y + 22, w * 0.45, Math.PI * 1.2, Math.PI * 1.8); fs(null, 7, OUTL); }
  else if (mood === 'strain') { rr(x - w * 0.5, y - 4, w, 18, 6); fs('#fff', 5, OUTL); seg(x - w * 0.5, y + 5, x + w * 0.5, y + 5, 3, OUTL); }
  else if (mood === 'surprised') { ell(x, y + 6, w * 0.25, 16); fs('#c92a2a', 5, OUTL); }
  else { P(); ctx.arc(x, y - 10, w * 0.5, Math.PI * 0.2, Math.PI * 0.8); fs(null, 7, OUTL); }
}
function car(x, y, s, o = {}) {
  const t = o.t || 0, type = o.type || 'mini', dir = o.dir || 1, spin = o.spin || 0, sink = o.sink || 0;
  const bob = (o.bounce ?? 1) * (Math.sin(t * 9) * 3 + (o.mouth || 0) * 6);
  ctx.save(); ctx.translate(x, y); ctx.scale(s * dir, s);
  const bodyPath = () => {
    P();
    if (type === 'mini') { ctx.roundRect(-210, -160, 420, 110, 46); ctx.roundRect(-140, -270, 260, 140, 70); }
    else if (type === 'tow') { ctx.roundRect(110, -320, 200, 250, 40); ctx.roundRect(-320, -150, 450, 80, 18); }
    else { ctx.roundRect(150, -320, 200, 250, 40); ctx.roundRect(-350, -270, 510, 200, 24); }
  };
  ctx.translate(0, bob);
  const col = o.color || { mini: '#22b8cf', tow: '#ff922b', fire: '#e03131' }[type];
  // Kran (Abschleppwagen) hinter der Karosserie
  if (type === 'tow') { seg(-250, -150, -330, -330, 22, OUTL); seg(-250, -150, -330, -330, 14, '#ffd43b'); if (!o.noHook) { seg(-330, -330, -360, o.hookY ?? -150, 5, OUTL); P(); ctx.arc(-360, (o.hookY ?? -150) + 18, 18, -Math.PI * 0.2, Math.PI * 1.1); fs(null, 8, '#495057'); } }
  bodyPath(); fs(col, 7, OUTL);
  // Schlamm
  if (o.mud > 0) { ctx.save(); bodyPath(); ctx.clip(); alpha(o.mud, () => { ctx.fillStyle = '#7a4a24'; ctx.fillRect(-400, -150, 800, 200); for (let i = 0; i < 9; i++) { circ(-200 + i * 50, -150 + (i % 3) * 10, 24); ctx.fill(); ell(-180 + i * 48, -110 + (i % 2) * 20, 10, 18); ctx.fill(); } }); ctx.restore(); }
  // Details je Typ
  let ex, ey, er, mx, my;
  if (type === 'mini') {
    rr(-110, -250, 90, 90, 30); fs('#e7f5ff', 6, OUTL);
    rr(-5, -255, 110, 105, 40); fs('#e7f5ff', 6, OUTL);
    ex = 52; ey = -205; er = 26; mx = 168; my = -98;
    circ(196, -128, 16); fs('#fff3bf', 5, OUTL); rr(-214, -120, 30, 22, 8); fs('#ff6b6b', 4, OUTL);
  } else if (type === 'tow') {
    rr(150, -290, 130, 120, 26); fs('#e7f5ff', 6, OUTL);
    ex = 215; ey = -232; er = 26; mx = 270; my = -120;
    rr(160, -350, 90, 30, 10); fs(o.lights && Math.sin(t * 14) > 0 ? '#ffd43b' : '#f08c00', 5, OUTL);
    for (let i = 0; i < 4; i++) seg(-300 + i * 100, -150, -260 + i * 100, -70, 6, 'rgba(0,0,0,0.15)');
    txt('TONI', -90, -110, 40, '#fff', { stroke: 8, sc: OUTL });
  } else {
    rr(190, -290, 130, 120, 26); fs('#e7f5ff', 6, OUTL);
    ex = 255; ey = -232; er = 26; mx = 312; my = -120;
    ctx.fillStyle = '#fff'; ctx.fillRect(-345, -170, 500, 24);
    seg(-320, -300, 120, -300, 10, '#ced4da'); seg(-320, -330, 120, -330, 10, '#ced4da'); for (let i = 0; i < 9; i++) seg(-300 + i * 50, -300, -300 + i * 50, -330, 6, '#ced4da');
    circ(-250, -200, 40); fs('#ffd43b', 6, OUTL); circ(-250, -200, 16); fs('#e8590c', 0);
    const on = o.lights && Math.sin(t * 16) > 0;
    rr(190, -352, 50, 30, 10); fs(on ? '#4dabf7' : '#1864ab', 5, OUTL); rr(250, -352, 50, 30, 10); fs(!on && o.lights ? '#4dabf7' : '#1864ab', 5, OUTL);
    if (o.lights) { ctx.save(); ctx.shadowColor = '#4dabf7'; ctx.shadowBlur = 50; circ(on ? 215 : 275, -337, 20); ctx.fillStyle = 'rgba(77,171,247,0.8)'; ctx.fill(); ctx.restore(); }
    txt('112', -100, -220, 46, '#fff', { stroke: 8, sc: OUTL });
  }
  eyes(ex, ey, er, o);
  mouthA(mx, my, 60, o);
  // Räder
  const wy = -45 + sink * 40, wr = type === 'mini' ? 46 : 54;
  const wxs = type === 'mini' ? [-125, 125] : type === 'tow' ? [-230, -90, 220] : [-260, -110, 250];
  for (const wx of wxs) wheel(wx, wy, wr, spin, sink);
  ctx.restore();
}
function bubbleTalk(x, y, txtS, p) { at(x, y, p, 0, () => { const w = tw(txtS, 44, 900) + 60; rr(-w / 2, -44, w, 88, 40); fs('#fff', 6, OUTL); P(); ctx.moveTo(-20, 40); ctx.lineTo(-40, 80); ctx.lineTo(10, 42); ctx.closePath(); fs('#fff', 0); txt(txtS, 0, 2, 44, OUTL); }); }
function rope(x1, y1, x2, y2, tight) { P(); ctx.moveTo(x1, y1); ctx.quadraticCurveTo((x1 + x2) / 2, (y1 + y2) / 2 + (tight ? 0 : 50), x2, y2); ctx.lineWidth = 9; ctx.strokeStyle = '#495057'; ctx.stroke(); }
function seriesTitle(t, until, ep) {
  alpha(1 - fade(t, until, 0.3), () => at(540, 300, 1, -0.02, () => {
    rr(-430, -100, 860, 200, 40); fs('#ffd43b', 8, OUTL);
    txt('Die Rettungsflitzer', 0, -26, 72, OUTL, { maxW: 800 }); txt(ep, 0, 50, 40, '#c92a2a', { weight: 900, maxW: 780 });
  }));
}
