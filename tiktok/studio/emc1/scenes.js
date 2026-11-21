'use strict';
/* WISSENSCHAFT – E = mc² mit Einsteins Lichtkasten. Eigener renderFrame + Engine-Untertitel. */
window.EP_CAPCOL = { Q: '#ffd43b' };
const SERIF = '"Liberation Serif", "DejaVu Serif", serif';
const NEON = '#ffd43b', CYAN = '#66d9ff', BG1 = '#0a1430';

/* ---------- Mini-Formelsatz ---------- */
function texParse(s) {
  let i = 0;
  const atom = ch => (/[a-zA-Z]/.test(ch) ? { t: 'var', s: ch } : '=≈+−'.includes(ch) ? { t: 'op', s: ch } : { t: 'txt', s: ch });
  function group() { i++; const g = seq('}'); i++; return g; }
  function seq(end) {
    const out = [];
    while (i < s.length && s[i] !== end) {
      if (s.startsWith('\\frac', i)) { i += 5; const n = group(), d = group(); out.push({ t: 'frac', n, d }); }
      else if (s.startsWith('\\cancel', i)) { i += 7; const g = group(); g.forEach(n => (n.c = true)); out.push(...g); }
      else if (s[i] === '\\') { const m = /^\\([a-zA-Z]+)/.exec(s.slice(i)); i += m[0].length; const map = { Delta: 'Δ', approx: '≈', cdot: '·', ll: '≪' }; const ch = map[m[1]] || m[1]; out.push(ch === 'Δ' ? { t: 'up', s: 'Δ' } : ch === '·' ? { t: 'txt', s: '·' } : { t: 'op', s: ch }); }
      else if (s[i] === '^') { i++; const sup = s[i] === '{' ? group() : [atom(s[i++])]; out.push({ t: 'sup', b: out.pop(), s: sup }); }
      else if (s[i] === ' ') i++;
      else out.push(atom(s[i++]));
    }
    return out;
  }
  return seq(undefined);
}
function fontFor(n, size) { return `${n.t === 'var' ? 'italic ' : ''}400 ${size}px ${SERIF}`; }
function mNode(n, size) {
  if (n.t === 'frac') {
    const a = mSeq(n.n, size * 0.82), b = mSeq(n.d, size * 0.82), g = size * 0.14, ax = size * 0.3;
    return { w: Math.max(a.w, b.w) + size * 0.3, asc: ax + g + a.asc + a.desc, desc: g + b.asc + b.desc - ax };
  }
  if (n.t === 'sup') { const b = mNode(n.b, size), s = mSeq(n.s, size * 0.6); return { w: b.w + s.w + size * 0.04, asc: Math.max(b.asc, size * 0.42 + s.asc), desc: b.desc }; }
  ctx.save(); ctx.font = fontFor(n, size); const w = ctx.measureText(n.s).width; ctx.restore();
  return { w: n.t === 'op' ? w + size * 0.55 : w + (n.t === 'var' ? size * 0.04 : 0), asc: size * 0.72, desc: size * 0.22 };
}
function mSeq(seq, size) { let w = 0, asc = 0, desc = 0; for (const n of seq) { const m = mNode(n, size); w += m.w; asc = Math.max(asc, m.asc); desc = Math.max(desc, m.desc); } return { w, asc, desc }; }
function dNode(n, x, y, size, col, cp) {
  const m = mNode(n, size);
  if (n.t === 'frac') {
    const a = mSeq(n.n, size * 0.82), b = mSeq(n.d, size * 0.82), g = size * 0.14, ax = y - size * 0.3;
    dSeq(n.n, x + (m.w - a.w) / 2, ax - g - a.desc, size * 0.82, col, cp);
    dSeq(n.d, x + (m.w - b.w) / 2, ax + g + b.asc, size * 0.82, col, cp);
    ctx.fillStyle = col; ctx.fillRect(x + size * 0.08, ax - size * 0.03, m.w - size * 0.16, size * 0.06);
  } else if (n.t === 'sup') {
    const b = mNode(n.b, size); dNode(n.b, x, y, size, col, cp); dSeq(n.s, x + b.w + size * 0.04, y - size * 0.42, size * 0.6, col, cp);
  } else {
    ctx.save(); ctx.font = fontFor(n, size); ctx.fillStyle = col; ctx.textBaseline = 'alphabetic';
    ctx.fillText(n.s, n.t === 'op' ? x + size * 0.275 : x, y); ctx.restore();
  }
  if (n.c && cp > 0) { ctx.save(); ctx.strokeStyle = '#ff6b6b'; ctx.lineWidth = size * 0.07; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(x - 4, y + size * 0.12); ctx.lineTo(x - 4 + (m.w + 8) * cp, y + size * 0.12 - (size * 0.85) * cp); ctx.stroke(); ctx.restore(); }
  return m.w;
}
function dSeq(seq, x, y, size, col, cp = 0) { for (const n of seq) x += dNode(n, x, y, size, col, cp); }
const TEXC = {};
function tex(s, cx, y, size, col, o = {}) {
  const seq = TEXC[s] || (TEXC[s] = texParse(s)); const m = mSeq(seq, size);
  ctx.save();
  if (o.glow) { ctx.shadowColor = col; ctx.shadowBlur = o.glow; }
  dSeq(seq, cx - m.w / 2, y, size, col, o.cancel || 0);
  ctx.restore();
  return m;
}

/* ---------- Hintergrund ---------- */
function blueprint(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#0d1b40'); g.addColorStop(1, '#050a1c'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.save(); ctx.globalAlpha = 0.18; ctx.strokeStyle = '#2b4a8a'; ctx.lineWidth = 1;
  for (let x = 0; x <= W; x += 45) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke(); }
  for (let y = 0; y <= H; y += 45) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }
  ctx.restore();
  ctx.save(); for (let i = 0; i < 70; i++) { ctx.globalAlpha = 0.25 + 0.6 * Math.abs(Math.sin(t * 1.3 + i)); circ(rnd(i) * W, rnd(i + 40) * H, 1 + rnd(i + 8) * 2); ctx.fillStyle = WHITE; ctx.fill(); } ctx.restore();
}
function header(t, a) {
  alpha(a, () => {
    pill('WISSENSCHAFT', 540, 225, 30, CYAN, '#04122e', { lw: 0 });
    const w1 = tw('Warum ', 70), m = mSeq(TEXC['E = mc^2'] || (TEXC['E = mc^2'] = texParse('E = mc^2')), 76), tot = w1 + m.w + tw('?', 70);
    const x0 = 540 - tot / 2;
    txt('Warum ', x0, 320, 70, WHITE, { align: 'left', weight: 900 });
    ctx.save(); dSeq(TEXC['E = mc^2'], x0 + w1, 345, 76, NEON); ctx.restore();
    txt('?', x0 + w1 + m.w + 4, 320, 70, WHITE, { align: 'left', weight: 900 });
  });
}

/* ---------- Lichtkasten ---------- */
function travelP(t) { return eIO(prog(t, C('recoil') - 0.4, E('n6') - C('recoil') + 0.4)); }
function boxScene(t) {
  const BX = 540, BY = 650, BW = 760, BH = 230;
  const p = travelP(t), drift = -70 * p;
  const x0 = BX - BW / 2 + drift;
  const ap = pop(t, C('box') - 0.1, 0.45);
  if (ap <= 0.001) return;
  at(BX, BY, ap, 0, () => {
    ctx.translate(-BX, -BY);
    // ursprüngliche Lage (ab Δx)
    if (t >= C('dx') - 0.1) { ctx.save(); ctx.setLineDash([14, 10]); ctx.lineWidth = 4; ctx.strokeStyle = 'rgba(255,255,255,0.35)'; ctx.strokeRect(BX - BW / 2, BY - BH / 2, BW, BH); ctx.restore(); }
    // Kasten
    ctx.save(); ctx.shadowColor = CYAN; ctx.shadowBlur = 20;
    ctx.lineWidth = 12; ctx.strokeStyle = CYAN; ctx.strokeRect(x0, BY - BH / 2, BW, BH); ctx.restore();
    ctx.fillStyle = 'rgba(102,217,255,0.06)'; ctx.fillRect(x0, BY - BH / 2, BW, BH);
    // Lampe links
    rr(x0 + 14, BY - 40, 26, 80, 8); fs('#ced4da', 0);
    if (t >= C('flash') - 0.05 && t < C('flash') + 0.5) { const f = 1 - prog(t, C('flash'), 0.5); const g = ctx.createRadialGradient(x0 + 40, BY, 5, x0 + 40, BY, 260); g.addColorStop(0, `rgba(255,236,150,${f})`); g.addColorStop(1, 'rgba(255,236,150,0)'); ctx.fillStyle = g; ctx.fillRect(x0 - 200, BY - 300, 600, 600); }
    // Lichtpuls
    if (t >= C('flash')) {
      const absorbed = p >= 1;
      const px = lerp(x0 + 60, x0 + BW - 40, p);
      if (!absorbed) {
        ctx.save(); ctx.shadowColor = NEON; ctx.shadowBlur = 40; ell(px, BY, 34, 22); ctx.fillStyle = NEON; ctx.fill(); ctx.restore();
        for (let i = 1; i < 6; i++) { ell(px - i * 16, BY, 26 - i * 4, 16 - i * 2.5); ctx.fillStyle = `rgba(255,212,59,${0.4 - i * 0.07})`; ctx.fill(); }
        txt('E', px, BY - 56, 46, NEON, { weight: 900 });
        if (t >= C('eq1')) { seg(px + 44, BY, px + 130, BY, 6, NEON); arrowHead(px + 140, BY, 0, 16, NEON); at(px + 100, BY - 70, 1, 0, () => tex('p', 0, 14, 48, NEON)); }
      } else { const g = ctx.createRadialGradient(x0 + BW - 20, BY, 5, x0 + BW - 20, BY, 120); g.addColorStop(0, `rgba(255,212,59,${0.6 * (1 - prog(t, E('n6'), 1.2))})`); g.addColorStop(1, 'rgba(255,212,59,0)'); ctx.fillStyle = g; ctx.fillRect(x0 + BW - 150, BY - 150, 300, 300); }
    }
    // Beschriftung M und L
    if (t >= C('M') - 0.05) at(x0 + BW / 2, BY - BH / 2 - 46, pop(t, C('M') - 0.05, 0.35), 0, () => pill('Masse M', 0, 0, 34, '#1c3d7a', WHITE, { lw: 0 }));
    if (t >= C('L') - 0.05) {
      const y = BY + BH / 2 + 50, a = fade(t, C('L') - 0.05, 0.3);
      alpha(a, () => { seg(x0 + 10, y, x0 + BW - 10, y, 4, WHITE); arrowHead(x0 + 4, y, Math.PI, 12, WHITE); arrowHead(x0 + BW - 4, y, 0, 12, WHITE); at(x0 + BW / 2, y, 1, 0, () => { rr(-34, -28, 68, 56, 12); ctx.fillStyle = BG1; ctx.fill(); tex('L', 0, 16, 48, WHITE); }); });
    }
    // Rückstoß
    if (t >= C('recoil') - 0.05 && p < 1) {
      seg(x0 - 20, BY, x0 - 130, BY, 8, '#ff6b6b'); arrowHead(x0 - 140, BY, Math.PI, 18, '#ff6b6b');
      at(x0 - 90, BY - 50, 1, 0, () => tex('v', 0, 14, 52, '#ff6b6b'));
    }
    // Δx
    if (t >= C('dx') - 0.05) {
      const y = BY - BH / 2 - 100, a = fade(t, C('dx') - 0.05, 0.3);
      alpha(a, () => {
        seg(BX - BW / 2, y, x0, y, 5, '#ff6b6b'); arrowHead(x0 - 4, y, Math.PI, 12, '#ff6b6b');
        at((BX - BW / 2 + x0) / 2, y - 44, 1, 0, () => tex('\\Delta x', 0, 14, 46, '#ff6b6b'));
        txt('(stark übertrieben)', BX + 160, y + 2, 26, 'rgba(255,255,255,0.6)', { weight: 700 });
      });
    }
    // Schwerpunkt
    if (t >= C('cm') - 0.05) {
      const ok = t >= C('mass');
      const cx = ok ? BX : BX + drift * 0.9, cy = BY;
      at(cx, cy, pop(t, C('cm') - 0.05, 0.35), 0, () => {
        circ(0, 0, 26); fs(ok ? '#40c057' : '#ff6b6b', 0); circ(0, 0, 26); ctx.fillStyle = WHITE;
        ctx.save(); ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, 26, 0, Math.PI / 2); ctx.closePath(); ctx.fill(); ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, 26, Math.PI, Math.PI * 1.5); ctx.closePath(); ctx.fill(); ctx.restore();
        circ(0, 0, 26); fs(null, 4, WHITE);
        txt('Schwerpunkt', 0, 56, 30, ok ? '#8ce99a' : '#ff8787', { weight: 900, stroke: 6, sc: BG1 });
      });
      if (!ok) at(BX + drift * 0.9, BY, 1 + 0.1 * Math.sin(t * 20), 0, () => { seg(-46, -46, 46, 46, 10, '#ff6b6b'); seg(46, -46, -46, 46, 10, '#ff6b6b'); });
    }
    // Wiederholung mit Masse m (n9)
    if (t >= C('mass') - 0.1 && t < E('n9') + 0.3) {
      const q = eIO(prog(t, C('mass'), E('n9') - C('mass')));
      const px = lerp(BX - BW / 2 + 60, BX + BW / 2 - 40, q);
      ctx.save(); ctx.shadowColor = NEON; ctx.shadowBlur = 30; ell(px, BY, 30, 20); ctx.fillStyle = NEON; ctx.fill(); ctx.restore();
      at(px, BY - 60, 1, 0, () => { circ(0, 0, 30); fs('#40c057', 0); tex('m', 0, 12, 44, WHITE); });
    }
  });
  if (t >= C('insert') && t < C('anders')) alpha(fade(t, C('insert'), 0.3), () => txt('Näherung Δx ≪ L – exakt gerechnet kommt dasselbe raus.', 540, 905, 26, 'rgba(255,255,255,0.65)', { weight: 700 }));
}

/* ---------- Formelpanel ---------- */
const EQS = [
  ['eq1', 'p = \\frac{E}{c}', 'Licht hat Impuls'],
  ['eq2', 'v = \\frac{E}{Mc}', 'Rückstoß (Impulserhaltung)'],
  ['eq3', 't \\approx \\frac{L}{c}', 'Laufzeit des Lichts'],
  ['eq4', '\\Delta x = v \\cdot t = \\frac{EL}{Mc^2}', 'Verschiebung des Kastens'],
  ['eq5', 'm \\cdot L = M \\cdot \\Delta x', 'Schwerpunkt bleibt'],
  ['insert', 'm \\cdot \\cancel{L} = \\cancel{M} \\cdot \\frac{E\\cancel{L}}{\\cancel{M}c^2}', 'Einsetzen und kürzen'],
  ['eq6', 'm = \\frac{E}{c^2}', 'Ergebnis'],
];
function panel(t) {
  const shown = EQS.filter(e => t >= C(e[0]) - 0.05);
  if (!shown.length) return;
  const a = fade(t, C('eq1') - 0.2, 0.3);
  alpha(a, () => { rr(50, 930, 980, 400, 34); ctx.fillStyle = 'rgba(255,255,255,0.06)'; ctx.fill(); ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(102,217,255,0.35)'; ctx.stroke(); });
  const cur = shown[shown.length - 1], prev = shown.length > 1 ? shown[shown.length - 2] : null;
  if (prev) alpha(0.5, () => tex(prev[1], 540, 1012, 54, WHITE, { cancel: prev[0] === 'insert' ? 1 : 0 }));
  const p = pop(t, C(cur[0]) - 0.05, 0.4);
  at(540, 1085, p, 0, () => txt(cur[2], 0, 0, 28, CYAN, { weight: 800 }));
  at(540, 1205, p, 0, () => tex(cur[1], 0, 0, 84, NEON, { glow: 16, cancel: cur[0] === 'insert' ? eOut(prog(t, C('cancel'), 0.5)) : 0 }));
}

/* ---------- Finale ---------- */
function reveal(t) {
  const a = fade(t, C('anders') - 0.1, 0.3);
  alpha(a, () => { ctx.fillStyle = 'rgba(3,6,18,0.9)'; ctx.fillRect(0, 0, W, H); });
  if (t >= C('reveal') - 0.05) {
    const p = pop(t, C('reveal') - 0.05, 0.5);
    rays(540, 860, NEON, 0.12 * fade(t, C('reveal'), 0.4), t * 0.4, 24);
    at(540, 860, p * (1 + 0.02 * Math.sin(t * 4)), 0, () => tex('E = mc^2', 0, 70, 230, NEON, { glow: 60 }));
    at(540, 1080, pop(t, C('reveal') + 0.4, 0.4), 0, () => txt('Energie hat Masse.', 0, 0, 64, WHITE, { stroke: 10, weight: 900 }));
    confetti(t, C('reveal'), 540, 860, 70);
  } else at(540, 860, 1 + 0.03 * Math.sin(t * 20), 0, () => txt('…', 0, 0, 200, NEON));
}
function sun(t) {
  bg('#2b0f00', '#0a0300');
  const s0 = C('sun');
  const R = 230 * pop(t, s0 - 0.05, 0.5);
  for (let i = 0; i < 40; i++) { const u = ((t - s0) * 0.5 + rnd(i)) % 1, a = rnd(i + 3) * Math.PI * 2, r = R + u * 520; circ(540 + Math.cos(a) * r, 760 + Math.sin(a) * r, 6 * (1 - u) + 1); ctx.fillStyle = `rgba(255,212,59,${1 - u})`; ctx.fill(); }
  const g = ctx.createRadialGradient(540, 760, R * 0.2, 540, 760, R * 1.6); g.addColorStop(0, '#fff3bf'); g.addColorStop(0.45, '#ffa94d'); g.addColorStop(0.62, 'rgba(255,120,0,0.35)'); g.addColorStop(1, 'rgba(255,120,0,0)');
  ctx.fillStyle = g; ctx.fillRect(0, 300, W, 920);
  txt('DIE SONNE', 540, 330, 80, NEON, { stroke: 14 });
  if (t >= C('tonnen') - 0.05) at(540, 1150, pop(t, C('tonnen') - 0.05, 0.4), 0, () => { txt('−4.000.000 t', 0, 0, 110, WHITE, { stroke: 16 }); txt('Masse pro Sekunde – als Licht', 0, 90, 40, '#ffd8a8', { weight: 800, stroke: 8 }); });
}
function cta(t) {
  const a = fade(t, C('cta') - 0.1, 0.3);
  alpha(a, () => { ctx.fillStyle = 'rgba(3,6,18,0.85)'; ctx.fillRect(0, 0, W, H); });
  at(540, 700, pop(t, C('cta'), 0.4), 0, () => pill('TEIL 2', 0, 0, 46, CYAN, '#04122e', { lw: 0 }));
  at(540, 860, pop(t, C('cta') + 0.2, 0.45), 0, () => { txt('Warum nichts', 0, -60, 96, WHITE, { stroke: 14 }); txt('schneller ist als Licht', 0, 60, 84, NEON, { stroke: 14, maxW: 980 }); });
}
function hook(t) {
  const out = eIn(prog(t, C('box') - 0.6, 0.4));
  alpha(1 - out, () => {
    rays(540, 860, NEON, 0.08, t * 0.3, 20);
    at(540, 860, 1.02 + 0.02 * Math.sin(t * 3), 0, () => tex('E = mc^2', 0, 70, 220, NEON, { glow: 50 }));
    at(540, 1100, pop(t, 0.6, 0.4), 0, () => pill('Herleitung in 60 Sekunden', 0, 0, 44, CYAN, '#04122e', { lw: 0 }));
    if (t >= C('woher') - 0.05) at(540, 560, pop(t, C('woher') - 0.05, 0.35), -0.05, () => txt('Aber woher kommt sie?', 0, 0, 64, WHITE, { stroke: 12, weight: 900 }));
  });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  if (t >= C('sun') - 0.1 && t < C('cta') + 0.5) { sun(t); if (t >= C('cta') - 0.1) cta(t); drawCaptions(t); return; }
  if (t >= C('cta')) { blueprint(t); cta(t); drawCaptions(t); return; }
  blueprint(t);
  if (t < C('box')) hook(t);
  header(t, fade(t, C('box') - 0.3, 0.4));
  boxScene(t);
  panel(t);
  if (t >= C('anders') - 0.1) reveal(t);
  drawCaptions(t);
};
window.EP_SCENES = {};
