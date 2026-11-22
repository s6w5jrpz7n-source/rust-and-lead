'use strict';
/* PHILOSOPHIE #3 – Das Schiff des Theseus */
const GY = 1195, NP = 12, NEWW = '#e0aa6e';
const ORDER3 = [3, 7, 10, 0, 5, 9, 1, 11, 4, 8, 2, 6];
function emoji(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
/* Zustand der Planken: 0 = original (schwarz), 1 = neu (helles Holz) */
function planksAt(t) {
  const st = new Array(NP).fill(0);
  const set = (i, tt) => { if (t >= tt) st[ORDER3[i]] = 1; };
  if (TL.cues.p1) { set(0, C('p1')); set(1, C('p2')); set(2, C('p3')); }
  const t5 = T('t5');
  for (let i = 3; i < NP; i++) set(i, t5 + 0.1 + (i - 3) * 0.12);
  return st;
}
function hullPath() { P(); ctx.moveTo(-330, -60); ctx.lineTo(340, -60); ctx.quadraticCurveTo(390, -40, 430, 10); ctx.lineTo(360, 22); ctx.quadraticCurveTo(0, 74, -330, 22); ctx.quadraticCurveTo(-380, -10, -330, -60); ctx.closePath(); }
function galley(x, y, s, o = {}) {
  const pl = o.planks || new Array(NP).fill(o.allNew ? 1 : 0), t = o.t || 0;
  at(x, y, s, o.rot || 0, () => {
    if (o.oars !== false) for (let i = 0; i < 9; i++) { const ox = -260 + i * 70, sw = Math.sin(t * 3 + i * 0.3) * 14; seg(ox, 0, ox - 70 + sw, 120, 6, BLK); }
    if (o.mast !== false) { seg(0, -60, 0, -420, 12, BLK); seg(-200, -400, 200, -400, 8, BLK);
      P(); ctx.moveTo(-190, -396); ctx.lineTo(190, -396); ctx.quadraticCurveTo(205 + Math.sin(t * 2) * 8, -250, 180, -120); ctx.lineTo(-180, -120); ctx.quadraticCurveTo(-170 + Math.sin(t * 2) * 8, -250, -190, -396); ctx.closePath(); fs(o.sail || CREAM, 5, BLK);
      for (const yy of [-330, -260, -190]) seg(-182, yy, 182, yy, 8, PURP); }
    P(); ctx.moveTo(-330, -60); ctx.quadraticCurveTo(-420, -90, -400, -200); ctx.quadraticCurveTo(-395, -240, -360, -230); ctx.lineWidth = 22; ctx.strokeStyle = BLK; ctx.lineCap = 'round'; ctx.stroke();
    ctx.save(); hullPath(); ctx.clip();
    const x0 = -390, w = (440 - x0) / NP;
    for (let i = 0; i < NP; i++) { ctx.fillStyle = pl[i] ? NEWW : BLK; ctx.fillRect(x0 + i * w, -80, w + 1, 170); if (pl[i]) { ctx.strokeStyle = '#9a6a3a'; ctx.lineWidth = 3; ctx.strokeRect(x0 + i * w, -80, w, 170); } }
    if (o.rot2) for (let i = 0; i < NP; i++) if (!pl[i]) for (let k = 0; k < 3; k++) { circ(x0 + i * w + rnd(i * 3 + k) * w, -40 + rnd(i + k * 7) * 70, 6 * o.rot2); ctx.fillStyle = '#6b4a2e'; ctx.fill(); }
    for (const yy of [-30, 0]) seg(-400, yy, 440, yy + 6, 3, TERRA_L);
    ctx.restore();
    hullPath(); fs(null, 6, BLK);
    ell(330, -28, 22, 13); ctx.fillStyle = CREAM; ctx.fill(); circ(334, -28, 7); ctx.fillStyle = BLK; ctx.fill();
  });
}
function waves(y, t, col = BLK) {
  ctx.fillStyle = '#4f7d93'; ctx.fillRect(0, y, W, 400);
  ctx.strokeStyle = col; ctx.lineWidth = 6;
  for (let r = 0; r < 3; r++) { P(); for (let x = -40; x <= W + 40; x += 10) { const yy = y + r * 40 + Math.sin(x / 40 + t * 2 + r) * 8; x === -40 ? ctx.moveTo(x, yy) : ctx.lineTo(x, yy); } ctx.stroke(); }
}
function temple(x, y, s) {
  at(x, y, s, 0, () => {
    P(); ctx.moveTo(-180, -260); ctx.lineTo(0, -330); ctx.lineTo(180, -260); ctx.closePath(); fs(CREAM, 5, BLK);
    rr(-180, -262, 360, 30, 2); fs(CREAM, 5, BLK);
    for (let i = 0; i < 6; i++) { rr(-160 + i * 60, -232, 26, 212, 2); fs(CREAM, 4, BLK); }
    rr(-200, -22, 400, 22, 2); fs(CREAM, 5, BLK);
  });
}
function pct(t, x, y) {
  const n = planksAt(t).filter(v => !v).length, v = Math.round(n / NP * 100);
  pill(`Originalteile: ${v} %`, x, y, 36, v ? BLK : PURP, CREAM, { lw: 0 });
}
function you(x, y, s, label, o = {}) {
  fig(x, y, s, Object.assign({ beard: false, robe: o.robe || BLK, eye: 'open' }, o));
  pill(label, x, y + 40, 28, BLK, CREAM, { lw: 0 });
}
function hook(t, lt) {
  ground(GY);
  you(290, GY - 40, 1.0, 'du, vor 10 Jahren', { robe: TERRA_D });
  you(770, GY - 40, 1.25, 'du, heute', { robe: BLK });
  at(530, 900, pop(t, 0.5, 0.4), 0, () => stxt('= ?', 0, 0, 120, CREAM, { stroke: 12 }));
  if (t >= C('raetsel') - 0.05) at(540, 480, pop(t, C('raetsel') - 0.05, 0.4), 0, () => pill('ein antikes Rätsel', 0, 0, 38, BLK, GOLD, { lw: 0 }));
}
function fahrt(t, lt) {
  temple(880, 1000, 0.8 * pop(t, T('t2') + 1.2, 0.5));
  stxt('ATHEN', 880, 1030, 34, BLK);
  const gx = lerp(-200, 470, eOut(prog(t, T('t2'), 2.8)));
  galley(gx, 1040, 0.85, { t });
  fig(gx - 230, 1040 - 60 * 0.85, 0.55, { helmet: true, beard: 'short', aF: [2.6, 0.2], eye: 'open', hold: 'spear' });
  waves(1060, t);
  at(540, 520, pop(t, T('t2') + 0.3, 0.4), 0, () => pill('Theseus · Bezwinger des Minotaurus', 0, 0, 34, BLK, CREAM, { lw: 0 }));
}
function museum(t, lt) {
  ground(GY);
  for (const k of [-1, 1]) { P(); ctx.moveTo(540 + k * 220 - 60, GY); ctx.lineTo(540 + k * 220, GY - 120); ctx.lineTo(540 + k * 220 + 60, GY); ctx.closePath(); fs(CREAM, 5, BLK); }
  galley(540, GY - 150, 0.95, { t: 0, oars: false, planks: planksAt(t), rot2: TL.cues.morsch && t > C('morsch') ? clamp((t - C('morsch')) * 2) : 0 });
  if (t < T('t4')) {
    at(540, 480, pop(t, T('t3'), 0.4), 0, () => pill('aufbewahrt in Athen', 0, 0, 36, BLK, CREAM, { lw: 0 }));
    if (t >= C('jahre') - 0.05) at(540, 570, pop(t, C('jahre') - 0.05, 0.4), 0, () => stxt('Jahrhundertelang ⏳', 0, 0, 56, CREAM, { stroke: 10 }));
  } else pct(t, 540, 480);
  // neue Planke fliegt ein
  for (const c of ['p1', 'p2', 'p3']) if (TL.cues[c] && t >= C(c) - 0.3 && t < C(c) + 0.3) { const u = prog(t, C(c) - 0.3, 0.3); at(lerp(1000, 540, u), lerp(560, GY - 150, u), 1, u * 3, () => { rr(-30, -60, 60, 120, 4); fs(NEWW, 4, BLK); }); }
  if (t >= T('t5')) {
    if (t >= C('null') - 0.05 && planksAt(t).every(v => v)) at(880, 800, pop(t, T('t5') + 1.5, 0.3), -0.15, () => { rr(-120, -56, 240, 112, 12); fs(null, 10, PURP); stxt('0 %', 0, 4, 80, PURP); });
    if (t >= C('frage') - 0.05) at(540, 572, pop(t, C('frage') - 0.05, 0.4), 0, () => stxt('Noch das Schiff des Theseus?', 0, 0, 54, CREAM, { stroke: 10 }));
  }
}
function zwei(t, lt) {
  const bt = C('b'), u = eOut(prog(t, T('t6'), 0.6));
  if (!TL.cues.ab || t < C('ab') - 0.05) at(540, 475, pop(t, T('t6') + 0.2, 0.4), 0, () => pill('Thomas Hobbes, 1655', 0, 0, 34, BLK, CREAM, { lw: 0 }));
  galley(540, lerp(GY - 150, 800, u), lerp(0.95, 0.62, u), { t, oars: false, allNew: true });
  ground(GY);
  if (t >= bt - 0.05) {
    const v = prog(t, bt, 1.4);
    // alte Planken fliegen zusammen
    for (let i = 0; i < NP; i++) {
      const k = clamp(v * 1.6 - i * 0.05);
      if (k < 1) at(lerp(100 + rnd(i) * 880, 540 - 230 + i * 40, eIO(k)), lerp(GY - 30 - rnd(i + 3) * 60, GY - 120, eIO(k)), 1, (1 - k) * (rnd(i) - 0.5) * 3, () => { rr(-22, -50, 44, 100, 4); fs(BLK, 3, TERRA_L); });
    }
    if (v > 0.6) alpha(clamp((v - 0.6) * 3), () => galley(540, GY - 110, 0.62, { t, oars: false, mast: v > 0.9 }));
  }
  const lab = (c, x, y, s) => { if (TL.cues[c] && t >= C(c) - 0.05) at(x, y, pop(t, C(c) - 0.05, 0.35), 0, () => { circ(0, 0, 58); fs(GOLD, 8, BLK); stxt(s, 0, 4, 76, BLK); }); };
  lab('a', 870, 740, 'A'); lab('bb', 870, GY - 160, 'B');
  if (TL.cues.ab && t >= C('ab') - 0.05) at(540, 478, pop(t, C('ab') - 0.05, 0.4), 0, () => stxt('Welches ist echt?', 0, 0, 56, CREAM, { stroke: 10 }));
  if (TL.cues.a && t >= C('a') - 0.05) { stxt('neue Planken', 540, 900, 30, BLK); }
  if (TL.cues.bb && t >= C('bb') - 0.05) { stxt('alte Planken', 540, GY + 30, 30, BLK); }
}
/* Mensch mit Zellen */
function bodyPath(x, y, s) { P(); ctx.arc(x, y - 640 * s, 80 * s, 0, Math.PI * 2); ctx.roundRect(x - 130 * s, y - 540 * s, 260 * s, 320 * s, 60 * s); ctx.roundRect(x - 120 * s, y - 240 * s, 100 * s, 240 * s, 40 * s); ctx.roundRect(x + 20 * s, y - 240 * s, 100 * s, 240 * s, 40 * s); }
function cells(x, y, s, t, t0, rate) {
  ctx.save(); bodyPath(x, y, s); ctx.fillStyle = CREAM; ctx.fill(); ctx.clip();
  for (let gx = -160; gx <= 160; gx += 28) for (let gy = -730; gy <= 0; gy += 28) {
    const i = (gx + 200) * 31 + gy, chg = t0 + rnd(i) * rate;
    circ(x + gx * s + (Math.abs(gy) % 56 ? 7 : 0), y + gy * s, 11 * s); ctx.fillStyle = t > chg ? GOLD : BLK; ctx.fill();
  }
  ctx.restore(); bodyPath(x, y, s); fs(null, 6, BLK);
}
function du(t, lt) {
  const t0 = T('t8') + 0.8;
  cells(540, GY - 10, 0.9, t, t0, (E('t8') - t0) * 1.4);
  at(540, 470, pop(t, T('t8') + 0.2, 0.4), 0, () => pill('dein Körper', 0, 0, 36, BLK, CREAM, { lw: 0 }));
  if (t >= C('haut') - 0.05) at(840, 820, pop(t, C('haut') - 0.05, 0.4), 0.08, () => { rr(-150, -70, 300, 140, 20); fs(GOLD, 6, BLK); stxt('Haut:', 0, -26, 36, BLK); stxt('alle paar Wochen neu', 0, 24, 30, BLK, { maxW: 270 }); });
}
function version(t, lt) {
  const g = t >= C('version') && t < C('version') + 0.35;
  const gx = g ? Math.sin(t * 90) * 14 : 0;
  ctx.save(); ctx.translate(gx, 0);
  cells(330, GY - 10, 0.7, t, -99, 0); cells(750, GY - 10, 0.7, t, 99, 0);
  ctx.restore();
  if (g) alpha(0.4, () => { ctx.fillStyle = '#00e5ff'; ctx.fillRect(0, 600 + Math.sin(t * 40) * 200, W, 30); ctx.fillStyle = '#ff2d75'; ctx.fillRect(0, 820 + Math.cos(t * 37) * 200, W, 22); });
  pill('DU 1.0', 330, GY + 30, 30, BLK, CREAM, { lw: 0 }); pill('DU 2.0', 750, GY + 30, 30, PURP, CREAM, { lw: 0 });
  if (TL.cues.erinn && t >= C('erinn') - 0.05) {
    const p = pop(t, C('erinn') - 0.05, 0.4);
    at(540, 515, p, 0, () => { emoji('📸', -90, 0, 70); emoji('🧠', 0, 0, 70); emoji('💌', 90, 0, 70); });
    at(540, 600, p, 0, () => stxt('gleiche Erinnerungen', 0, 0, 44, CREAM, { stroke: 8 }));
  }
}
function cta(t, lt) {
  galley(300, 840, 0.45, { t, allNew: true, oars: false }); galley(780, 840, 0.45, { t, oars: false });
  for (const [x, s] of [[300, 'A'], [780, 'B']]) { circ(x, 580, 54); fs(GOLD, 8, BLK); stxt(s, x, 584, 70, BLK); }
  at(540, 1040, pop(t, C('cta') - 0.05, 0.4), 0, () => stxt('A oder B? Schreib’s unten 👇', 0, 0, 58, CREAM, { stroke: 12 }));
  at(540, 1150, pop(t, C('cta') + 0.9, 0.4), 0, () => pill('Folg für mehr Philosophie in 60 Sekunden', 0, 0, 30, BLK, CREAM, { lw: 0 }));
}
const SCN = [['t1', hook], ['t2', fahrt], ['t3', museum], ['t6', zwei], ['t8', du], ['t9', version], ['t10', cta]];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  vaseBg();
  ctx.save(); ctx.beginPath(); ctx.rect(0, 432, W, 830); ctx.clip();
  sceneAt(t, SCN);
  ctx.restore();
  frame('PHILOSOPHIE #3', 'Das Schiff des Theseus');
  drawCaptions(t);
};
window.EP_SCENES = {};
