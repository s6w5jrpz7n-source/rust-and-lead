'use strict';
/* DAY 1 vs. LATER – Unser Weihnachtsbaum. Eigener renderFrame, Daten aus build.py (TL.data). */
const BD = TL.data, ST = BD.stages;
const STATE = [ // Gesundheit, Hängen, Lichter an, Kugeln dran, Stern, Nadeln am Boden, Lametta, Ostern, Geschenke, Katze
  { h: 1.0, droop: 0.0, lights: 1.0, orn: 16, star: 'ok', floor: 0, tinsel: 0.3, easter: false, gifts: 0, cat: 'sit' },
  { h: 0.9, droop: 0.1, lights: 1.0, orn: 13, star: 'ok', floor: 40, tinsel: 0.35, easter: false, gifts: 0, cat: 'tree' },
  { h: 0.75, droop: 0.3, lights: 0.85, orn: 12, star: 'tilt', floor: 120, tinsel: 0.4, easter: false, gifts: 4, cat: 'gift' },
  { h: 0.4, droop: 0.55, lights: 0.6, orn: 9, star: 'tilt', floor: 260, tinsel: 1.0, easter: false, gifts: 0, cat: 'scared' },
  { h: 0.12, droop: 0.8, lights: 0.4, orn: 4, star: 'fallen', floor: 420, tinsel: 0.7, easter: false, gifts: 0, cat: 'sleep' },
  { h: 0.0, droop: 0.9, lights: 0.0, orn: 0, star: 'none', floor: 480, tinsel: 0.2, easter: true, gifts: 0, cat: 'bunny' },
];
function stageAt(t) { let k = 0; ST.forEach((s, i) => { if (t >= s.t0) k = i; }); return k; }

/* ---------- Raum ---------- */
function windowView(k, t, x, y, w, h) {
  ctx.save(); rr(x, y, w, h, 8); ctx.clip();
  if (k <= 3) {
    const g = ctx.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#0b1d3a'); g.addColorStop(1, '#27406b'); ctx.fillStyle = g; ctx.fillRect(x, y, w, h);
    circ(x + w * 0.72, y + h * 0.22, 26); ctx.fillStyle = '#fff6d6'; ctx.fill();
    ctx.fillStyle = '#e9f1ff'; ctx.fillRect(x, y + h - 50, w, 50);
    if (k < 3) for (let i = 0; i < 40; i++) { const sx = x + rnd(i) * w + Math.sin(t + i) * 8, sy = y + ((rnd(i + 7) * h + t * (30 + rnd(i) * 30)) % h); circ(sx, sy, 2 + rnd(i + 3) * 3); ctx.fillStyle = WHITE; ctx.fill(); }
    if (k === 3) for (let b = 0; b < 3; b++) {
      const ph = ((t * 0.9 + b * 0.37) % 1), bx = x + w * (0.25 + 0.25 * b), by = y + h * (0.25 + 0.1 * (b % 2)), r = ph * 90;
      const col = ['#ff6b6b', '#ffd43b', '#74c0fc'][b];
      for (let i = 0; i < 14; i++) { const a = (i / 14) * Math.PI * 2; circ(bx + Math.cos(a) * r, by + Math.sin(a) * r, 4 * (1 - ph) + 1); ctx.fillStyle = col; ctx.globalAlpha = 1 - ph; ctx.fill(); }
      ctx.globalAlpha = 1;
    }
  } else if (k === 4) {
    ctx.fillStyle = '#7d8590'; ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = 'rgba(220,230,240,0.6)'; ctx.lineWidth = 2;
    for (let i = 0; i < 40; i++) { const sx = x + rnd(i) * w, sy = y + ((rnd(i + 5) * h + t * 600) % h); ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(sx - 6, sy + 24); ctx.stroke(); }
  } else {
    const g = ctx.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#74c0fc'); g.addColorStop(1, '#d0ebff'); ctx.fillStyle = g; ctx.fillRect(x, y, w, h);
    circ(x + w * 0.75, y + h * 0.25, 40); ctx.fillStyle = '#ffd43b'; ctx.fill();
    ctx.fillStyle = '#8ce99a'; ctx.fillRect(x, y + h - 60, w, 60);
    for (let i = 0; i < 6; i++) { const fx = x + 20 + i * (w - 40) / 5; seg(fx, y + h - 20, fx, y + h - 60, 4, '#2f9e44'); circ(fx, y + h - 66, 12); ctx.fillStyle = ['#ff8787', '#ffd43b', '#da77f2'][i % 3]; ctx.fill(); }
  }
  ctx.restore();
  rr(x, y, w, h, 8); fs(null, 14, '#e9dcc3'); seg(x + w / 2, y, x + w / 2, y + h, 10, '#e9dcc3'); seg(x, y + h / 2, x + w, y + h / 2, 10, '#e9dcc3');
  rr(x - 20, y + h, w + 40, 26, 6); fs('#e9dcc3', 4, '#bfae8e');
}
function room(k, t) {
  const wall = ['#c96b4b', '#c96b4b', '#b85f43', '#8f5a4a', '#8a8279', '#d6c9a0'][k];
  ctx.fillStyle = wall; ctx.fillRect(0, 0, W, H);
  ctx.save(); ctx.globalAlpha = 0.08; for (let x = 0; x < W; x += 60) { ctx.fillStyle = '#000'; ctx.fillRect(x, 0, 22, 1300); } ctx.restore();
  windowView(k, t, 70, 520, 300, 380);
  ctx.fillStyle = '#8b5a3c'; ctx.fillRect(0, 1290, W, 700);
  for (let x = -40; x < W; x += 150) seg(x, 1290, x + 60, 1920, 4, '#6f452d');
  seg(0, 1290, W, 1290, 8, '#5c3a26');
  at(860, 640, 1, 0.03, () => { rr(-80, -100, 160, 200, 6); fs('#f8f9fa', 6, '#5c3a26'); ctx.fillStyle = '#e03131'; ctx.fillRect(-80, -100, 160, 46); txt(['DEZ', 'DEZ', 'DEZ', 'DEZ', 'FEB', 'APR'][k], 0, -76, 30, WHITE); txt(['1', '12', '24', '31', '20', '5'][k], 0, 20, 80, INK); });
}

/* ---------- Baum ---------- */
const ORN = Array.from({ length: 16 }, (_, i) => ({ fx: rnd(i * 3 + 1) * 2 - 1, fy: 0.12 + 0.8 * rnd(i * 5 + 2), c: ['#e03131', '#fcc419', '#4dabf7', '#e64980'][i % 4] }));
function tierPath(cx, yb, yt, hw, droop, jag) {
  P(); ctx.moveTo(cx, yt);
  const n = 8;
  ctx.lineTo(cx + hw, yb + droop * 40);
  for (let i = n; i >= -n; i--) { const u = i / n; ctx.lineTo(cx + hw * u, yb + droop * 40 * Math.abs(u) + (i % 2 ? -jag : 0)); }
  ctx.closePath();
}
function drawTree(cx, by, k, t) {
  const s = STATE[k], H0 = 700, top = by - H0;
  ctx.fillStyle = '#6b4226'; ctx.fillRect(cx - 22, by - 90, 44, 100);
  rr(cx - 90, by - 20, 180, 60, 14); fs('#c92a2a', 7, '#5c1a1a'); seg(cx - 90, by, cx + 90, by, 6, '#fcc419');
  const tiers = [[by - 60, by - 300, 290], [by - 230, by - 450, 230], [by - 380, by - 580, 170], [by - 520, top, 110]];
  // Äste (sichtbar, wenn kahl)
  const bare = 1 - s.h;
  if (bare > 0.2) {
    ctx.save(); ctx.globalAlpha = Math.min(1, bare * 1.4);
    seg(cx, by - 80, cx, top, 16, '#6b4226');
    for (let i = 0; i < 9; i++) { const y = by - 110 - i * 64, hw = 280 - i * 28; for (const sd of [-1, 1]) { P(); ctx.moveTo(cx, y); ctx.quadraticCurveTo(cx + sd * hw * 0.5, y - 10, cx + sd * hw, y + s.droop * 60); ctx.lineWidth = 7 - i * 0.5; ctx.strokeStyle = '#6b4226'; ctx.lineCap = 'round'; ctx.stroke(); } }
    ctx.restore();
  }
  if (s.h > 0.02) {
    const col = s.h > 0.6 ? ['#2b8a3e', '#237032'] : s.h > 0.3 ? ['#5c7a29', '#4a6321'] : ['#8a7a3a', '#6f6230'];
    ctx.save(); ctx.globalAlpha = Math.min(1, s.h * 1.2);
    tiers.forEach(([yb, yt, hw], i) => {
      tierPath(cx, yb, yt, hw, s.droop * (1 - i * 0.2), 18); ctx.fillStyle = col[0]; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = '#173d1f'; ctx.stroke();
      tierPath(cx + hw * 0.25, yb - 8, yt + 40, hw * 0.55, s.droop * 0.5, 10); ctx.fillStyle = col[1]; ctx.fill();
    });
    ctx.restore();
    if (s.h < 0.95) { ctx.save(); ctx.fillStyle = '#6b4226'; for (let i = 0; i < 120 * (1 - s.h); i++) { const y = by - 80 - rnd(i * 7) * (H0 - 120); const hw = 290 * (1 - (by - y) / H0); circ(cx + (rnd(i * 11) * 2 - 1) * hw * 0.8, y, 3); ctx.fill(); } ctx.restore(); }
  }
  // Lametta
  if (s.tinsel > 0) { ctx.save(); ctx.strokeStyle = 'rgba(230,236,245,0.9)'; ctx.lineWidth = 2; const n = Math.floor(60 * s.tinsel); for (let i = 0; i < n; i++) { const y = by - 100 - rnd(i * 13) * (H0 - 160), hw = 280 * (1 - (by - y) / H0), x = cx + (rnd(i * 17) * 2 - 1) * hw * 0.85; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + Math.sin(t * 2 + i) * 3, y + 40 + rnd(i) * 30); ctx.stroke(); } ctx.restore(); }
  // Lichterkette
  for (let r = 0; r < 4; r++) {
    const y0 = by - 140 - r * 140, hw = 250 - r * 52;
    P(); for (let i = 0; i <= 20; i++) { const u = i / 20, x = cx - hw + u * 2 * hw, y = y0 - u * 60 + Math.sin(u * Math.PI) * 30 + s.droop * 30; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
    ctx.lineWidth = 3; ctx.strokeStyle = '#2b2b2b'; ctx.stroke();
    for (let i = 1; i < 20; i += 2) {
      const u = i / 20, x = cx - hw + u * 2 * hw, y = y0 - u * 60 + Math.sin(u * Math.PI) * 30 + s.droop * 30 + 8;
      const on = rnd(r * 31 + i) < s.lights && !(s.lights < 1 && Math.sin(t * 7 + i * 3) > 0.6 && rnd(i + r) > 0.5);
      const c = ['#ffd43b', '#ff6b6b', '#74c0fc', '#8ce99a'][(i + r) % 4];
      ctx.save(); if (on) { ctx.shadowColor = c; ctx.shadowBlur = 18; } ell(x, y, 7, 10); ctx.fillStyle = on ? c : '#495057'; ctx.fill(); ctx.restore();
    }
  }
  // Kugeln
  ORN.forEach((o, i) => {
    if (i >= s.orn) return;
    const y = top + 80 + o.fy * (H0 - 160), hw = 270 * ((y - top) / H0), x = cx + o.fx * hw * 0.75, yy = y + s.droop * 30 * Math.abs(o.fx);
    seg(x, yy - 26, x, yy - 14, 3, '#adb5bd'); circ(x, yy, 18); fs(o.c, 4, '#2b2b2b'); circ(x - 6, yy - 6, 5); ctx.fillStyle = 'rgba(255,255,255,0.7)'; ctx.fill();
  });
  // Ostereier
  if (s.easter) for (let i = 0; i < 9; i++) {
    const y = top + 120 + rnd(i * 3 + 9) * (H0 - 220), hw = 260 * ((y - top) / H0), x = cx + (rnd(i * 5 + 4) * 2 - 1) * hw * 0.8;
    seg(x, y - 30, x, y - 18, 3, '#adb5bd');
    at(x, y + Math.sin(t * 3 + i) * 3, 1, Math.sin(t * 2 + i) * 0.1, () => { ell(0, 0, 16, 22); fs(['#ffa8a8', '#ffe066', '#a5d8ff', '#b2f2bb', '#d0bfff'][i % 5], 4, '#2b2b2b'); seg(-14, 0, 14, 0, 4, WHITE); });
  }
  // Spitze
  if (s.star === 'ok' || s.star === 'tilt') at(cx + (s.star === 'tilt' ? 14 : 0), top - 10, 1, s.star === 'tilt' ? 0.45 : 0, () => { ctx.save(); ctx.shadowColor = '#ffd43b'; ctx.shadowBlur = 30; starShape(0, 0, 5, 50, 22, -Math.PI / 2); fs('#ffd43b', 5, '#e67700'); ctx.restore(); });
  if (s.easter) at(cx, top - 20, 1, 0, () => { ell(-14, -50, 10, 34, -0.2); fs('#f8f9fa', 4); ell(14, -50, 10, 34, 0.2); fs('#f8f9fa', 4); circ(0, 0, 32); fs('#f8f9fa', 4); circ(-10, -4, 4); ctx.fillStyle = INK; ctx.fill(); circ(10, -4, 4); ctx.fill(); circ(0, 8, 5); ctx.fillStyle = '#ff8fa3'; ctx.fill(); });
}
function starShape(cx, cy, n, r1, r2, rot) { P(); for (let i = 0; i < n * 2; i++) { const a = rot + (i * Math.PI) / n, r = i % 2 ? r2 : r1; const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); } ctx.closePath(); }
function floorStuff(cx, by, k, t) {
  const s = STATE[k];
  ctx.save();
  for (let i = 0; i < s.floor; i++) { const x = cx + (rnd(i * 3) * 2 - 1) * (200 + rnd(i) * 240), y = by + 10 + rnd(i * 7) * 170; ctx.strokeStyle = k >= 4 ? '#8a7a3a' : '#2f6b34'; ctx.lineWidth = 3; ctx.beginPath(); const a = rnd(i * 5) * 6; ctx.moveTo(x, y); ctx.lineTo(x + Math.cos(a) * 14, y + Math.sin(a) * 6); ctx.stroke(); }
  ctx.restore();
  if (s.star === 'fallen') at(cx + 230, by + 90, 1, 2.6, () => { starShape(0, 0, 5, 40, 18, 0); fs('#c9a227', 5, '#7a5c00'); });
  if (k === 4) for (let i = 0; i < 6; i++) at(cx - 240 + i * 90, by + 120 + (i % 2) * 30, 1, 0, () => { circ(0, 0, 16); fs(ORN[i].c, 4, '#2b2b2b'); });
  if (s.gifts) [[-170, 0, '#e03131'], [150, 10, '#1c7ed6'], [-40, 40, '#2f9e44'], [260, 50, '#ae3ec9']].forEach(([dx, dy, c], i) => at(cx + dx, by + 40 + dy, 1, 0, () => {
    rr(-60, -70, 120, 80, 6); fs(c, 6, '#2b2b2b'); ctx.fillStyle = '#ffd43b'; ctx.fillRect(-10, -70, 20, 80); ctx.fillRect(-60, -38, 120, 14);
  }));
  if (k === 3) { at(cx - 260, by + 90, 1, 0.3, () => { P(); ctx.moveTo(0, 0); ctx.lineTo(70, -20); ctx.lineTo(70, 20); ctx.closePath(); fs('#4dabf7', 4); }); }
  if (k === 4) at(cx + 40, by - 260, 1, 0.08, () => { rr(-90, -60, 180, 120, 4); fs('#ffe066', 4, '#c99700'); txt('RAUS', 0, -20, 34, INK); txt('BRINGEN!', 0, 22, 30, INK); });
}
function cat(cx, by, k, t) {
  const mode = STATE[k].cat;
  const body = (x, y, s, o = {}) => at(x, y, s, o.rot || 0, () => {
    ell(0, 0, 70, o.flat ? 34 : 56); fs('#f08c00', 6, '#5c3a00');
    if (!o.flat) { P(); ctx.moveTo(60, 10); ctx.quadraticCurveTo(130, -10 - (o.puff ? 40 : 0), 110, -80); ctx.lineWidth = o.puff ? 30 : 16; ctx.strokeStyle = '#f08c00'; ctx.lineCap = 'round'; ctx.stroke(); }
    circ(-40, -60, 46); fs('#f08c00', 6, '#5c3a00');
    for (const sd of [-1, 1]) { P(); ctx.moveTo(-40 + sd * 18, -96); ctx.lineTo(-40 + sd * 40, -126); ctx.lineTo(-40 + sd * 42, -84); ctx.closePath(); fs('#f08c00', 5, '#5c3a00'); }
    if (o.sleep) { seg(-58, -62, -46, -62, 4, INK); seg(-34, -62, -22, -62, 4, INK); }
    else for (const sd of [-1, 1]) { ell(-40 + sd * 16, -62, o.puff ? 12 : 9, o.puff ? 14 : 12); fs('#d3f9d8', 3, INK); circ(-40 + sd * 16, -62, o.puff ? 3 : 5); ctx.fillStyle = INK; ctx.fill(); }
    if (o.bunny) { ell(-56, -130, 10, 34, -0.2); fs('#f8f9fa', 4); ell(-24, -130, 10, 34, 0.2); fs('#f8f9fa', 4); }
  });
  if (mode === 'sit') body(cx - 300, by + 120, 0.9);
  if (mode === 'tree') { at(cx + 60, by - 330 + Math.sin(t * 3) * 6, 1, 0, () => { for (const sd of [-1, 1]) { ell(sd * 18, 0, 12, 14); fs('#d3f9d8', 3, INK); circ(sd * 18, 0, 5); ctx.fillStyle = INK; ctx.fill(); } }); body(cx + 330, by + 150, 0.5, { sleep: true, flat: true }); }
  if (mode === 'gift') body(cx - 40, by - 30, 0.75);
  if (mode === 'scared') body(cx + 300, by + 130, 0.8, { puff: true, rot: Math.sin(t * 40) * 0.03 });
  if (mode === 'sleep') { body(cx - 280, by + 140, 0.85, { sleep: true, flat: true }); txt('z', cx - 240 + Math.sin(t * 2) * 6, by + 40 - ((t * 30) % 40), 40, WHITE, { stroke: 6 }); }
  if (mode === 'bunny') body(cx - 300, by + 120, 0.9, { bunny: true });
}

/* ---------- Text ---------- */
function tikCaption(str, y, a) {
  const lines = (() => { ctx.save(); ctx.font = `800 46px ${FONT}`; const ws = str.split(' '), out = []; let c = ''; for (const w of ws) { const tst = c ? c + ' ' + w : w; if (c && ctx.measureText(tst).width > 820) { out.push(c); c = w; } else c = tst; } out.push(c); ctx.restore(); return out; })();
  alpha(a, () => lines.forEach((ln, i) => {
    ctx.save(); ctx.font = `800 46px ${FONT}`; const w = ctx.measureText(ln).width + 44; ctx.restore();
    rr(540 - w / 2, y + i * 66 - 32, w, 64, 14); ctx.fillStyle = WHITE; ctx.fill();
    txt(ln, 540, y + i * 66 + 2, 46, INK, { weight: 800 });
  }));
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const k = stageAt(t), s = ST[k];
  const lt = t - s.t0;
  const z = 1 + 0.04 * Math.exp(-lt * 5);
  ctx.save(); ctx.translate(540, 960); ctx.scale(z, z); ctx.translate(-540, -960);
  room(k, t);
  const cx = 560, by = 1300;
  drawTree(cx, by, k, t);
  floorStuff(cx, by, k, t);
  cat(cx, by, k, t);
  ctx.restore();
  if (lt < 0.09 && k > 0) { ctx.fillStyle = `rgba(255,255,255,${0.8 * (1 - lt / 0.09)})`; ctx.fillRect(0, 0, W, H); }
  // Etikett (Format: "Day 1 vs. later")
  at(540, 290, k === 0 ? 1 : pop(t, s.t0, 0.3), 0, () => {
    txt(s.label, 0, 0, 140, WHITE, { stroke: 20, maxW: 980 });
    pill(s.sub, 0, 104, 36, k >= 3 ? '#e03131' : '#2b8a3e', WHITE, { lw: 5 });
  });
  if (t < 1.8) alpha(1 - fade(t, 1.5, 0.3), () => txt('Unser Weihnachtsbaum, jedes Jahr:', 540, 470, 46, WHITE, { stroke: 10, weight: 900, maxW: 980 }));
  tikCaption(s.cap, 1450, fade(t, s.t0 + 0.35, 0.2));
  if (t >= BD.end) {
    const a = fade(t, BD.end, 0.25);
    alpha(a, () => { ctx.fillStyle = 'rgba(10,10,20,0.78)'; ctx.fillRect(0, 0, W, H); });
    at(540, 820, pop(t, BD.end + 0.1, 0.4), -0.04, () => { txt('Wie lange', 0, -80, 130, WHITE, { stroke: 18 }); txt('steht eurer?', 0, 60, 130, '#ffd43b', { stroke: 18, maxW: 980 }); });
    at(540, 1060, pop(t, BD.end + 0.5, 0.4), 0, () => txt('Rekord in die Kommentare', 0, 0, 52, WHITE, { stroke: 10, weight: 900 }));
  }
};
window.EP_SCENES = {};
