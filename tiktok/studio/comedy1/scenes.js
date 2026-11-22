'use strict';
/* COMEDY – Archivfilm 1950, ehrlich synchronisiert. Bilder aus build/comedy1/frames (film_cut.py). */
const EX = TL.data;
window.EP_NAMES = EX.names;
window.EP_CAPCOL = { N: '#ffd43b', V: '#8ce99a', S: '#74c0fc', T: '#ffa8a8', K: '#ffd8a8' };
const FY = 360, FH = 810;  // Filmfenster 1080×810
const IMG = {};
function frameImg(i) {
  if (IMG[i]) return IMG[i];
  IMG[i] = new Promise(res => { const im = new Image(); im.onload = () => res(im); im.onerror = () => res(null); im.src = `../build/comedy1/frames/f${String(i).padStart(5, '0')}.jpg`; });
  return IMG[i];
}
function lineAt(t) { let cur = TL.lines[0]; for (const l of TL.lines) if (t >= l.start - 0.15) cur = l; return cur; }
function emoji(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
window.renderFrame = async function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const fi = Math.min(Math.round(t * 30), Math.floor(TL.duration * 30) - 1);
  const im = await frameImg(fi);
  const l = lineAt(t), lt = t - (l.start - 0.15);
  // Hintergrund: unscharfes, abgedunkeltes Filmbild
  ctx.fillStyle = '#111'; ctx.fillRect(0, 0, W, H);
  if (im) { ctx.save(); ctx.filter = 'blur(28px) brightness(0.45)'; ctx.drawImage(im, -540, -100, 2160, 2120); ctx.restore(); }
  // Film mit Punch-in-Zoom und leichtem Bildstand-Wackeln
  const z = EX.zoom[l.id] ? 1 + (EX.zoom[l.id] - 1) * eOut(clamp(lt / 0.5)) : 1;
  const jx = Math.sin(t * 37) * 1.5, jy = Math.cos(t * 29) * 2;
  const shake = l.id === 'c11' ? Math.sin(t * 80) * 6 * Math.exp(-lt * 3) : 0;
  ctx.save(); ctx.beginPath(); ctx.rect(0, FY, W, FH); ctx.clip();
  if (im) { const w = W * z, h = FH * z; ctx.filter = `brightness(${1 + 0.06 * Math.sin(t * 23) * Math.sin(t * 7)}) contrast(1.08)`; ctx.drawImage(im, (W - w) / 2 + jx + shake, FY + (FH - h) / 2 + jy, w, h); ctx.filter = 'none'; }
  // Filmkorn, Kratzer, Staub
  const f = Math.floor(t * 30);
  for (let i = 0; i < 140; i++) { ctx.fillStyle = rnd(i + f * 13) > 0.5 ? 'rgba(255,255,255,0.10)' : 'rgba(0,0,0,0.14)'; ctx.fillRect(rnd(i * 7 + f) * W, FY + rnd(i * 3 + f * 5) * FH, 2, 2); }
  for (let i = 0; i < 2; i++) if (rnd(f * 3 + i) > 0.6) { const x = rnd(f + i * 17) * W; ctx.fillStyle = 'rgba(255,255,255,0.18)'; ctx.fillRect(x, FY, 2, FH); }
  if (rnd(f * 11) > 0.85) { circ(rnd(f * 5) * W, FY + rnd(f * 9) * FH, 3 + rnd(f) * 5); ctx.fillStyle = 'rgba(0,0,0,0.5)'; ctx.fill(); }
  const v = ctx.createRadialGradient(540, FY + FH / 2, 300, 540, FY + FH / 2, 760); v.addColorStop(0, 'rgba(0,0,0,0)'); v.addColorStop(1, 'rgba(0,0,0,0.55)'); ctx.fillStyle = v; ctx.fillRect(0, FY, W, FH);
  ctx.restore();
  // Rahmen
  ctx.fillStyle = '#000'; ctx.fillRect(0, FY - 6, W, 6); ctx.fillRect(0, FY + FH, W, 6);
  // Kopf: Titel
  pill('LEHRFILM 1950', 540, 170, 34, '#ffd43b', INK, { lw: 0 });
  txt('ehrlich synchronisiert', 540, 262, 70, WHITE, { stroke: 14 });
  // Sticker
  const st = EX.stickers[l.id];
  if (st && lt > 0.3) at(900, FY + 140, pop(t, l.start + 0.2, 0.4), 0.15 * Math.sin(t * 3), () => emoji(st, 0, 0, 120));
  if (l.id === 'c1' && t > (TL.cues.ang || 99)) at(540, FY + FH - 70, pop(t, TL.cues.ang, 0.35), -0.06, () => pill('ANGEBLICH.', 0, 0, 52, '#e03131', WHITE, { lw: 0 }));
  if (l.id === 'c11') at(540, FY + 90, pop(t, l.start, 0.3), 0, () => txt('…', 0, 0, 120, WHITE, { stroke: 12 }));
  if (l.id === 'c14') at(540, FY + FH / 2, pop(t, l.start, 0.4), 0, () => { rr(-430, -110, 860, 220, 30); ctx.fillStyle = 'rgba(0,0,0,0.75)'; ctx.fill(); txt('📲 ab in die', 0, -40, 60, WHITE); txt('Familiengruppe', 0, 40, 72, '#ffd43b'); });
  drawCaptions(t);
};
window.EP_SCENES = {};
