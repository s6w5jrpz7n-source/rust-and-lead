'use strict';
/* QUIZ – Gameshow-Format (10 Fragen, immer schwerer). Daten kommen aus script.py → EXPORT → TL.data.
   Bildtypen pro Frage: {type:'emoji', e}, {type:'flag', id}, {type:'shape', iso} (braucht shapes.js). Eigener renderFrame. */
const QD = TL.data;
const NQ = QD.questions.length;
const QB = 60 / 128;
const LEVELS = [['LEICHT', '#40c057'], ['LEICHT', '#40c057'], ['LEICHT', '#40c057'], ['MITTEL', '#fab005'], ['MITTEL', '#fab005'],
  ['MITTEL', '#fab005'], ['SCHWER', '#fd7e14'], ['SCHWER', '#fd7e14'], ['GENIE', '#fa5252'], ['GENIE', '#fa5252']];

function qIdx(t) { let k = 0; for (let i = 1; i <= NQ; i++) if (t >= T('q' + i) - 0.12) k = i; return k; }
function bp(t) { return Math.exp(-((t % QB) / QB) * 6); }
function wrapText(str, size, maxW, weight = 900) {
  ctx.save(); ctx.font = `${weight} ${size}px ${FONT}`;
  const words = str.split(' '), lines = []; let cur = '';
  for (const w of words) { const test = cur ? cur + ' ' + w : w; if (cur && ctx.measureText(test).width > maxW) { lines.push(cur); cur = w; } else cur = test; }
  if (cur) lines.push(cur);
  ctx.restore(); return lines;
}

/* ---------- Flaggen (vereinfachte, proportionsgetreue Zeichnungen) ---------- */
const FLAGS = {
  JPN: [2, 3, (w, h) => { ctx.fillStyle = WHITE; ctx.fillRect(0, 0, w, h); circ(w / 2, h / 2, h * 0.3); ctx.fillStyle = '#BC002D'; ctx.fill(); }],
  ITA: [2, 3, (w, h) => { ['#009246', '#FFFFFF', '#CE2B37'].forEach((c, i) => { ctx.fillStyle = c; ctx.fillRect(i * w / 3, 0, w / 3 + 1, h); }); }],
  CHE: [1, 1, (w, h) => { ctx.fillStyle = '#DA291C'; ctx.fillRect(0, 0, w, h); const u = w / 32; ctx.fillStyle = WHITE; ctx.fillRect(13 * u, 6 * u, 6 * u, 20 * u); ctx.fillRect(6 * u, 13 * u, 20 * u, 6 * u); }],
  SWE: [10, 16, (w, h) => { ctx.fillStyle = '#006AA7'; ctx.fillRect(0, 0, w, h); const u = w / 16; ctx.fillStyle = '#FECC02'; ctx.fillRect(5 * u, 0, 2 * u, h); ctx.fillRect(0, 4 * u, w, 2 * u); }],
  GRC: [2, 3, (w, h) => {
    const s = h / 9;
    for (let i = 0; i < 9; i++) { ctx.fillStyle = i % 2 ? WHITE : '#0D5EAF'; ctx.fillRect(0, i * s, w, s + 1); }
    ctx.fillStyle = '#0D5EAF'; ctx.fillRect(0, 0, 5 * s, 5 * s);
    ctx.fillStyle = WHITE; ctx.fillRect(2 * s, 0, s, 5 * s); ctx.fillRect(0, 2 * s, 5 * s, s);
  }],
  COL: [2, 3, (w, h) => { ctx.fillStyle = '#FCD116'; ctx.fillRect(0, 0, w, h / 2); ctx.fillStyle = '#003893'; ctx.fillRect(0, h / 2, w, h / 4); ctx.fillStyle = '#CE1126'; ctx.fillRect(0, h * 0.75, w, h / 4 + 1); }],
  BGD: [3, 5, (w, h) => { ctx.fillStyle = '#006A4E'; ctx.fillRect(0, 0, w, h); circ(w * 0.45, h / 2, w / 5); ctx.fillStyle = '#F42A41'; ctx.fill(); }],
  SYC: [1, 2, (w, h) => {
    const tri = (pts, c) => { P(); ctx.moveTo(0, h); for (const [x, y] of pts) ctx.lineTo(x, y); ctx.closePath(); ctx.fillStyle = c; ctx.fill(); };
    tri([[0, 0], [w / 3, 0]], '#003F87'); tri([[w / 3, 0], [2 * w / 3, 0]], '#FCD856'); tri([[2 * w / 3, 0], [w, 0], [w, h / 3]], '#D62828');
    tri([[w, h / 3], [w, 2 * h / 3]], '#FFFFFF'); tri([[w, 2 * h / 3], [w, h]], '#007A3D');
  }],
  MCO: [4, 5, (w, h) => { ctx.fillStyle = '#CE1126'; ctx.fillRect(0, 0, w, h / 2); ctx.fillStyle = WHITE; ctx.fillRect(0, h / 2, w, h / 2); }],
  IDN: [2, 3, (w, h) => { ctx.fillStyle = '#CE1126'; ctx.fillRect(0, 0, w, h / 2); ctx.fillStyle = WHITE; ctx.fillRect(0, h / 2, w, h / 2); }],
};
function starShape(cx, cy, n, r1, r2, rot = 0) {
  P(); for (let i = 0; i < n * 2; i++) { const a = rot + (i * Math.PI) / n, r = i % 2 ? r2 : r1; const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); } ctx.closePath();
}
function drawNepal(cx, cy, size) {
  const w = size * 0.82, h = size, x0 = cx - w / 2, y0 = cy - h / 2;
  const pts = [[0, 0], [1, 0.47], [0.36, 0.47], [1, 1], [0, 1]].map(([x, y]) => [x0 + x * w, y0 + y * h]);
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,0.45)'; ctx.shadowBlur = 30; ctx.shadowOffsetY = 12;
  P(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath();
  ctx.fillStyle = '#DC143C'; ctx.fill(); ctx.shadowColor = 'transparent'; ctx.lineWidth = size * 0.045; ctx.strokeStyle = '#003893'; ctx.lineJoin = 'miter'; ctx.stroke();
  ctx.restore();
  const mx = x0 + w * 0.27, my = y0 + h * 0.3;
  ctx.fillStyle = WHITE; starShape(mx, my + h * 0.02, 8, h * 0.07, h * 0.04, Math.PI / 8); ctx.fill();
  P(); ctx.arc(mx, my - h * 0.03, h * 0.09, 0.1 * Math.PI, 0.9 * Math.PI); ctx.lineWidth = h * 0.03; ctx.strokeStyle = WHITE; ctx.stroke();
  starShape(x0 + w * 0.27, y0 + h * 0.78, 12, h * 0.11, h * 0.07); ctx.fillStyle = WHITE; ctx.fill();
}
function drawFlag(id, cx, cy, maxW, maxH) {
  if (id === 'NPL') { drawNepal(cx, cy, Math.min(maxH, maxW / 0.82)); return; }
  const [rh, rw, fn] = FLAGS[id];
  const k = Math.min(maxW / rw, maxH / rh), w = rw * k, h = rh * k, x0 = cx - w / 2, y0 = cy - h / 2;
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,0.5)'; ctx.shadowBlur = 34; ctx.shadowOffsetY = 14;
  ctx.fillStyle = '#000'; ctx.fillRect(x0, y0, w, h); ctx.restore();
  ctx.save(); ctx.translate(x0, y0); ctx.beginPath(); ctx.rect(0, 0, w, h); ctx.clip(); fn(w, h);
  const sh = ctx.createLinearGradient(0, 0, w, h); sh.addColorStop(0, 'rgba(255,255,255,0.12)'); sh.addColorStop(0.5, 'rgba(0,0,0,0)'); sh.addColorStop(1, 'rgba(0,0,0,0.1)');
  ctx.fillStyle = sh; ctx.fillRect(0, 0, w, h); ctx.restore();
  ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(255,255,255,0.5)'; ctx.strokeRect(x0, y0, w, h);
}
function drawEmoji(e, cx, cy, size, t) {
  const bob = Math.sin(t * 3) * 8;
  ctx.save(); ctx.font = `${size}px "Noto Color Emoji", sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.shadowColor = 'rgba(0,0,0,0.45)'; ctx.shadowBlur = 30; ctx.shadowOffsetY = 12;
  ctx.fillText(e, cx, cy + bob); ctx.restore();
}

/* ---------- Bausteine ---------- */
function qbg2(t, hot) {
  const c = hot ? QD.hot : QD.theme;
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, c[0]); g.addColorStop(1, c[1]);
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rays(540, 760, '#ffffff', 0.05 + 0.03 * bp(t), t * 0.25, 20);
  if (QD.stars) { ctx.save(); for (let i = 0; i < 90; i++) { ctx.globalAlpha = 0.3 + 0.7 * Math.abs(Math.sin(t * 1.5 + i)); circ(rnd(i) * W, rnd(i + 50) * H, 1 + rnd(i + 9) * 2.5); ctx.fillStyle = WHITE; ctx.fill(); } ctx.restore(); }
  dots(t, '#9775fa', 0.22, 61);
}
function qheader(t) {
  at(540, 255, 1 + 0.015 * bp(t), 0, () => txt(QD.title, 0, 0, 96, YELLOW, { stroke: 16, maxW: 980 }));
  txt(QD.sub, 540, 335, 36, WHITE, { weight: 800, stroke: 8 });
}
function qdots(t, k, rev) {
  for (let i = 1; i <= NQ; i++) {
    const x = 120 + (i - 1) * 93, y = 410, done = i < k || (i === k && rev), cur = i === k && !rev;
    circ(x, y, cur ? 26 + 4 * bp(t) : 20); fs(done ? '#40c057' : cur ? YELLOW : '#343a63', 5, done || cur ? INK : '#4c5490');
    txt(String(i), x, y + 2, cur ? 26 : 22, done || cur ? INK : '#8e96d6', { weight: 900 });
  }
  if (k > 0) { const [lab, col] = LEVELS[k - 1]; at(540, 478, pop(t, T('q' + k) - 0.12, 0.3), 0, () => pill('SCHWIERIGKEIT: ' + lab, 0, 0, 30, col, INK, { lw: 5 })); }
}
function qcard(t, k, slide) {
  const Qn = QD.questions[k - 1], q = L['q' + k], a = L['a' + k];
  const rev = t >= a.start - 0.05;
  ctx.save(); ctx.translate(slide * W, 0);
  rr(50, 520, 980, 590, 40); ctx.fillStyle = 'rgba(255,255,255,0.08)'; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = 'rgba(255,255,255,0.25)'; ctx.stroke();
  txt(`FRAGE ${k}/${NQ}`, 100, 565, 30, '#b197fc', { align: 'left', weight: 900 });
  const lines = wrapText(Qn.text, 60, 860);
  const ty = lines.length > 1 ? 625 : 640;
  at(540, ty, pop(t, q.start - 0.1, 0.35), 0, () => lines.forEach((ln, i) => txt(ln, 0, i * 70, 60, WHITE, { stroke: 12, maxW: 900 })));
  const vy = lines.length > 1 ? 925 : 900, vh = lines.length > 1 ? 280 : 320;
  const vp = pop(t, q.start, 0.45);
  const v = Qn.visual;
  at(540, vy, vp, 0, () => {
    if (v.type === 'flag') drawFlag(v.id, 0, 0, 560, vh);
    else if (v.type === 'emoji') drawEmoji(v.e, 0, 0, vh * 0.85, t);
  });
  if (rev && v.type === 'flag' && v.id === 'MCO') {
    const p = pop(t, a.start + 0.6, 0.4);
    at(860, 1010, p, 0.06, () => { drawFlag('IDN', 0, 0, 150, 100); txt('Indonesien 2:3', 0, 76, 24, WHITE, { stroke: 6, weight: 800 }); });
    at(220, 1010, p, -0.06, () => txt('Monaco 4:5', 0, 0, 28, WHITE, { stroke: 7, weight: 900 }));
  }
  const c0 = q.end + 0.05, c1 = a.start - 0.05;
  if (t >= c0 && t < c1 + 0.05) {
    const p = clamp((t - c0) / (c1 - c0)), n = Math.max(1, 3 - Math.floor(p * 3));
    at(930, 580, 1 + 0.15 * Math.exp(-(((t - c0) % ((c1 - c0) / 3)) * 10)), 0, () => { circ(0, 0, 50); fs(n === 1 ? RED : YELLOW, 6, INK); txt(String(n), 0, 3, 56, INK); });
    rr(110, 1440, 860, 22, 11); ctx.fillStyle = 'rgba(255,255,255,0.15)'; ctx.fill();
    rr(110, 1440, Math.max(22, 860 * (1 - p)), 22, 11); ctx.fillStyle = p < 0.5 ? '#40c057' : p < 0.8 ? YELLOW : RED; ctx.fill();
  }
  Qn.opts.forEach((o, i) => {
    const y = 1140 + i * 96, isR = i === Qn.right;
    let bg = WHITE, fg = INK, sc = 1;
    if (rev) { if (isR) { bg = '#40c057'; fg = WHITE; sc = 1 + 0.06 * Math.sin(prog(t, a.start - 0.05, 0.25) * Math.PI); } else { bg = '#5c2b3a'; fg = '#ff8fa3'; } }
    at(540, y + 38, pop(t, q.start + 0.05 + i * 0.07, 0.3) * sc, 0, () => {
      rr(-420, -38, 840, 76, 38); fs(bg, 6, INK);
      circ(-372, 0, 28); fs(rev && isR ? WHITE : '#7048e8', 0);
      txt('ABC'[i], -372, 2, 32, rev && isR ? '#2b8a3e' : WHITE, { weight: 900 });
      txt(o, 10, 2, 46, fg, { weight: 900, maxW: 640 });
      if (rev && isR) { P(); ctx.moveTo(338, 0); ctx.lineTo(356, 18); ctx.lineTo(388, -18); ctx.lineWidth = 10; ctx.strokeStyle = WHITE; ctx.lineCap = 'round'; ctx.stroke(); }
      if (rev && !isR) { seg(340, -16, 376, 16, 8, '#ff8fa3'); seg(376, -16, 340, 16, 8, '#ff8fa3'); }
    });
  });
  ctx.restore();
  if (k === NQ) confetti(t, a.start, 540, 900, 110);
}
function qbanner(t, id, text, col) {
  const l = L[id]; const qn = 'q' + id.slice(1); if (!l || t < l.start - 0.1 || t > T(qn) + 0.5) return;
  alpha(fade(t, l.start - 0.1, 0.15) * (1 - fade(t, T(qn) + 0.2, 0.25)), () => {
    ctx.fillStyle = col; at(540, 960, 1, -0.06, () => { ctx.fillRect(-700, -110, 1400, 220); txt(text, 0, 4, 92, WHITE, { stroke: 14, maxW: 1000 }); });
  });
}
function qintro(t) {
  alpha(1 - eIn(prog(t, T('q1') - 0.32, 0.22)), () => {
    at(540, 760, 1.04 - 0.04 * eOut(prog(t, 0, 0.8)) + 0.03 * bp(t), 0, () => {
      txt('10 FRAGEN', 0, -120, 150, WHITE, { stroke: 18 });
      txt('IMMER SCHWERER', 0, 30, 104, '#ff8787', { stroke: 16, maxW: 980 });
    });
    at(540, 1060, pop(t, C('genie') - 0.1, 0.4), -0.05, () => { rr(-400, -80, 800, 160, 30); fs(YELLOW, 8); txt('10/10 = GENIE', 0, 4, 96, INK); });
  });
}
function qoutro(t) {
  const t0 = C('outro');
  alpha(fade(t, t0 - 0.2, 0.3), () => {
    ctx.fillStyle = 'rgba(10,5,30,0.82)'; ctx.fillRect(0, 0, W, H);
    at(540, 560, pop(t, t0 - 0.1, 0.4), 0, () => txt('Wie viele hattest du?', 0, 0, 82, WHITE, { stroke: 12, maxW: 980 }));
    const cols = ['#868e96', '#40c057', '#fd7e14', '#fa5252'];
    QD.ratings.forEach(([r, n], i) => at(540, 730 + i * 120, pop(t, t0 + 0.2 + i * 0.18, 0.35), 0, () => {
      rr(-380, -48, 760, 96, 48); fs(cols[i], 6, INK); txt(r, -270, 3, 52, WHITE, { stroke: 8 }); txt(n, 90, 3, 56, WHITE, { stroke: 8, maxW: 480 });
    }));
    at(540, 1260, pop(t, t0 + 1.2, 0.4), 0, () => txt('Schreib’s in die Kommentare', 0, 0, 50, YELLOW, { stroke: 10, weight: 900 }));
  });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const k = qIdx(t);
  qbg2(t, k >= 8);
  qheader(t);
  if (k === 0) qintro(t);
  else if (t < C('outro') + 0.2) {
    qdots(t, k, t >= L['a' + k].start - 0.05);
    const sl = 1 - eOut(prog(t, T('q' + k) - 0.12, 0.3));
    if (k > 1 && sl > 0) { ctx.save(); ctx.globalAlpha = sl; ctx.translate(-(1 - sl) * W, 0); qcard(t, k - 1, 0); ctx.restore(); }
    qcard(t, k, sl);
  }
  qbanner(t, 'h8', 'JETZT WIRD’S SCHWER', 'rgba(232,89,12,0.95)');
  qbanner(t, 'h10', 'LETZTE FRAGE – NUR FÜR GENIES', 'rgba(201,42,42,0.95)');
  if (t >= C('outro') - 0.2) qoutro(t);
};
window.EP_SCENES = {};
