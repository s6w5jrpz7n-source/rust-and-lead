'use strict';
/* Folge 1: Klo-Blockierer */
/* ---------- Szenen ---------- */
function sceneHook(t) {
  bg('#1b1848', '#4a1d8f');
  ctx.save(); ctx.globalAlpha = 0.08; for (let x = -((t * 20) % 90); x < W; x += 90) seg(x, 0, x, H, 3, WHITE); for (let y = -((t * 20) % 90); y < H; y += 90) seg(0, y, W, y, 3, WHITE); ctx.restore();
  dots(t, '#a78bfa', 0.35, 4);
  const gIn = C('gurkeIn'), drumT = C('drum');
  if (t < gIn + 0.5) {
    const out = eIn(prog(t, gIn - 0.15, 0.45));
    alpha(1 - out, () => {
      at(540, 375, pop(t, 0.2), 0, () => pill('NEUE STUDIE', 0, 0, 48, RED, WHITE));
      at(540, 500, pop(t, TOK('h1', 11) - 0.1), Math.sin(t * 3) * 0.02, () => txt('KLO-BLOCKIERER', 0, 0, 110, YELLOW, { stroke: 18, maxW: 980 }));
      const zoom = 1 + 0.18 * eIO(prog(t, drumT, 1.2));
      const shake = t > TOK('h1', 12) ? Math.sin(t * 38) * 0.012 : 0;
      at(540, 1260 + out * 400, zoom * pop(t, 0.45, 0.5) * 0.85, shake, () => drawDoor(t));
    });
    const dark = prog(t, drumT, 0.5) * (1 - prog(t, gIn, 0.25));
    if (dark > 0) {
      const g = ctx.createRadialGradient(540, 900, 120, 540, 900, 900);
      g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, `rgba(0,0,0,${0.8 * dark})`);
      ctx.fillStyle = g; ctx.fillRect(-80, -80, W + 160, H + 160);
      alpha(dark, () => txt('?', 540, 960 + Math.sin(t * 8) * 10, 280, YELLOW, { stroke: 22 }));
    }
  }
  if (t >= gIn - 0.05) {
    const g = ctx.createRadialGradient(540, 900, 50, 540, 900, 700);
    g.addColorStop(0, 'rgba(255,230,120,0.55)'); g.addColorStop(1, 'rgba(255,230,120,0)');
    alpha(fade(t, gIn, 0.3), () => { ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); rays(540, 900, '#fff3b0', 0.12, t * 0.2); });
    const susT = C('sus'), angT = T('h6');
    let mood = 'happy';
    if (t >= susT) mood = 'sus';
    if (t >= angT) mood = 'angry';
    const zoomIn = 1 + 0.16 * eIO(prog(t, susT, 0.9)) - 0.16 * eIO(prog(t, angT, 0.25));
    const s = pop(t, gIn, 0.55) * 1.02 * zoomIn;
    const jump = t < gIn + 0.6 ? Math.sin(prog(t, gIn, 0.6) * Math.PI) * 60 : 0;
    const angry = t >= angT;
    const armR = angry ? 2.5 + 0.35 * Math.sin(t * 13) : (t >= T('h4') && t < susT ? 2.1 + 0.35 * Math.sin(t * 7) : 0.35);
    drawGurke(540, 1225 - jump + (zoomIn - 1) * 500, s, { t, mood, mouth: gMouth(t), hat: 'mirror', clip: true, armL: 0.55, armR, point: angry, lookY: mood === 'sus' ? 0.3 : 0 });
    const nameOut = 1 - fade(t, susT, 0.25);
    alpha(nameOut, () => {
      at(540, 455, pop(t, TOK('h4', 2) - 0.05), 0, () => txt('DR. GURKE', 0, 0, 124, WHITE, { stroke: 20 }));
      at(540, 565, pop(t, TOK('h4', 4) - 0.05), 0, () => pill('Gurkologisches Institut', 0, 0, 44, GREEN, WHITE));
    });
    if (t >= TOK('h5', 1) && t < angT + 0.1) {
      const qs = [[300, 560, 0], [790, 520, 0.15], [210, 760, 0.3], [870, 740, 0.45]];
      for (const [qx, qy, d] of qs) at(qx, qy + Math.sin(t * 4 + d * 10) * 14, pop(t, TOK('h5', 1) + d, 0.35), Math.sin(t * 3 + d) * 0.2, () => txt('?', 0, 0, 130, YELLOW, { stroke: 16 }));
    }
    if (angry) {
      alpha(0.35 * Math.exp(-(t - angT) * 2.5), () => { ctx.fillStyle = RED; ctx.fillRect(-80, -80, W + 160, H + 160); });
      stamp('NICHT SO!', 540, 520, t, C('stamp1'), -0.13);
    }
  }
}
function sceneProblem(t) {
  bg('#ffe7a3', '#ffcf86');
  const t0 = T('p1');
  at(540, 300, pop(t, t0 - 0.1), 0, () => txt('Das Syndrom:', 0, 0, 46, INK, { weight: 800 }));
  at(540, 380, pop(t, t0 + 0.1), 0, () => txt('KLO-BLOCKIERER', 0, 0, 104, RED, { stroke: 16, maxW: 980 }));
  const top = 470, floor = 1150;
  const enter = eOut(prog(t, t0, 0.5));
  ctx.save(); ctx.translate(0, (1 - enter) * 300); ctx.globalAlpha *= enter;
  rr(60, top, 545, floor - top, 0); fs('#d6ecfa', 7);
  ctx.save(); rr(60, top, 545, floor - top, 0); ctx.clip();
  for (let x = 60; x < 605; x += 68) seg(x, top, x, floor, 3, '#b3d6ee');
  for (let y = top; y < floor; y += 68) seg(60, y, 605, y, 3, '#b3d6ee');
  ctx.restore();
  rr(630, top, 450, floor - top, 0); fs('#f6d7a7', 7);
  ctx.save(); rr(630, top, 450, floor - top, 0); ctx.clip();
  for (let x = 650; x < 1080; x += 56) seg(x, top, x, floor, 14, 'rgba(255,255,255,0.35)');
  ctx.restore();
  rr(600, top - 10, 34, floor - top + 10, 4); fs('#8d6e63', 7);
  rr(40, floor, 1060, 46, 6); fs('#c49a6c', 7);
  rr(644, 760, 140, 390, 6); fs('#c08a5b', 7);
  circ(762, 960, 10); fs(YELLOW, 4);
  rr(660, 800, 108, 44, 10); fs(RED, 5); txt('BESETZT', 714, 823, 22, WHITE);
  const whine = C('whine');
  drawSitter(330, floor, 0.6, { t, mood: t >= whine ? 'whine' : 'bored', shake: t >= whine });
  const mins = Math.floor(lerp(0, 20, eIO(prog(t, T('p2'), C('twenty') - T('p2')))) + Math.max(0, (t - C('twenty')) * 0.6));
  at(850, 590, pop(t, T('p2') - 0.1), 0, () => { pill(`${mins} MIN`, 0, 0, 58, mins >= 20 ? RED : WHITE, mins >= 20 ? WHITE : INK); });
  const q = C('queue');
  const people = [[870, ORANGE, '#2b2d42', 0.0], [975, '#00b894', '#6d4c41', 0.25], [1070, '#e84393', '#2b2d42', 0.5]];
  for (const [px, sh, hair, d] of people) {
    const k = eOut(prog(t, q + d, 0.45));
    if (k > 0) drawStander(lerp(1250, px, k), floor, 0.62, { t, ph: d * 9, shirt: sh, hair, angry: t >= whine });
  }
  if (t >= whine) for (let i = 0; i < 2; i++) at(870 + i * 105, 790 - Math.abs(Math.sin(t * 9 + i)) * 16, pop(t, whine + 0.2 + i * 0.12), 0, () => txt('!!', 0, 0, 64, RED, { stroke: 10 }));
  ctx.restore();
  bubble(330, 572, 1, 'Ich kann nicht…', whine, t);
}
function scenePhone(t) {
  bg('#a8eee8', '#6fd0c9');
  stripes('#ffffff', 0.12, t * 40);
  const tIn = T('f1'), f1e = E('f1');
  titleBlock(t, tIn - 0.05, f1e + 0.05, 'PROBLEM #1', 'DAS HANDY', RED);
  const gOut = eIn(prog(t, f1e + 0.05, 0.45));
  if (gOut < 1) drawGurke(540, 1270 + gOut * 1000, 1.0 * pop(t, tIn - 0.1, 0.45), { t, mood: 'angry', mouth: gMouth(t), hat: 'mirror', armL: 0.4, armR: 2.55 + 0.25 * Math.sin(t * 12), point: true });
  const f2 = T('f2'), f3 = T('f3'), f4 = T('f4');
  const mv = eIO(prog(t, f3 - 0.1, 0.5));
  const pcx = lerp(540, 280, mv), pcy = lerp(730, 640, mv), pr = lerp(215, 150, mv);
  at(0, 0, 1, 0, () => {
    const s = pop(t, f2 - 0.1, 0.45);
    if (s <= 0.001) return;
    at(pcx, pcy, s, 0, () => {
      drawPie(0, 0, pr, 0.667 * eOut(prog(t, C('pie'), 0.8)), PURPLE);
      txt('2/3', 0, 4, pr * 0.5, INK);
    });
    alpha(1 - mv, () => txt('nehmen das Handy mit aufs Klo', 540, 1010, 46, INK, { weight: 800 }));
    alpha(mv, () => txt('Handy dabei', pcx, pcy + pr + 48, 38, INK, { weight: 800 }));
  });
  at(735, 600, pop(t, C('stat46') - 0.05, 0.45), 0, () => {
    txt('+46 %', 0, 0, 150, RED, { stroke: 18 });
    txt('Hämorrhoiden-', 0, 115, 46, INK, { weight: 800 });
    txt('Risiko', 0, 165, 46, INK, { weight: 800 });
  });
  drawPhoneBig(290, 1010, 0.62 * pop(t, f4 - 0.05, 0.45), t);
  at(290, 1162, pop(t, C('longer') - 0.05), 0, () => pill('länger sitzen', 0, 0, 34, ORANGE, WHITE));
  at(750, 1050, pop(t, f4 + 0.35, 0.45), 0, () => {
    drawGauge(0, 0, 150, lerp(0.12, 0.95, eOut(prog(t, C('druck'), 0.8))), t);
    txt('DRUCK', 0, 70, 50, INK);
  });
  alpha(fade(t, f3 + 0.3, 0.5) * 0.75, () => txt('Studie: Ramprasad et al., PLOS ONE 2025 · n = 125', 540, 1215, 28, INK, { weight: 600 }));
}
function panel(x, y, s, label, labCol, fn) {
  at(x, y, s, 0, () => {
    rr(-222, 0, 444, 680, 36); fs('rgba(255,255,255,0.88)', 7);
    pill(label, 0, 54, 40, labCol, WHITE);
    fn();
  });
}
function scenePosture(t) {
  bg('#cdf3d3', '#9fe3ad');
  dots(t, '#ffffff', 0.3, 9);
  const tIn = T('s1'), s1e = E('s1');
  titleBlock(t, tIn - 0.05, s1e + 0.05, 'PROBLEM #2', 'DU SITZT FALSCH!', RED, 120);
  const gOut = eIn(prog(t, s1e + 0.05, 0.45));
  if (gOut < 1) drawGurke(540, 1270 + gOut * 1000, 1.0 * pop(t, tIn - 0.1, 0.45), { t, mood: 'angry', mouth: gMouth(t), hat: 'mirror', armL: 0.4, armR: 2.55 + 0.25 * Math.sin(t * 12), point: true });
  const s2 = T('s2'), s4 = T('s4');
  const ps = lerp(1, 0.78, eIO(prog(t, s4 - 0.1, 0.5)));
  const stoolK = eOut(prog(t, C('stool'), 0.5));
  const lp = pop(t, s2 - 0.1, 0.45);
  if (lp > 0.001) {
    panel(292, 420, ps * lp, stoolK > 0.5 ? 'MIT HOCKER' : 'SITZEN', stoolK > 0.5 ? GREEN : RED, () => {
      at(0, 450, 0.8, 0, () => {
        drawToiletSide();
        if (stoolK > 0) at(0, 0, 1, 0, () => { ctx.translate(0, -(1 - eBack(prog(t, C('stool'), 0.5))) * 300); drawStool(); });
        drawSideFigure(lerpPose(POSE_SIT, POSE_STOOL, stoolK), PURPLE, '#3a5bd9');
      });
      const hk = eOut(prog(t, C('muscle'), 0.4));
      if (hk > 0) {
        alpha(hk, () => {
          const kink = eBack(prog(t, C('kink'), 0.4)) * (1 - 0.85 * stoolK);
          const J = drawHose(10, 590, clamp(kink, 0, 1.05), t, { muscle: stoolK < 0.5, hi: t >= C('muscle') && t < C('hose') + 0.6 ? 1 : 0 });
          if (stoolK < 0.5) alpha(fade(t, C('muscle'), 0.3), () => txt('Muskel', J[0] - 105, J[1] - 64, 34, RED, { weight: 900 }));
        });
      }
      if (stoolK > 0.5) check(150, 160, pop(t, C('stool') + 0.25, 0.4) * 0.9);
    });
  }
  const rpS = pop(t, C('squat') - 0.1, 0.45);
  if (rpS > 0.001) {
    panel(788, 420, ps * rpS, 'HOCKE', GREEN, () => {
      at(0, 450, 0.8, 0, () => {
        ell(30, -4, 120, 16); fs('#e4eaf3', 6);
        drawSideFigure(POSE_SQUAT, '#00b894', '#2f3e46');
      });
      const st = C('straight');
      drawHose(10, 590, 1 - eOut(prog(t, st - 0.2, 0.5)), t, { muscle: false });
    });
  }
  alpha(fade(t, C('hose') - 0.05, 0.3) * (1 - fade(t, s4 - 0.2, 0.3)), () => at(540, 1180, pop(t, C('hose') - 0.05), 0, () => pill('wie ein Gartenschlauch', 0, 0, 40, '#2fae5a', WHITE)));
  const bk = fade(t, s4 + 0.2, 0.4);
  if (bk > 0) {
    alpha(bk, () => {
      const rows = [['Hocke', 51, '51 Sek.', GREEN, 'bar1', 1000], ['Sitzen', 120, '≈ 2 Min.', RED, 'bar2', 1100]];
      for (const [lab, v, vs, col, cue, y] of rows) {
        txt(lab, 90, y, 46, INK, { align: 'left' });
        const w = 500 * (v / 125) * eOut(prog(t, C(cue) - 0.1, 0.7));
        rr(270, y - 34, Math.max(w, 1), 68, 18); fs(col, 7);
        if (t > C(cue)) txt(vs, 270 + w + 18, y + 2, 42, INK, { align: 'left', alpha: fade(t, C(cue) + 0.4, 0.3) });
      }
      txt('Studie: Sikirov, Dig Dis Sci 2003 · n = 28', 540, 1205, 28, INK, { weight: 600, alpha: 0.75 });
    });
  }
}
function sceneMethod(t) {
  bg('#a9bf6d', '#768f3f');
  rays(540, 950, '#ffffff', 0.1, t * 0.3, 18);
  const t0 = T('m1'), bbt = C('bbt');
  alpha(1 - fade(t, bbt - 0.1, 0.2), () => at(540, 340, pop(t, t0 - 0.05), 0, () => txt('DIE METHODE', 0, 0, 112, WHITE, { stroke: 18 })));
  at(540, 380, pop(t, bbt - 0.05, 0.4), 0, () => {
    txt('BECKENBODEN-', 0, -50, 96, YELLOW, { stroke: 18 });
    txt('TRAINING', 0, 48, 96, YELLOW, { stroke: 18 });
  });
  stamp('NICHT SO!', 540, 600, t, C('stamp2'), 0.12, { fadeAt: bbt + 0.15 });
  // Spannung k
  let k = 0;
  const tense = C('tense'), hold = C('hold'), relax = C('relax');
  if (t >= tense) k = eOut(prog(t, tense, 0.3)) * (1 - eOut(prog(t, relax, 0.35)));
  for (const c of ['c1', 'c2', 'c3']) if (t >= C(c)) k = Math.max(k, eOut(prog(t, C(c), 0.08)) * (1 - eOut(prog(t, C(c) + 0.28, 0.22))));
  const ff = C('ff'), c20 = C('c20');
  if (t >= ff && t < c20) k = 0.5 + 0.5 * Math.sin((t - ff) * 34);
  if (t >= c20) k = Math.max(0, 1 - prog(t, c20 + 0.3, 0.3)) * eOut(prog(t, c20, 0.08));
  const ap = pop(t, t0 - 0.1, 0.45);
  const yTop = 1150, sag = lerp(70, 6, k);
  const ymid = drawHammock(210, 870, yTop, sag * ap, k, t, t >= bbt ? 'Beckenboden' : '');
  const midY = (yTop + (yTop + sag * 2)) / 2;
  const speak = !!gLineAt(t);
  const salute = t >= c20 + 0.1 && t < c20 + 2.4;
  let mood = k > 0.55 ? 'squeeze' : (speak ? 'angry' : 'happy');
  if (t >= relax && t < T('m6')) mood = 'happy';
  const vib = t >= ff && t < c20 ? Math.sin(t * 90) * 5 : 0;
  drawGurke(540 + vib, midY * ap + (1 - ap) * 1700 + 0, 0.82 * ap, {
    t, mood, mouth: gMouth(t), hat: 'drill', coat: false, drill: true,
    sx: 1 + 0.07 * k, sy: 1 - 0.09 * k,
    armL: salute ? 0.4 : 0.5 + 0.2 * k, armR: salute ? -2.75 : (speak && k < 0.5 ? 2.4 + 0.3 * Math.sin(t * 12) : 0.5 + 0.2 * k), point: speak && !salute && k < 0.5,
  });
  // Pups-Wolke
  const pp = C('pups');
  if (t >= pp && t < pp + 1.0) {
    const u = prog(t, pp, 1.0);
    const sc = u < 0.35 ? eBack(u / 0.35) : 1 - eIn((u - 0.35) / 0.65);
    at(690, midY - 90, sc, 0, () => { for (const [x, y, r] of [[0, 0, 34], [30, -20, 28], [-26, -16, 26], [12, 18, 24]]) { circ(x, y, r); fs('#c7e88a', 5); } txt('?!', 70, -50, 46, RED, { stroke: 8 }); });
  }
  // Kommandos
  const cmd = (str, col, t1, t2) => { if (t >= t1 && t < t2) at(540, 560, pop(t, t1, 0.3), Math.sin(t * 30) * 0.015 * (col === ORANGE ? 1 : 0), () => txt(str, 0, 0, 104, col, { stroke: 18 })); };
  cmd('ANSPANNEN!', RED, tense, hold);
  cmd('HALTEN!', ORANGE, hold, relax);
  cmd('LOCKER LASSEN', BLUE, relax, T('m6'));
  // Zähler
  const reps = T('m6');
  if (t >= reps) {
    let n = 0;
    if (t >= C('c1')) n = 1; if (t >= C('c2')) n = 2; if (t >= C('c3')) n = 3;
    if (t >= ff) n = Math.min(19, 3 + Math.floor(17 * prog(t, ff, c20 - ff - 0.05)));
    if (t >= c20) n = 20;
    const lastChange = n >= 20 ? c20 : (t >= ff ? t - ((t - ff) % 0.09) : (n === 3 ? C('c3') : n === 2 ? C('c2') : n === 1 ? C('c1') : reps));
    at(790, 650, pop(t, reps - 0.05, 0.4), 0, () => {
      circ(0, 0, 118); fs(n >= 20 ? GREEN : WHITE, 9);
      at(0, -8, 1 + 0.25 * (1 - eOut(prog(t, lastChange, 0.15))), 0, () => txt(String(n), 0, 0, 120, n >= 20 ? WHITE : INK));
      txt('/ 20', 0, 72, 34, n >= 20 ? WHITE : INK, { weight: 800 });
    });
    if (t >= ff && t < c20) at(790, 830, 1, 0, () => {
      for (const dx of [-34, 14]) { P(); ctx.moveTo(dx - 26, -32); ctx.lineTo(dx + 26, 0); ctx.lineTo(dx - 26, 32); ctx.closePath(); fs(YELLOW, 7); }
      txt('x10', 0, 66, 40, WHITE, { stroke: 9 });
    });
    if (t < ff) at(300, 650, pop(t, reps, 0.4), 0, () => pill('20 x', 0, 0, 56, RED, WHITE));
  }
  confetti(t, c20, 540, 760);
}
function sceneTips(t) {
  bg('#ffdbe5', '#ffb8cb');
  dots(t, '#ffffff', 0.35, 21);
  const t1 = T('t1'), t2 = T('t2');
  at(540, 330, pop(t, t1 - 0.1), 0, () => txt('BONUS-TIPPS', 0, 0, 112, WHITE, { stroke: 18 }));
  const g1 = 1 - fade(t, t2 - 0.15, 0.3);
  alpha(g1, () => {
    const a1 = pop(t, t1, 0.45);
    at(300, 0, a1, 0, () => { drawHammock(-170, 170, 760, 8, 1, t, ''); txt('spüren', 0, 965, 48, INK, { weight: 800 }); });
    at(540, 780, a1, 0, () => { seg(-50, 0, 40, 0, 14); arrowHead(52, 0, 0, 28, INK); });
    at(780, 0, pop(t, C('entspannen') - 0.1, 0.45), 0, () => { drawHammock(-170, 170, 760, 70, 0, t, ''); txt('entspannen', 0, 965, 48, INK, { weight: 800 }); });
  });
  const cards = [['card1', 290, 690, 'Genug trinken', s => drawGlass(s)], ['card2', 750, 690, 'Ballaststoffe', s => drawBroccoli(s)],
    ['card3', 290, 1030, 'Nicht pressen', s => drawNoPress(s, t)], ['card4', 750, 1030, 'Max. 10 Min.', s => drawTimer(s, t)]];
  for (const [cue, x, y, lab, icon] of cards) {
    const wig = cue === 'card4' && t >= C('stand') ? Math.sin((t - C('stand')) * 18) * 0.06 * Math.exp(-(t - C('stand')) * 1.5) : 0;
    at(x, y, pop(t, C(cue) - 0.08, 0.4), wig, () => {
      rr(-200, -150, 400, 300, 34); fs(WHITE, 7);
      at(0, -30, 1, 0, () => icon(0.95));
      txt(lab, 0, 104, 40, INK, { weight: 900 });
    });
  }
  at(750, 872, pop(t, C('stand') - 0.05), 0, () => pill('Aufstehen!', 0, 0, 36, GREEN, WHITE));
}
function sceneOutro(t) {
  bg('#fff1c4', '#ffd98a');
  rays(540, 1050, '#ffffff', 0.25, t * 0.25);
  const o1 = T('o1'), sal = C('salad'), cta = C('cta');
  const bx = 700, by = 1135;
  const bs = pop(t, o1 - 0.2, 0.5);
  at(bx, by, bs, 0, () => drawBowlBack(0, 0));
  const jp = prog(t, sal - 0.05, 0.6);
  const gx = lerp(320, bx, eIO(jp)), gyBase = lerp(1235, 1240, jp) - Math.sin(jp * Math.PI) * 330;
  const inBowl = jp >= 1;
  const angry = t >= T('o2') && t < cta;
  const shake = angry ? Math.sin(t * 40) * 6 : 0;
  drawGurke(gx + shake, gyBase, 0.8 * pop(t, o1 - 0.25, 0.45), {
    t, mood: angry ? 'angry' : 'happy', mouth: gMouth(t), hat: 'mirror', rot: jp > 0 && jp < 1 ? Math.sin(jp * Math.PI) * -0.5 : 0, noShadow: jp > 0,
    armL: inBowl ? 2.2 + 0.2 * Math.sin(t * 6) : 0.4, armR: angry ? 2.5 + 0.3 * Math.sin(t * 12) : (inBowl ? 2.3 + 0.2 * Math.sin(t * 6 + 1) : 0.4), point: angry,
  });
  at(bx, by, bs, 0, () => drawBowlFront(0, 0));
  alpha(1 - fade(t, cta - 0.2, 0.3), () => at(540, 470, pop(t, sal + 0.2, 0.4), 0, () => txt('Gurke → Salat.', 0, 0, 88, DGREEN, { stroke: 14, sc: WHITE })));
  stamp('NIRGENDWO SONST!', 540, 640, t, C('nirgendwo'), -0.08, { size: 78, fadeAt: cta - 0.2 });
  // CTA
  at(540, 330, pop(t, cta - 0.05, 0.4), 0, () => txt('Schick das dem', 0, 0, 66, INK, { weight: 900 }));
  at(540, 440, pop(t, cta + 0.15, 0.4), Math.sin(t * 4) * 0.02, () => txt('KLO-BLOCKIERER', 0, 0, 116, YELLOW, { stroke: 20, maxW: 980 }));
  at(540, 550, pop(t, cta + 0.3, 0.4), 0, () => txt('in deinem Leben', 0, 0, 66, INK, { weight: 900 }));
  if (t >= cta + 0.4) {
    const p = eOut(prog(t, cta + 0.4, 0.7));
    ctx.save();
    P(); ctx.moveTo(880, 600); ctx.bezierCurveTo(1060, 760, 1060, 1100, 1000, 1360);
    ctx.setLineDash([2400, 2400]); ctx.lineDashOffset = 2400 * (1 - p) + 1600 * (1 - p);
    ctx.lineWidth = 26; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.stroke();
    ctx.lineWidth = 14; ctx.strokeStyle = RED; ctx.stroke();
    ctx.restore();
    if (p > 0.95) arrowHead(1000, 1372 + Math.sin(t * 8) * 8, Math.PI / 2 + 0.25, 34, RED);
  }
  at(540, 700, pop(t, C('arzt') - 0.3, 0.4), 0, () => {
    const w = tw('Bei Dauerproblemen: ab zum Arzt', 38, 800) + 130;
    rr(-w / 2, -40, w, 80, 40); fs(WHITE, 6);
    at(-w / 2 + 48, 0, 1, 0, () => { ctx.fillStyle = RED; ctx.fillRect(-9, -26, 18, 52); ctx.fillRect(-26, -9, 52, 18); });
    txt('Bei Dauerproblemen: ab zum Arzt', 30, 2, 38, INK, { weight: 800 });
  });
  const endT = E('o4') + 0.15;
  at(540, 1470, pop(t, endT, 0.45), 0, () => {
    txt('Folge 2?', 0, -40, 72, WHITE, { stroke: 14 });
    txt('Schreib’s in die Kommentare', 0, 40, 46, WHITE, { stroke: 11 });
  });
}


window.EP_SCENES = { hook: sceneHook, problem: sceneProblem, phone: scenePhone, posture: scenePosture, method: sceneMethod, tips: sceneTips, outro: sceneOutro };
window.EP_STAMPS = ['stamp1', 'stamp2', 'nirgendwo'];
