'use strict';
/* Gemeinsame Katze für die Serie „der drang, …“ (orange Tigerkatze). Lädt nach engine.js. */
const CAT = { fur: '#f4a259', dark: '#d9772b', light: '#ffd8a8', belly: '#fff4e6', line: '#5c2e0e', nose: '#ff8fab', eye1: '#e9f78a', eye2: '#7fb53a' };

/* Kopf (Ursprung = Kopfmitte). o: gaze [x,y], pupil (Breite 8–40), lid (0–1), tilt, flick, shine (Nacht-Leuchten), mouth ('w'|'o'|'meow') */
function catHead(x, y, s, o = {}) {
  const [gx, gy] = o.gaze || [0, 0], pw = o.pupil ?? 10, ld = o.lid || 0, fl = o.flick || 0;
  ctx.save(); ctx.translate(x, y); ctx.rotate(o.tilt || 0); ctx.scale(s, s);
  for (const sd of [-1, 1]) at(sd * 120, -120, 1, sd * (0.05 + (sd > 0 ? fl * 0.25 : 0)), () => {
    P(); ctx.moveTo(-sd * 70, 30); ctx.lineTo(sd * 10, -130); ctx.lineTo(sd * 70, 40); ctx.closePath(); fs(CAT.fur, 6, CAT.line);
    P(); ctx.moveTo(-sd * 40, 20); ctx.lineTo(sd * 6, -90); ctx.lineTo(sd * 44, 26); ctx.closePath(); ctx.fillStyle = '#ffc9d6'; ctx.fill();
  });
  P(); ctx.ellipse(0, 0, 210, 182, 0, 0, Math.PI * 2);
  const hg = ctx.createRadialGradient(-40, -60, 30, 0, 0, 230); hg.addColorStop(0, CAT.light); hg.addColorStop(0.5, CAT.fur); hg.addColorStop(1, '#e8893f');
  ctx.fillStyle = hg; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = CAT.line; ctx.stroke();
  for (const sd of [-1, 1]) { P(); ctx.moveTo(sd * 180, -20); for (let i = 0; i < 4; i++) ctx.lineTo(sd * (232 - (i % 2) * 22), 20 + i * 26); ctx.lineTo(sd * 150, 120); ctx.closePath(); ctx.fillStyle = CAT.fur; ctx.fill(); }
  for (const dx of [-36, 0, 36]) { P(); ctx.moveTo(dx, -172); ctx.quadraticCurveTo(dx * 1.2, -130, dx * 0.9, -100); ctx.lineWidth = 12; ctx.strokeStyle = CAT.dark; ctx.lineCap = 'round'; ctx.stroke(); }
  for (const sd of [-1, 1]) { ell(sd * 120, 70, 34, 18); ctx.fillStyle = 'rgba(255,140,160,0.35)'; ctx.fill(); }
  for (const sd of [-1, 1]) {
    const ex = sd * 80, ey = -20;
    ctx.save(); ell(ex, ey, 56, 50, sd * -0.12); ctx.clip();
    const eg = ctx.createRadialGradient(ex, ey, 6, ex, ey, 60); eg.addColorStop(0, CAT.eye1); eg.addColorStop(1, CAT.eye2); ctx.fillStyle = eg; ctx.fillRect(ex - 60, ey - 60, 120, 120);
    ell(ex + gx * 16, ey + gy * 12, pw / 2, 40); ctx.fillStyle = '#1a1a1a'; ctx.fill();
    if (o.shine) { ell(ex + gx * 16, ey + gy * 12, pw / 2 - 2, 36); ctx.fillStyle = 'rgba(190,255,120,0.35)'; ctx.fill(); }
    circ(ex + gx * 16 - 14, ey + gy * 12 - 16, 10); ctx.fillStyle = WHITE; ctx.fill(); circ(ex + gx * 16 + 12, ey + gy * 12 + 14, 5); ctx.fill();
    if (ld > 0) { ctx.fillStyle = CAT.fur; ctx.fillRect(ex - 60, ey - 60, 120, 110 * ld); seg(ex - 56, ey - 60 + 110 * ld, ex + 56, ey - 60 + 110 * ld, 6, CAT.line); }
    ctx.restore();
    ell(ex, ey, 56, 50, sd * -0.12); fs(null, 6, CAT.line);
    if (o.shine) { ctx.save(); ctx.shadowColor = '#c0ff60'; ctx.shadowBlur = 40; ell(ex, ey, 50, 44, sd * -0.12); ctx.strokeStyle = 'rgba(200,255,120,0.5)'; ctx.lineWidth = 3; ctx.stroke(); ctx.restore(); }
  }
  for (const sd of [-1, 1]) { ell(sd * 34, 74, 50, 38); ctx.fillStyle = CAT.belly; ctx.fill(); }
  ell(0, 110, 40, 24); ctx.fillStyle = CAT.belly; ctx.fill();
  P(); ctx.moveTo(-20, 40); ctx.lineTo(20, 40); ctx.quadraticCurveTo(22, 46, 4, 62); ctx.lineTo(-4, 62); ctx.quadraticCurveTo(-22, 46, -20, 40); ctx.closePath(); fs(CAT.nose, 4, CAT.line);
  if (o.mouth === 'meow' || o.mouth === 'o') { const h = o.mouth === 'meow' ? 34 : 18; ell(0, 92 + h * 0.3, 22, h * 0.6); fs('#7a1f2b', 5, CAT.line); ell(0, 92 + h * 0.6, 12, h * 0.25); ctx.fillStyle = '#ff8fab'; ctx.fill(); }
  else { P(); ctx.moveTo(0, 62); ctx.lineTo(0, 74); ctx.arc(-16, 74, 16, 0, Math.PI * 0.85); fs(null, 5, CAT.line); P(); ctx.arc(16, 74, 16, Math.PI * 0.15, Math.PI); fs(null, 5, CAT.line); }
  for (const sd of [-1, 1]) for (let i = 0; i < 3; i++) { P(); ctx.moveTo(sd * 70, 70 + i * 14); ctx.quadraticCurveTo(sd * 170, 50 + i * 22, sd * 260, 40 + i * 34); ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(255,255,255,0.95)'; ctx.stroke(); }
  ctx.restore();
}
/* Sitzende Katze (Ursprung = Mitte unten). o: alles von catHead + pawL/pawR [x,y] lokal, tail (+1/−1 Seite), tailWag, sx/sy (Quetschen), head (false = ohne Kopf) */
function catSit(x, y, s, o = {}) {
  const t = o.t || 0, side = o.tail ?? -1, sx = o.sx || 1, sy = o.sy || 1;
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  const tf = Math.sin(t * 2.2) * 0.15 + (o.tailWag || 0);
  P(); ctx.moveTo(side * 150 * sx, -40 * sy); ctx.bezierCurveTo(side * 330 * sx, -40 * sy, side * 330 * sx, -160 * sy, side * (290 + tf * 80) * sx, -300 * sy);
  ctx.lineWidth = 64; ctx.strokeStyle = CAT.line; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 52; ctx.strokeStyle = CAT.fur; ctx.stroke();
  ctx.save(); ctx.scale(sx, sy * (1 + 0.01 * Math.sin(t * 3)));
  P(); ctx.moveTo(-130, -400); ctx.bezierCurveTo(-210, -300, -230, -60, -175, 0); ctx.lineTo(175, 0); ctx.bezierCurveTo(230, -60, 210, -300, 130, -400); ctx.closePath();
  const bg2 = ctx.createLinearGradient(0, -420, 0, 0); bg2.addColorStop(0, CAT.fur); bg2.addColorStop(1, '#e8893f'); ctx.fillStyle = bg2; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = CAT.line; ctx.stroke();
  for (const sd of [-1, 1]) for (let i = 0; i < 3; i++) { P(); ctx.arc(sd * 150, -250 + i * 70, 50, sd > 0 ? Math.PI * 0.6 : Math.PI * 0.1, sd > 0 ? Math.PI * 0.9 : Math.PI * 0.4); ctx.lineWidth = 12; ctx.strokeStyle = CAT.dark; ctx.stroke(); }
  P(); ctx.moveTo(-90, -360); for (let i = 0; i <= 8; i++) ctx.lineTo(-90 + i * 22.5, -330 - (i % 2) * 26); ctx.lineTo(80, -120); ctx.quadraticCurveTo(0, -60, -80, -120); ctx.closePath(); ctx.fillStyle = CAT.belly; ctx.fill();
  ctx.restore();
  const paw = (px, py, arm) => {
    if (arm) limb(arm[0], arm[1], px, py - 10, 58, CAT.fur);
    ell(px, py, 50, 32); fs(CAT.belly, 5, CAT.line); for (const dx of [-18, 0, 18]) seg(px + dx, py + 10, px + dx, py - 4, 3, '#d9b38c');
  };
  const pl = o.pawL || [-70 * sx, -14], pr = o.pawR || [70 * sx, -14];
  paw(pl[0], pl[1], o.pawL ? [-110 * sx, -320 * sy] : null);
  paw(pr[0], pr[1], o.pawR ? [110 * sx, -320 * sy] : null);
  ctx.restore();
  if (o.head !== false) catHead(x, y - 540 * s * sy, s, o);
}
/* Laufende Katze, Seitenansicht (Ursprung = Bodenpunkt unter dem Bauch). dir +1 nach rechts. */
function catRun(x, y, s, ph, dir = 1, o = {}) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s * dir, s);
  const st = Math.sin(ph * Math.PI * 2), ct = Math.cos(ph * Math.PI * 2);
  const by = -150 - Math.abs(st) * 30;
  P(); ctx.moveTo(-170, by - 10); if (o.tailUp) { const w = Math.sin((o.t || 0) * 3) * 14; ctx.bezierCurveTo(-250, by - 120, -200, by - 300, -215 + w, by - 430); ctx.quadraticCurveTo(-205 + w, by - 500, -150 + w, by - 480); } else ctx.quadraticCurveTo(-300, by - 60 - ct * 30, -360, by - 140 - st * 40); ctx.lineWidth = 46; ctx.strokeStyle = CAT.line; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 34; ctx.strokeStyle = CAT.fur; ctx.stroke();
  const legs = [[-120, 1], [-90, -1], [110, -1], [140, 1]];
  for (const [lx, sg] of legs) { const a = sg * st * 0.8; limb(lx, by + 30, lx + Math.sin(a) * 110, by + 30 + Math.cos(a) * 110, 30, CAT.fur); ell(lx + Math.sin(a) * 120, by + 30 + Math.cos(a) * 118, 26, 14); fs(CAT.belly, 4, CAT.line); }
  ell(0, by, 200 + st * 20, 82); fs(CAT.fur, 6, CAT.line);
  for (let i = 0; i < 4; i++) { P(); ctx.arc(-80 + i * 50, by - 70, 36, Math.PI * 0.2, Math.PI * 0.8); ctx.lineWidth = 10; ctx.strokeStyle = CAT.dark; ctx.stroke(); }
  const hx = 210, hy = by - 60 + ct * 8;
  for (const ex of [-30, 30]) { P(); ctx.moveTo(hx + ex - 30, hy - 60); ctx.lineTo(hx + ex, hy - 150); ctx.lineTo(hx + ex + 30, hy - 50); ctx.closePath(); fs(CAT.fur, 5, CAT.line); }
  circ(hx, hy, 92); fs(CAT.fur, 6, CAT.line);
  ell(hx + 60, hy + 30, 44, 32); ctx.fillStyle = CAT.belly; ctx.fill(); circ(hx + 92, hy + 12, 10); ctx.fillStyle = CAT.nose; ctx.fill();
  ell(hx + 34, hy - 18, 26, 28); fs(CAT.eye1, 4, CAT.line); ell(hx + 40, hy - 18, 14, 22); ctx.fillStyle = '#111'; ctx.fill(); circ(hx + 34, hy - 26, 6); ctx.fillStyle = WHITE; ctx.fill();
  for (let i = 0; i < 3; i++) seg(hx + 70, hy + 24 + i * 10, hx + 170, hy + 10 + i * 18, 3, WHITE);
  ctx.restore();
  if (o.lines) for (let i = 0; i < 6; i++) { const ly = y - 260 + i * 40; seg(x - dir * (260 + i * 30), ly, x - dir * (460 + i * 30 + rnd(i) * 80), ly, 6, 'rgba(255,255,255,0.45)'); }
}
/* Liegende Katze (Brot-Pose) von vorn-schräg; Ursprung = Mitte unten. */
function catLoaf(x, y, s, o = {}) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  P(); ctx.moveTo(220, -40); ctx.bezierCurveTo(360, -40, 380, 40, 300, 60); ctx.lineWidth = 52; ctx.strokeStyle = CAT.line; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 40; ctx.strokeStyle = CAT.fur; ctx.stroke();
  P(); ctx.ellipse(40, -120, 300, 150, 0, 0, Math.PI * 2); const g = ctx.createLinearGradient(0, -270, 0, 30); g.addColorStop(0, CAT.fur); g.addColorStop(1, '#e8893f'); ctx.fillStyle = g; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = CAT.line; ctx.stroke();
  for (let i = 0; i < 4; i++) { P(); ctx.arc(60 + i * 60, -230, 50, Math.PI * 0.3, Math.PI * 0.7); ctx.lineWidth = 12; ctx.strokeStyle = CAT.dark; ctx.stroke(); }
  ell(-150, 10, 54, 26); fs(CAT.belly, 5, CAT.line); ell(-40, 16, 54, 26); fs(CAT.belly, 5, CAT.line);
  ctx.restore();
  catHead(x - 200 * s, y - 230 * s, s * 0.85, o);
}
/* Bildunterschrift im TikTok-Stil, klein geschrieben */
function drangCaption(lines) {
  lines.forEach((ln, i) => {
    ctx.save(); ctx.font = `800 62px ${FONT}, "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.lineWidth = 12; ctx.strokeStyle = '#000'; ctx.lineJoin = 'round'; ctx.strokeText(ln, 540, 250 + i * 78);
    ctx.fillStyle = WHITE; ctx.fillText(ln, 540, 250 + i * 78); ctx.restore();
  });
}
function kk(t, a, b) { return eIO(prog(t, a, b - a)); }
function blinkLid(t, t0) { if (t < t0) return 0; const u = prog(t, t0, 0.9); return u < 0.4 ? eIO(u / 0.4) : lerp(1, 0.45, eIO(clamp((u - 0.4) / 0.6))); }

/* ---------- Ergänzungen: Rückansicht, Bauchlage, Serienelemente ---------- */
/* Katze von hinten (Ursprung = Mitte unten); o.tailUp 0..1 */
function catBack(x, y, s, o = {}) {
  const t = o.t || 0;
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  P(); ctx.moveTo(-130, -400); ctx.bezierCurveTo(-210, -300, -230, -60, -175, 0); ctx.lineTo(175, 0); ctx.bezierCurveTo(230, -60, 210, -300, 130, -400); ctx.closePath(); fs(CAT.fur, 6, CAT.line);
  for (let i = 0; i < 4; i++) { P(); ctx.arc(0, -320 + i * 80, 150 - i * 6, Math.PI * 0.15, Math.PI * 0.85); ctx.lineWidth = 14; ctx.strokeStyle = CAT.dark; ctx.stroke(); }
  const sw = Math.sin(t * 3) * 30;
  P(); ctx.moveTo(0, -40); ctx.bezierCurveTo(10, -200, sw, -360, 20 + sw, -520); ctx.lineWidth = 64; ctx.strokeStyle = CAT.line; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 52; ctx.strokeStyle = CAT.fur; ctx.stroke();
  for (const sd of [-1, 1]) { P(); ctx.moveTo(sd * 70, -600); ctx.lineTo(sd * 130, -760); ctx.lineTo(sd * 180, -590); ctx.closePath(); fs(CAT.fur, 6, CAT.line); }
  ell(0, -560, 205, 170); fs(CAT.fur, 6, CAT.line);
  for (const dx of [-50, 0, 50]) { P(); ctx.moveTo(dx, -720); ctx.quadraticCurveTo(dx * 1.1, -640, dx * 0.9, -580); ctx.lineWidth = 14; ctx.strokeStyle = CAT.dark; ctx.lineCap = 'round'; ctx.stroke(); }
  ctx.restore();
}
/* Katze auf dem Rücken, Bauch nach oben (Ursprung = Mitte unten) */
function catBelly(x, y, s, o = {}) {
  const t = o.t || 0;
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  P(); ctx.moveTo(280, -60); ctx.quadraticCurveTo(420, -40, 430, -160); ctx.lineWidth = 52; ctx.strokeStyle = CAT.line; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 40; ctx.strokeStyle = CAT.fur; ctx.stroke();
  for (const [lx, ly, a] of [[-140, -150, -0.4], [-40, -170, 0.2], [130, -150, -0.3], [230, -130, 0.4]]) { const w = Math.sin(t * 4 + lx) * 0.15; limb(lx, ly + 40, lx + Math.sin(a + w) * 110, ly - Math.cos(a + w) * 110, 40, CAT.fur); ell(lx + Math.sin(a + w) * 120, ly - Math.cos(a + w) * 120, 30, 22); fs(CAT.belly, 4, CAT.line); }
  ell(60, -70, 280, 120); fs(CAT.fur, 6, CAT.line);
  ell(60, -95, 200, 80); ctx.fillStyle = CAT.belly; ctx.fill();
  ctx.restore();
  catHead(x - 260 * s, y - 110 * s, s * 0.8, Object.assign({ tilt: -1.2 }, o));
}
function emo(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
function drangBadge(n) { pill(`der drang #${n}`, 540, 168, 30, '#f08c00', WHITE, { lw: 0 }); }
function shareBand(t, t0, text = 'schick das jemandem, dessen katze das auch macht 😼') {
  if (t < t0) return;
  const a = eOut(prog(t, t0, 0.25));
  alpha(a, () => {
    ctx.save(); ctx.font = `800 40px ${FONT}, "Noto Color Emoji"`; const w = Math.min(1000, ctx.measureText(text).width + 60); ctx.restore();
    at(540, 1480 + (1 - a) * 40, 1, 0, () => { rr(-w / 2, -42, w, 84, 42); ctx.fillStyle = 'rgba(255,255,255,0.95)'; ctx.fill();
      ctx.save(); ctx.font = `800 40px ${FONT}, "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = INK; ctx.fillText(text, 0, 3); ctx.restore(); });
  });
}
