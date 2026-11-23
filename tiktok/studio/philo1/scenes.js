'use strict';
/* PHILOSOPHIE #1 – Diogenes: „Geh mir aus der Sonne.“ */
const GY = 1195;
const DIO = { beard: 'long', robe: BLK };
function cueP(name, d = 0.35) { return pop(window.__t, C(name) - 0.05, d); }
function shadowWedge(x0, a) { alpha(a, () => { P(); ctx.moveTo(x0, 700); ctx.lineTo(x0 - 520, GY + 20); ctx.lineTo(x0 - 80, GY + 20); ctx.closePath(); ctx.fillStyle = 'rgba(28,18,12,0.45)'; ctx.fill(); }); }

/* Diogenes sitzt vor seinem Pithos und sonnt sich */
function dioLying(x, t, o = {}) {
  pithos(x - 90, GY - 175, 0.9);
  at(x + 170, GY, 1, -0.12, () => fig(0, 0, 0.92, Object.assign({}, DIO, { pose: 'sit', dir: 1, aF: [1.1, 1.3], aB: [-0.6, 0.2], eye: o.eye || 'calm' })));
}
function alexFig(x, t, o = {}) {
  fig(x + 60, GY, 1.05, Object.assign({ dir: -1, helmet: true, cloak: PURP, hold: 'spear', aF: [0.5, -0.6], ph: t, robe: BLK }, o));
}

function hook(t, lt) {
  sunDisc(930, 590, 62, t);
  ground(GY);
  shadowWedge(780, 1);
  dioLying(330, t, { eye: t > C('sonne') - 0.1 ? 'open' : 'calm' });
  alexFig(800, t, { aF: [1.3, 0.1], mouth: t < C('sonne') ? 0.4 * (Math.sin(t * 18) > 0) : 0 });
  if (lt < C('sonne') - T('d1')) sbubble('Wünsch dir was!', 640, 630, pop(t, 0.3, 0.35), { tail: 40, tdx: 30 });
  if (t >= C('sonne') - 0.05) {
    sbubble(['Geh mir aus', 'der Sonne.'], 330, 760, pop(t, C('sonne') - 0.05, 0.4), { size: 58, tail: -40, tdx: -10 });
  }
}
function intro(t, lt) {
  sunDisc(900, 1000, 50, t, 0.6);
  at(540, 1180, 1, 0, () => fig(0, 0, 1.35, Object.assign({}, DIO, { aF: [0.6, 0.6], hold: 'staff', eye: 'open', mouth: 0 })));
  at(540, 560, pop(t, T('d2'), 0.4), 0, () => { stxt('ΔΙΟΓΕΝΗΣ', 0, -50, 44, BLK, { ls: 8 }); stxt('DIOGENES', 0, 30, 110, CREAM, { stroke: 12 }); });
  at(540, 700, pop(t, T('d2') + 0.3, 0.4), 0, () => pill('Griechenland · 4. Jh. v. Chr.', 0, 0, 32, BLK, CREAM, { lw: 0 }));
  if (t >= C('title') - 0.05) at(820, 960, pop(t, C('title') - 0.05, 0.4), 0.12, () => { rr(-170, -70, 340, 140, 20); fs(GOLD, 6, BLK); stxt('der frechste', 0, -24, 40, BLK); stxt('Philosoph', 0, 28, 46, BLK); });
}
function tonne(t, lt) {
  ground(GY);
  const k = C('krug');
  if (t < k) {
    const p = pop(t, T('d3'), 0.45);
    at(540, GY, p, 0, () => { barrel(0, 0, 1.25); fig(0, -260 * 1.25 + 60, 0.75, Object.assign({}, DIO, { aF: [2.4, 0.3], aB: [-2.4, -0.3], eye: 'open' })); });
    at(540, 560, p, 0, () => stxt('„Die Tonne“', 0, 0, 72, CREAM, { stroke: 10 }));
  } else {
    const p = pop(t, k - 0.05, 0.45);
    alpha(1 - prog(t, k - 0.05, 0.25), () => at(540, GY, 1.25 - 0.4 * prog(t, k - 0.05, 0.25), 0.4 * prog(t, k - 0.05, 0.25), () => barrel(0, 0, 1)));
    at(520, GY - 210, p, 0, () => { pithos(0, 0, 1.25); fig(150, 120, 0.55, Object.assign({}, DIO, { pose: 'sit', dir: 1, aF: [1.2, 0.8], eye: 'calm' })); });
    at(540, 560, p, 0, () => { stxt('eigentlich: ein Pithos', 0, 0, 64, CREAM, { stroke: 10 }); stxt('(riesiger Tonkrug)', 0, 70, 40, BLK); });
    // altes Wort durchgestrichen
    alpha(1 - prog(t, k + 0.6, 0.3), () => { stxt('„Die Tonne“', 540, 470, 46, CREAM, { stroke: 8 }); seg(400, 470, 680, 470, 8, PURP); });
  }
}
function besitz(t, lt) {
  ground(GY);
  const kd = C('kind'), wg = C('weg');
  const throwP = prog(t, wg - 0.05, 0.6);
  fig(260, GY, 1.0, Object.assign({}, DIO, { hold: t < wg ? 'bowl' : null, aF: t < wg ? [1.3, 0.4] : [2.6, 0.3], eye: t > kd + 0.3 ? 'wide' : 'open' }));
  if (t < kd) {
    at(720, 700, pop(t, C('besitz'), 0.4), 0, () => { rr(-210, -130, 420, 260, 24); fs(CREAM, 6, BLK); stxt('BESITZ:', 0, -70, 44, TERRA_D); stxt('1 Mantel', 0, 0, 52, BLK); stxt('1 Schale', 0, 70, 52, BLK); });
  } else {
    // Brunnen mit Löwenkopf rechts, Kind trinkt aus den Händen
    rr(900, GY - 420, 160, 420, 8); fs(CREAM, 6, BLK); circ(900, GY - 330, 44); fs(BLK, 0);
    P(); ctx.moveTo(872, GY - 320); ctx.quadraticCurveTo(820, GY - 300, 805, GY - 215); ctx.lineWidth = 12; ctx.strokeStyle = '#8fd3ff'; ctx.stroke();
    child(700, GY, 1.15, { dir: 1, aF: [1.9, -0.2], aB: [1.7, 0.0], eye: 'closed' });
    for (let i = 0; i < 4; i++) { const u = (t * 2 + i / 4) % 1; circ(812 - u * 10, GY - 215 + u * 50, 6); ctx.fillStyle = '#8fd3ff'; ctx.fill(); }
    if (t < wg + 0.3) at(560, 520, pop(t, kd, 0.4), 0, () => stxt('Ein Kind trinkt aus den Händen', 0, 0, 50, CREAM, { stroke: 9 }));
  }
  if (t >= wg - 0.05) {
    const u = throwP, bx = lerp(390, 520, u), by = lerp(GY - 300, GY - 10, u * u);
    if (u < 1) at(bx, by, 1, u * 8, () => { P(); ctx.ellipse(0, 0, 46, 22, 0, 0, Math.PI); fs(CREAM, 5, BLK); });
    else for (let i = 0; i < 7; i++) { const a = -Math.PI * (0.1 + rnd(i) * 0.8), r = 40 + 110 * eOut(prog(t, wg + 0.55, 0.4)); at(520 + Math.cos(a) * r, GY - 10 + Math.sin(a) * r * 0.5, 1, rnd(i + 2) * 6, () => { P(); ctx.moveTo(-14, 0); ctx.lineTo(12, -8); ctx.lineTo(6, 10); ctx.closePath(); fs(CREAM, 3, BLK); }); }
    if (t >= wg + 0.3) at(560, 520, pop(t, wg + 0.3, 0.4), -0.04, () => { rr(-300, -50, 600, 100, 20); fs(CREAM, 6, BLK); stxt('Besitz: 1 Mantel. Fertig.', 0, 3, 48, BLK); });
  }
}
function platon(t, lt) {
  ground(GY);
  column(130, GY, 560, 0.9); column(950, GY, 560, 0.9);
  const hu = C('huhn'), se = C('seht');
  alpha(1 - prog(t, hu - 0.05, 0.3), () => { rr(60, 560, 960, 60, 6); fs(CREAM, 5, BLK); stxt('AKADEMIE', 540, 592, 38, BLK, { ls: 10 }); });
  fig(750, GY, 1.05, { dir: -1, beard: 'long', robe: PURP, aF: t < hu ? [1.4, 0.5] : [0.4, 0.2], eye: t > se ? 'wide' : 'open', mouth: t > se ? 0.6 : 0 });
  stxt('PLATON', 750, GY + 34, 30, BLK);
  if (t < hu) {
    at(390, 790, pop(t, T('d5') + 0.3, 0.4), 0, () => { rr(-300, -100, 600, 200, 24); fs(CREAM, 6, BLK); stxt('Mensch =', 0, -50, 40, TERRA_D); stxt('federloses Wesen', 0, 4, 54, BLK); stxt('auf zwei Beinen', 0, 60, 54, BLK); });
  } else {
    const inn = eOut(prog(t, hu - 0.05, 0.6));
    fig(lerp(-150, 270, inn), GY, 1.0, Object.assign({}, DIO, { pose: inn < 1 ? 'walk' : 'stand', ph: t * 1.5, hold: 'chicken', aF: [2.2, 0.2], chickRot: 0, eye: 'open', mouth: t > se ? 0.7 : 0 }));
    if (t >= se - 0.05) {
      at(740, 540, pop(t, se - 0.05, 0.4), -0.04, () => { stxt('„SEHT HER:', 0, 0, 62, CREAM, { stroke: 12, maxW: 540 }); stxt('PLATONS MENSCH!“', 0, 72, 62, CREAM, { stroke: 12, maxW: 540 }); });
      at(860, 720, pop(t, se + 0.2, 0.3), 0, () => stxt('!?', 0, 0, 80, PURP, { stroke: 8, sc: CREAM }));
    }
  }
}
function alex(t, lt) {
  sunDisc(930, 590, 62, t);
  ground(GY);
  const inn = eOut(prog(t, T('d7') + 0.2, 1.6));
  const ax = lerp(1250, 800, inn);
  if (inn > 0.4) shadowWedge(ax - 20, clamp((inn - 0.4) * 2));
  dioLying(330, t, { eye: 'calm' });
  alexFig(ax, t, { pose: inn < 1 ? 'walk' : 'stand', ph: t * 1.3, aF: t > C('wunsch') ? [1.4, 0.1] : [0.5, -0.6], mouth: t > C('wunsch') && t < E('d7') ? 0.4 * (Math.sin(t * 18) > 0) : 0 });
  at(420, 480, pop(t, T('d7') + 0.6, 0.4), 0, () => pill('ALEXANDER DER GROSSE', 0, 0, 34, BLK, GOLD, { lw: 0 }));
  if (t >= C('wunsch') - 0.05) sbubble(['Wünsch dir,', 'was du willst!'], 660, 650, pop(t, C('wunsch') - 0.05, 0.4), { tail: 60, tdx: 40 });
}
function aus(t, lt) {
  sunDisc(930, 590, 62, t);
  ground(GY);
  shadowWedge(780, 1);
  dioLying(330, t, { eye: t > C('blinz') + 0.2 ? 'open' : 'calm' });
  alexFig(800, t, { aF: [1.4, 0.1], eye: t > C('aus') + 0.3 ? 'wide' : 'open' });
  if (t >= C('aus') - 0.05) sbubble(['Geh mir ein bisschen', 'aus der Sonne.'], 380, 760, pop(t, C('aus') - 0.05, 0.4), { size: 50, tail: -60, tdx: -10 });
}
function quote(t, lt) {
  sunDisc(930, 590, 62, t);
  ground(GY);
  dioLying(330, t, { eye: 'calm' });
  const step = eOut(prog(t, T('d9'), 0.8));
  alexFig(lerp(800, 960, step), t, { aF: [0.9, 0.6], eye: 'open' });
  quoteCard(['„Wäre ich nicht Alexander,', 'wollte ich Diogenes sein.“'], '— Alexander (nach Plutarch)', 540, 660, pop(t, C('wollte') - 0.6, 0.45), { size: 50, w: 940 });
}
function lehre(t, lt) {
  sunDisc(760, 860, 80, t);
  ground(GY);
  fig(480, GY, 1.0, Object.assign({}, DIO, { pose: 'sit', aF: [1.0, 1.2], aB: [-0.3, 0.2], eye: 'calm' }));
  at(540, 520, pop(t, T('d10') + 0.4, 0.4), 0, () => stxt('Wer wenig braucht, ist frei.', 0, 0, 62, CREAM, { stroke: 12 }));
  if (t >= C('sklave') - 0.05) at(540, 625, pop(t, C('sklave') - 0.05, 0.4), 0, () => { rr(-440, -46, 880, 92, 46); ctx.fillStyle = BLK; ctx.fill(); stxt('Wer alles will, wird Sklave seiner Wünsche.', 0, 2, 40, GOLD, { maxW: 840 }); });
}
function cta(t, lt) {
  sunDisc(540, 620, 80, t, 0.7);
  pithos(540, 820, 0.8);
  at(540, 1030, pop(t, C('cta') - 0.05, 0.4), 0, () => stxt('Was könntest du weglassen? 👇', 0, 0, 58, CREAM, { stroke: 12 }));
  at(540, 1150, pop(t, C('cta') + 0.8, 0.4), 0, () => pill('Nächste Folge: der Sklave, den nichts brechen konnte', 0, 0, 30, BLK, CREAM, { lw: 0 }));
}
const SCN = [['d1', hook], ['d2', intro], ['d3', tonne], ['d4', besitz], ['d5', platon], ['d7', alex], ['d8', aus], ['d9', quote], ['d10', lehre], ['d11', cta]];
window.renderFrame = function (t) {
  window.__t = t;
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  vaseBg();
  ctx.save(); ctx.beginPath(); ctx.rect(0, 432, W, 830); ctx.clip();
  sceneAt(t, SCN);
  ctx.restore();
  frame('PHILOSOPHIE #1', 'Der frechste Philosoph');
  drawCaptions(t);
};
window.EP_SCENES = {};
