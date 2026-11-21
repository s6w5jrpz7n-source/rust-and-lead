'use strict';
/* KLARTEXT – Format „X, ehrlich übersetzt“ (dunkle Übersetzer-App, zynisch). Eigener renderFrame.
   Jede Folge setzt vorher window.KT (Texte, Farben, Outro-Widget) in <folge>/scenes.js. */
const KT = window.KT;
const BG0 = '#0b0b10', REAL_BG = '#15151c', ACC = '#ff3b30', GRAY = '#8e8e93', OFF = '#f5f5f7';
const CARD_HR = KT.cardBg, HR_BLUE = KT.cardInk;
const MONO = '"JetBrains Mono", monospace';
const NI = TL.lines.filter(l => /^i\d+$/.test(l.id)).length;
const BEAT = 60 / (KT.bpm || 98);
const CX0 = 50, CW = 940, TXT_X = 96, TXT_W = 840;

function setFont(size, weight = 900, font = FONT) { ctx.font = `${weight} ${size}px ${font}`; }
function mono(s, x, y, size, col, o = {}) {
  ctx.save(); setFont(size, o.weight || 700, MONO); ctx.textAlign = o.align || 'left'; ctx.textBaseline = 'middle';
  ctx.fillStyle = col; if (o.alpha !== undefined) ctx.globalAlpha *= o.alpha; ctx.fillText(s, x, y); ctx.restore();
}
function layoutWords(words, size, maxW, weight = 900) {
  ctx.save(); setFont(size, weight);
  const sp = ctx.measureText(' ').width;
  const lines = []; let cur = [], cw = 0;
  words.forEach((w, i) => {
    const clean = w.replace(/\*/g, ''), ww = ctx.measureText(clean).width;
    if (cur.length && cw + sp + ww > maxW) { lines.push({ items: cur, width: cw }); cur = []; cw = 0; }
    const x = cur.length ? cw + sp : 0;
    cur.push({ i, clean, hi: w.includes('*'), x, width: ww });
    cw = x + ww;
  });
  if (cur.length) lines.push({ items: cur, width: cw });
  ctx.restore();
  return lines;
}
function fitSize(words, start, maxW, maxLines) {
  let s = start;
  while (s > 40 && layoutWords(words, s, maxW).length > maxLines) s -= 4;
  return s;
}
function pillMono(s, x, y, size, bg, fg) {
  ctx.save(); setFont(size, 800, MONO);
  const w = ctx.measureText(s).width + size * 1.2, h = size * 1.7;
  rr(x, y - h / 2, w, h, h / 2); ctx.fillStyle = bg; ctx.fill(); ctx.restore();
  mono(s, x + size * 0.6, y + 1, size, fg, { weight: 800 });
  return w;
}

/* ---------- Hintergrund & Kopf ---------- */
function bgDark(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, '#101018'); g.addColorStop(1, BG0);
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const rg = ctx.createRadialGradient(540, 1700, 50, 540, 1700, 900);
  rg.addColorStop(0, 'rgba(255,59,48,0.13)'); rg.addColorStop(1, 'rgba(255,59,48,0)');
  ctx.fillStyle = rg; ctx.fillRect(0, 0, W, H);
  ctx.save(); ctx.globalAlpha = 0.045; ctx.strokeStyle = WHITE; ctx.lineWidth = 2;
  for (let x = 0; x <= W; x += 60) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke(); }
  for (let y = 0; y <= H; y += 60) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }
  ctx.restore();
  const f = Math.round(t * 30);
  ctx.save(); ctx.fillStyle = 'rgba(255,255,255,0.06)';
  for (let i = 0; i < 140; i++) ctx.fillRect(rnd(i * 7 + f * 131) * W, rnd(i * 13 + f * 71) * H, 3, 3);
  ctx.restore();
}
function itemIndex(t) { let k = 0; for (let i = 1; i <= NI; i++) if (t >= T('i' + i) - 0.02) k = i; return k; }
function header(t, a) {
  alpha(a, () => {
    ctx.save(); setFont(50, 900); ctx.textBaseline = 'middle'; ctx.fillStyle = OFF; ctx.fillText('KLARTEXT', CX0 + 10, 232);
    const w = ctx.measureText('KLARTEXT').width; ctx.restore();
    if ((t % BEAT) < BEAT * 0.55) { ctx.fillStyle = ACC; ctx.fillRect(CX0 + 22 + w, 208, 22, 48); }
    const k = itemIndex(t);
    mono(`${String(k).padStart(2, '0')}/${String(NI).padStart(2, '0')}`, CX0 + CW - 10, 232, 36, GRAY, { align: 'right' });
    const segW = (CW - 7 * 10) / NI;
    for (let i = 1; i <= NI; i++) {
      const x = CX0 + (i - 1) * (segW + 10);
      ctx.fillStyle = '#2a2a33'; ctx.fillRect(x, 282, segW, 8);
      let p = 0;
      if (t >= T('r' + i)) p = 1;
      else if (t >= T('i' + i)) p = 0.5 * prog(t, T('i' + i), E('i' + i) - T('i' + i));
      if (p > 0) { ctx.fillStyle = i === k ? ACC : OFF; ctx.fillRect(x, 282, segW * p, 8); }
    }
  });
}

/* ---------- Karten ---------- */
function drawTyped(line, t, x, y, size, col) {
  const words = line.tokens.map(k => k.t);
  const lines = layoutWords(words, size, TXT_W);
  const total = lines.reduce((a, l) => a + l.items.map(it => it.clean).join(' ').length + 1, -1);
  const dur = Math.max(0.3, (line.end - line.start) * 0.85);
  const n = Math.floor(total * clamp((t - line.start + 0.08) / dur));
  ctx.save(); setFont(size, 900); ctx.textBaseline = 'middle'; ctx.fillStyle = col;
  let used = 0, cx = x, cy = y;
  lines.forEach((ln, li) => {
    const str = ln.items.map(it => it.clean).join(' ');
    const take = clamp(n - used, 0, str.length), sub = str.slice(0, take);
    const yy = y + li * size * 1.14;
    ctx.fillText(sub, x, yy);
    if (take > 0 || li === 0) { cx = x + ctx.measureText(sub).width; cy = yy; }
    used += str.length + 1;
  });
  ctx.restore();
  if (n < total || (t * 2) % 1 < 0.5) { ctx.fillStyle = col; ctx.fillRect(cx + 6, cy - size * 0.42, 7, size * 0.84); }
}
function drawReveal(line, t, x, y, size, maxW, o = {}) {
  const words = line.tokens.map(k => k.t);
  const lines = layoutWords(words, size, maxW);
  lines.forEach((ln, li) => ln.items.forEach(it => {
    const tk = line.tokens[it.i];
    const p = prog(t, tk.s - 0.05, 0.12);
    if (p <= 0) return;
    const lx = o.center ? x - ln.width / 2 : x;
    const yy = y + li * size * 1.12 + (1 - eOut(p)) * 26;
    ctx.save(); ctx.globalAlpha *= p; setFont(size, 900); ctx.textBaseline = 'middle';
    if (it.hi) {
      const bp = eOut(prog(t, tk.s, 0.16));
      rr(lx + it.x - 12, yy - size * 0.6, (it.width + 24) * bp, size * 1.14, 12); ctx.fillStyle = ACC; ctx.fill();
      ctx.fillStyle = WHITE;
    } else ctx.fillStyle = o.col || OFF;
    ctx.fillText(it.clean, lx + it.x, yy);
    ctx.restore();
  }));
}
function swapIcon(x, y, rot, t) {
  const pulse = 1 + 0.05 * Math.exp(-(t % BEAT) * 10);
  at(x, y, pulse, rot, () => {
    circ(0, 0, 54); fs('#1f1f28', 5, '#3a3a46');
    for (const sd of [-1, 1]) {
      seg(sd * 14, -24 * sd, sd * 14, 24 * sd, 7, OFF);
      P(); ctx.moveTo(sd * 14, 32 * sd); ctx.lineTo(sd * 14 - 12, 18 * sd); ctx.lineTo(sd * 14 + 12, 18 * sd); ctx.closePath(); ctx.fillStyle = OFF; ctx.fill();
    }
  });
}
function hrCard(t, y0, k) {
  rr(CX0, y0, CW, 420, 40); ctx.fillStyle = CARD_HR; ctx.fill();
  pillMono(KT.cardLabel, TXT_X - 6, y0 + 52, 24, HR_BLUE, WHITE);
  mono(KT.cardLang, CX0 + CW - 40, y0 + 52, 26, KT.cardMute, { align: 'right' });
  mono(KT.meta, TXT_X, y0 + 364, 26, KT.cardMute);
  for (const [sx, sy, ph] of [[CX0 + CW - 60, y0 + 125, 0]]) {
    const s = 0.6 + 0.4 * Math.sin(t * 5 + ph);
    at(sx, sy, s, t, () => { P(); ctx.moveTo(0, -22); ctx.quadraticCurveTo(0, 0, 22, 0); ctx.quadraticCurveTo(0, 0, 0, 22); ctx.quadraticCurveTo(0, 0, -22, 0); ctx.quadraticCurveTo(0, 0, 0, -22); ctx.fillStyle = '#f6c90e'; ctx.fill(); });
  }
  ctx.save(); setFont(28, 800); const bw = ctx.measureText(KT.button).width + 60; ctx.restore();
  rr(CX0 + CW - 40 - bw, y0 + 334, bw, 60, 30); ctx.fillStyle = HR_BLUE; ctx.fill();
  txt(KT.button, CX0 + CW - 40 - bw / 2, y0 + 365, 28, WHITE, { weight: 800 });
  if (k === 0) { mono(KT.placeholderTop, TXT_X, y0 + 150, 36, KT.cardMute); return; }
  const line = L['i' + k];
  const words = line.tokens.map(tk => tk.t);
  const size = fitSize(words, 88, TXT_W, 2);
  const fadeNext = k < NI ? 1 - prog(t, T('i' + (k + 1)) - 0.14, 0.12) : 1;
  alpha(fadeNext, () => drawTyped(line, t, TXT_X, y0 + 168, size, HR_BLUE));
}
function realCard(t, y0, k) {
  const r = k ? L['r' + k] : null;
  const g = r ? prog(t, r.start - 0.02, 0.22) : 1;
  const glitch = r && g > 0 && g < 1;
  const f = Math.round(t * 30);
  const jx = glitch ? (rnd(f * 3.1) - 0.5) * 26 : 0, jy = glitch ? (rnd(f * 5.7) - 0.5) * 12 : 0;
  ctx.save(); ctx.translate(jx, jy);
  if (glitch) { ctx.shadowColor = ACC; ctx.shadowBlur = 40; }
  rr(CX0, y0, CW, 500, 40); ctx.fillStyle = REAL_BG; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = ACC; ctx.stroke();
  ctx.restore();
  ctx.save(); ctx.translate(jx, jy);
  pillMono('ÜBERSETZUNG', TXT_X - 6, y0 + 52, 24, ACC, WHITE);
  mono('Deutsch (ehrlich)', CX0 + CW - 40, y0 + 52, 26, GRAY, { align: 'right' });
  mono('Ehrlichkeit: 100 %', TXT_X, y0 + 474, 24, '#ff6b62');
  if (!r || t < r.start - 0.05) {
    const dots = '.'.repeat(1 + Math.floor((t * 3) % 3));
    mono(k ? 'Übersetze' + dots : KT.placeholderBottom + dots, TXT_X, y0 + 160, 40, '#5c5c66');
  } else {
    const words = r.tokens.map(tk => tk.t);
    const size = fitSize(words, 96, TXT_W, 3);
    const fadeNext = k < NI ? 1 - prog(t, T('i' + (k + 1)) - 0.14, 0.12) : 1;
    alpha(fadeNext, () => {
      if (glitch) {
        alpha(0.55, () => { ctx.save(); ctx.translate(-8, 0); drawReveal(r, t, TXT_X, y0 + 178, size, TXT_W, { col: '#00e5ff' }); ctx.restore(); });
        alpha(0.55, () => { ctx.save(); ctx.translate(8, 0); drawReveal(r, t, TXT_X, y0 + 178, size, TXT_W, { col: ACC }); ctx.restore(); });
      }
      drawReveal(r, t, TXT_X, y0 + 178, size, TXT_W);
    });
  }
  ctx.restore();
  if (glitch) for (let i = 0; i < 4; i++) {
    const by = y0 + rnd(f * 11 + i) * 500, bh = 6 + rnd(f * 17 + i) * 26;
    ctx.fillStyle = i % 2 ? 'rgba(0,229,255,0.35)' : 'rgba(255,59,48,0.45)';
    ctx.fillRect(CX0 + rnd(f * 23 + i) * 200, by, 300 + rnd(f * 29 + i) * 500, bh);
  }
}
function notification(t) {
  const n0 = C('notif');
  if (t < n0) return;
  const inP = eOut(prog(t, n0, 0.4)), outP = eIn(prog(t, T('o1') - 0.15, 0.3));
  const y = lerp(-200, 330, inP) - outP * 600;
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 40;
  rr(CX0, y, CW, 200, 36); ctx.fillStyle = 'rgba(40,40,50,0.97)'; ctx.fill(); ctx.restore();
  rr(CX0 + 30, y + 30, 96, 96, 24); ctx.fillStyle = ACC; ctx.fill();
  rr(CX0 + 50, y + 55, 56, 42, 6); fs(WHITE, 0);
  P(); ctx.moveTo(CX0 + 50, y + 58); ctx.lineTo(CX0 + 78, y + 80); ctx.lineTo(CX0 + 106, y + 58); ctx.lineWidth = 5; ctx.strokeStyle = ACC; ctx.stroke();
  txt(KT.notif.title, CX0 + 150, y + 52, 34, OFF, { align: 'left', weight: 800 });
  mono(KT.notif.time, CX0 + CW - 34, y + 52, 26, GRAY, { align: 'right' });
  KT.notif.lines.forEach((ln, i) => txt(ln, CX0 + 150, y + 105 + i * 43, 30, '#d1d1d6', { align: 'left', weight: 600, maxW: CW - 190 }));
}

/* ---------- Abschnitte ---------- */
function hook(t, deckIn) {
  const outP = eIn(prog(t, deckIn - 0.05, 0.35));
  const sc = lerp(1.05, 1, eOut(prog(t, 0, 2.0))) * (1 + outP * 0.4);
  alpha(1 - outP, () => at(540, 960, sc, 0, () => {
    txt(KT.hook[0], 0, -300, 190, OFF, { maxW: 980 });
    txt(KT.hook[1], 0, -120, 190, OFF, { maxW: 980 });
    const h = C('honest');
    if (t >= h - 0.03) {
      const g = prog(t, h, 0.25), f = Math.round(t * 30);
      const jx = g < 1 ? (rnd(f) - 0.5) * 40 : 0;
      at(jx, 0, 1, 0, () => {
        rr(-470, 40, 940, 330, 24); ctx.fillStyle = ACC; ctx.fill();
        if (g < 1) { txt('EHRLICH', -10, 130, 150, '#00e5ff', { alpha: 0.6 }); }
        txt('EHRLICH', 0, 130, 150, WHITE);
        txt('ÜBERSETZT.', 0, 280, 130, BG0, { maxW: 900 });
      });
    }
  }));
}
function deck(t, deckIn, outroT) {
  const inP = eOut(prog(t, deckIn, 0.45));
  const outP = eIn(prog(t, outroT, 0.4));
  const k = itemIndex(t);
  alpha(1 - outP, () => {
    at(0, (1 - inP) * 700 + outP * 400, 1, 0, () => hrCard(t, 380, k));
    let rot = 0;
    for (let i = 1; i <= NI; i++) if (t >= T('r' + i) - 0.02) rot += Math.PI * eOut(prog(t, T('r' + i) - 0.02, 0.35));
    at(0, (1 - inP) * 900 + outP * 400, 1, 0, () => { realCard(t, 880, k); swapIcon(540, 840, rot, t); });
    mono(KT.source, 540, 1435, 26, '#4a4a55', { align: 'center' });
  });
  notification(t);
}
function outroWidget(t, top) {
  const w = KT.outroWidget, cv = C('cv');
  if (t < cv - 0.1) return;
  alpha(eOut(prog(t, cv - 0.1, 0.3)), () => {
    rr(110, top, 860, 170, 30); ctx.fillStyle = '#1b1b24'; ctx.fill(); ctx.lineWidth = 3; ctx.strokeStyle = '#33333d'; ctx.stroke();
    if (w.type === 'upload') {
      rr(140, top + 30, 76, 96, 10); ctx.fillStyle = ACC; ctx.fill();
      txt('PDF', 178, top + 80, 26, WHITE);
      mono(w.file, 240, top + 55, 30, OFF);
      const p = eIO(prog(t, cv, 1.6));
      rr(240, top + 100, 690, 18, 9); ctx.fillStyle = '#2a2a33'; ctx.fill();
      rr(240, top + 100, Math.max(18, 690 * p), 18, 9); ctx.fillStyle = p >= 1 ? '#34c759' : ACC; ctx.fill();
      mono(p >= 1 ? 'Hochgeladen ✓' : `${Math.round(p * 100)} %`, 930, top + 55, 26, p >= 1 ? '#34c759' : GRAY, { align: 'right' });
    } else if (w.type === 'counter') {
      const n = Math.round(lerp(w.from, w.to, eOut(prog(t, cv + 0.1, 0.9))));
      mono(w.label, 150, top + 60, 30, OFF);
      mono(w.sub, 150, top + 115, 30, ACC);
      at(930, top + 85, 1 + 0.12 * Math.exp(-(t - cv - 1.0) * 8) * (t > cv + 1.0 ? 1 : 0), 0, () => txt(String(n), 0, 0, 88, OFF, { align: 'right' }));
    }
  });
}
function outro(t, outroT) {
  const endT = E('o2') + 0.35;
  const endP = eOut(prog(t, endT, 0.4));
  alpha(1 - endP, () => {
    const o1Size = KT.o1Size || 150, o1Lines = layoutWords(L['o1'].tokens.map(k => k.t), o1Size, 960).length;
    const o2Size = 64, o2Lines = layoutWords(L['o2'].tokens.map(k => k.t), o2Size, 900).length;
    const o1Y = 660, o2Y = o1Y + (o1Lines - 1) * o1Size * 1.12 + o1Size * 0.6 + 80;
    drawReveal(L['o1'], t, 540, o1Y, o1Size, 960, { center: true });
    drawReveal(L['o2'], t, 540, o2Y, o2Size, 900, { center: true, col: '#c7c7cc' });
    outroWidget(t, o2Y + (o2Lines - 1) * o2Size * 1.12 + 75);
  });
  if (endP > 0) alpha(endP, () => {
    at(540, 700, pop(t, endT, 0.4), 0, () => { ctx.save(); setFont(44, 800, MONO); const w = ctx.measureText(KT.end.tag).width + 53; ctx.restore(); pillMono(KT.end.tag, -w / 2, 0, 44, ACC, WHITE); });
    at(540, 880, pop(t, endT + 0.12, 0.45), 0, () => { txt(KT.end.lines[0], 0, 0, 104, OFF, { maxW: 960 }); txt(KT.end.lines[1], 0, 122, 104, OFF, { maxW: 960 }); });
    at(540, 1170, pop(t, endT + 0.35, 0.4), 0, () => mono(KT.end.tagline, 0, 0, 34, GRAY, { align: 'center' }));
  });
}

window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  bgDark(t);
  const deckIn = T('i1') - 0.45, outroT = T('o1') - 0.1;
  if (t < deckIn + 0.4) hook(t, deckIn);
  if (t >= deckIn) deck(t, deckIn, outroT);
  if (t >= outroT) outro(t, outroT);
  header(t, 1 - (t >= C('notif') && t < T('o1') ? eOut(prog(t, C('notif'), 0.3)) : 0));
};
window.EP_SCENES = {};
window.EP_STAMPS = [];
