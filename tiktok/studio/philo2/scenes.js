'use strict';
/* PHILOSOPHIE #2 – Epiktet: Was liegt in deiner Macht? */
const GY = 1195;
const EPI = { beard: 'short', robe: BLK };
function emoji(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
function stool(x) { rr(x - 90, GY - 150, 180, 22, 8); fs(CREAM, 5, BLK); for (const k of [-1, 1]) { seg(x + k * 70, GY - 130, x - k * 60, GY, 8, BLK); } }
function crackLines(x, y, p) { alpha(p, () => { for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; seg(x + Math.cos(a) * 40, y + Math.sin(a) * 40, x + Math.cos(a) * (70 + 40 * p), y + Math.sin(a) * (70 + 40 * p), 8, CREAM); } }); }

function hook(t, lt) {
  ground(GY);
  const kn = C('knack'), broken = t >= kn, tw = t > T('e1') + 0.4 && !broken;
  stool(330);
  // Epiktet sitzt, Bein wird hochgehalten und verdreht
  fig(300, GY, 1.0, Object.assign({}, EPI, { pose: 'sit', legOut: broken ? 70 : 140, footY: broken ? -20 : -120, aF: [1.0, 1.2], eye: 'calm', mouth: 0 }));
  // Herr (größer, purpur), beugt sich vor und hält den Fuß
  at(730, GY, 1, broken ? -0.15 : -0.35, () => fig(0, 0, 1.15, { dir: -1, beard: 'short', robe: PURP, aF: broken ? [0.3, 0.2] : [0.55, 0.25], aB: broken ? [0.1, 0.2] : [0.45, 0.35], eye: broken ? 'wide' : 'open' }));
  if (tw) for (let i = 0; i < 2; i++) { const a = t * 5 + i * Math.PI; P(); ctx.arc(560, GY - 120, 62, a, a + 1.6); ctx.lineWidth = 7; ctx.strokeStyle = CREAM; ctx.stroke(); }
  if (t >= C('ruhig') - 0.05 && !broken) sbubble(['Wenn du so weitermachst,', 'brichst du es.'], 380, 620, pop(t, C('ruhig') - 0.05, 0.4), { size: 46, tail: -80, tdx: -20 });
  if (broken) {
    crackLines(500, GY - 60, 1 - prog(t, kn + 0.4, 0.4));
    at(760, 540, pop(t, kn - 0.05, 0.3), 0.1, () => stxt('KNACK!', 0, 0, 96, CREAM, { stroke: 14 }));
    if (t >= C('gesagt') - 0.05) sbubble('Hab ich doch gesagt.', 360, 680, pop(t, C('gesagt') - 0.05, 0.4), { size: 50, tail: -80, tdx: -20 });
  }
}
function intro(t, lt) {
  at(540, 1190, 1, 0, () => fig(0, 0, 1.3, Object.assign({}, EPI, { hold: 'staff', aF: [0.5, 0.5], eye: 'calm' })));
  at(540, 540, pop(t, T('e3'), 0.4), 0, () => { stxt('ἘΠΊΚΤΗΤΟΣ', 0, -50, 40, BLK, { ls: 6 }); stxt('EPIKTET', 0, 30, 110, CREAM, { stroke: 12 }); });
  at(540, 680, pop(t, T('e3') + 0.3, 0.4), 0, () => pill('ca. 50–135 n. Chr. · Römisches Reich', 0, 0, 30, BLK, CREAM, { lw: 0 }));
  if (t >= C('sklave') - 0.05) {
    chainIcon(540, 900, 0.8 * pop(t, C('sklave') - 0.05, 0.4));
    at(820, 820, pop(t, C('sklave'), 0.35), -0.15, () => { rr(-130, -46, 260, 92, 10); fs(null, 8, PURP); stxt('SKLAVE', 0, 2, 54, PURP); });
  }
  alpha(0.85, () => stxt('Quelle: Kelsos, zitiert bei Origenes', 540, 1225, 26, BLK));
}
function frei(t, lt) {
  ground(GY);
  for (let i = 0; i < 5; i++) column(150 + i * 195, GY, 600, 0.75);
  fig(420, GY, 1.0, Object.assign({}, EPI, { hold: 'staff', aF: [1.5, 0.3], aB: [0.2, 0.3], eye: 'open', mouth: 0.3 * (Math.sin(t * 9) > 0.3) }));
  child(700, GY, 1.1, { pose: 'sit', dir: -1, eye: 'open' }); child(860, GY, 1.1, { pose: 'sit', dir: -1, eye: 'open', robe: PURP });
  const br = eOut(prog(t, C('frei'), 0.6));
  if (br < 1) chainIcon(540, 760, 0.7, br);
  at(540, 520, pop(t, C('frei') + 0.3, 0.4), 0, () => stxt('frei – und Lehrer der Stoa', 0, 0, 56, CREAM, { stroke: 10 }));
}
const ITEMS_J = [['j1', '💭', 'Gedanken'], ['j2', '⚖️', 'Entscheidungen'], ['j3', '🎭', 'Reaktion']];
const ITEMS_N = [['n1', '🌧️', 'Wetter'], ['n2', '🚗', 'Stau'], ['n3', '🗣️', 'Meinung anderer']];
function macht(t, lt) {
  const pL = pop(t, T('e5') + 0.2, 0.4), pR = pop(t, C('nicht') - 0.05, 0.4);
  at(290, 850, pL, 0, () => {
    rr(-235, -380, 470, 760, 30); fs(CREAM, 8, BLK);
    stxt('IN DEINER', 0, -320, 44, BLK); stxt('MACHT ✓', 0, -268, 52, '#2b8a3e');
    seg(-180, -230, 180, -230, 4, BLK);
  });
  at(790, 850, pR, 0, () => {
    rr(-235, -380, 470, 760, 30); fs(BLK, 8, CREAM);
    stxt('NICHT IN DEINER', 0, -320, 40, CREAM); stxt('MACHT ✗', 0, -268, 52, '#ff8787');
    seg(-180, -230, 180, -230, 4, CREAM);
  });
  const drop = (list, x, dark) => list.forEach(([cue, e, label], i) => {
    if (!TL.cues[cue] || t < C(cue) - 0.08) return;
    const p = eOut(prog(t, C(cue) - 0.08, 0.35)), y = lerp(480, 720 + i * 170, p);
    alpha(clamp(p * 2), () => { emoji(e, x - 150, y, 80); stxt(label, x + 45, y + 4, 40, dark ? CREAM : BLK, { maxW: 270 }); });
  });
  drop(ITEMS_J, 290, false); drop(ITEMS_N, 790, true);
}
function zitat(t, lt) {
  fig(160, GY, 0.8, Object.assign({}, EPI, { hold: 'staff', aF: [0.6, 0.5], eye: 'calm' }));
  ground(GY);
  quoteCard(['„Nicht die Dinge', 'beunruhigen uns,', 'sondern unsere Meinungen', 'über die Dinge.“'], '— Epiktet, Handbüchlein der Moral', 600, 760, pop(t, C('zitat') + 0.5, 0.45), { size: 52, w: 820 });
}
function nehmen(t, lt) {
  ground(GY);
  const glow = prog(t, C('ruhe') - 0.05, 0.6);
  if (glow > 0) alpha(glow, () => { const g = ctx.createRadialGradient(540, 960, 40, 540, 960, 420); g.addColorStop(0, 'rgba(255,211,107,0.8)'); g.addColorStop(1, 'rgba(255,211,107,0)'); ctx.fillStyle = g; ctx.fillRect(100, 500, 880, 760); });
  fig(540, GY, 1.1, Object.assign({}, EPI, { hold: 'staff', aF: [0.5, 0.4], eye: 'calm' }));
  const tag = (cue, x, y, txtS, ok) => { if (t < C(cue) - 0.05) return; at(x, y, pop(t, C(cue) - 0.05, 0.35), ok ? 0 : -0.08, () => { rr(-170, -44, 340, 88, 44); fs(ok ? GOLD : BLK, 5, BLK); stxt(txtS, 0, 3, 40, ok ? BLK : CREAM); }); };
  tag('f1', 230, 640, 'Freiheit ✗', false);
  tag('f2', 850, 640, 'Bein ✗', false);
  if (t >= C('f2') - 0.05) crackLines(560, GY - 90, 1 - prog(t, C('f2') + 0.3, 0.4));
  tag('ruhe', 540, 520, 'Ruhe ✓', true);
}
function cta(t, lt) {
  fig(540, GY, 1.0, Object.assign({}, EPI, { hold: 'staff', aF: [0.5, 0.4], eye: 'calm' }));
  ground(GY);
  at(540, 600, pop(t, C('cta') - 0.05, 0.4), 0, () => { stxt('Worüber ärgerst du dich –', 0, 0, 56, CREAM, { stroke: 12 }); stxt('obwohl du’s nicht ändern kannst? 👇', 0, 72, 46, CREAM, { stroke: 10 }); });
  at(540, 760, pop(t, C('cta') + 1.0, 0.4), 0, () => pill('Nächste Folge: Das Schiff des Theseus', 0, 0, 32, BLK, CREAM, { lw: 0 }));
}
const SCN = [['e1', hook], ['e3', intro], ['e4', frei], ['e5', macht], ['e8', zitat], ['e9', nehmen], ['e10', cta]];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  vaseBg();
  ctx.save(); ctx.beginPath(); ctx.rect(0, 432, W, 830); ctx.clip();
  sceneAt(t, SCN);
  ctx.restore();
  frame('PHILOSOPHIE #2', 'Der Sklave, den nichts brach');
  drawCaptions(t);
};
window.EP_SCENES = {};
