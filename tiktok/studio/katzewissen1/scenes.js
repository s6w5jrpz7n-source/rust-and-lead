'use strict';
/* 5 katzen-signale, die du kennen musst – Speicher-Video */
const EV = TL.data.ev;
const KEYS = ['s1', 's2', 's3', 's4', 's5'];
const SIG = [
  { title: 'langsames blinzeln', mean: ['= „ich vertraue dir“ ❤️'] },
  { title: 'schwanz senkrecht hoch', mean: ['= „schön, dass du da bist!“'] },
  { title: 'bauch zeigen', mean: ['= „ich vertraue dir“', '(keine einladung zum kraulen!)'] },
  { title: 'treteln', mean: ['= „mir geht’s richtig gut“'] },
  { title: 'köpfchen geben', mean: ['= „du gehörst jetzt mir“ 😼'] },
];
function hand(x, y, s, rot) {
  at(x, y, s, rot, () => {
    rr(0, -60, 260, 120, 50); fs(SKIN, 6, '#8a5a3c');
    for (let i = 0; i < 4; i++) { rr(-70 + i * 8, -58 + i * 30, 110, 34, 17); fs(SKIN, 5, '#8a5a3c'); }
    rr(180, -70, 200, 140, 20); fs('#4c6ef5', 6, '#1c2b6b');
  });
}
function textLine(s, x, y, size, col) {
  ctx.save(); ctx.font = `800 ${size}px ${FONT}, "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  const w = ctx.measureText(s).width; if (w > 960) { ctx.translate(x, y); ctx.scale(960 / w, 960 / w); ctx.translate(-x, -y); }
  ctx.lineWidth = 10; ctx.strokeStyle = '#000'; ctx.lineJoin = 'round'; ctx.strokeText(s, x, y); ctx.fillStyle = col; ctx.fillText(s, x, y); ctx.restore();
}
function hearts(t, t0, x, y) {
  if (t < t0) return;
  for (let i = 0; i < 4; i++) { const u = prog(t, t0 + i * 0.18, 1.1); if (u <= 0 || u >= 1) continue; alpha(1 - u, () => emo('❤️', x + (i % 2 ? 1 : -1) * (150 + rnd(i) * 60), y - u * 140, 54 + i * 6)); }
}
function illu(i, t, lt) {
  if (i === 0) { // langsames Blinzeln
    const c = lt < 0.6 ? 0 : lt < 1.3 ? eIO(prog(lt, 0.6, 0.7)) : lt < 1.7 ? 1 : 1 - eIO(prog(lt, 1.7, 0.6));
    catHead(540, 900, 1.15, { t, lid: c * 0.95, pupil: 14 });
    hearts(t, EV.s1 + 1.9, 540, 800);
    if (lt > 0.6 && lt < 1.9) txt('l a n g s a m …', 540, 1150, 40, '#495057', { weight: 800 });
  } else if (i === 1) { // Schwanz hoch
    ctx.fillStyle = '#e9dcc6'; ctx.fillRect(0, 1230, W, 20);
    const cx = lerp(380, 640, prog(lt, 0, 3));
    catRun(cx, 1230, 0.72, lt * 0.9, 1, { tailUp: true, t });
    at(cx - 260, 690, pop(t, EV.s2 + 0.8, 0.35), 0, () => { txt('wie ein ?', -10, -40, 40, '#e64980', { weight: 900 }); seg(0, 0, 60, 90, 8, '#e64980'); arrowHead(64, 96, Math.atan2(90, 60), 22, '#e64980'); });
  } else if (i === 2) { // Bauch zeigen
    rr(140, 1150, 800, 70, 30); fs('#d0bfff', 6, '#5f3dc4');
    catBelly(600, 1190, 0.9, { t, lid: lt < 1.4 ? 0.3 : 0, pupil: lt < 1.4 ? 12 : 34 });
    if (lt > 0.9) { const u = prog(lt, 0.9, 0.5); hand(lerp(1150, 720, eOut(u)), 950, 0.9, -0.3); }
    if (lt > 1.5) { at(640, 760, pop(t, EV.s3 + 1.5, 0.3), -0.1, () => txt('*ZACK*', 0, 0, 72, '#c92a2a', { stroke: 10, sc: WHITE, weight: 900 })); for (let k = 0; k < 6; k++) { const a = k / 6 * Math.PI * 2 + lt; seg(760 + Math.cos(a) * 60, 950 + Math.sin(a) * 60, 760 + Math.cos(a) * 110, 950 + Math.sin(a) * 110, 8, '#fab005'); } }
  } else if (i === 3) { // Treteln
    ell(540, 1215, 420, 60); fs('#ffc9c9', 6, '#c92a2a'); for (let k = 0; k < 7; k++) circ(200 + k * 112, 1215, 14), ctx.fillStyle = '#ffe3e3', ctx.fill();
    const ph = lt * 2.6 * Math.PI * 2, up = s => Math.max(0, Math.sin(ph + s)) * 46;
    catSit(540, 1190, 0.62, { t, pawL: [-70, -14 - up(0)], pawR: [70, -14 - up(Math.PI)], lid: 0.6, pupil: 12 });
    for (let k = 0; k < 3; k++) { const u = (lt * 0.8 + k / 3) % 1; alpha(Math.sin(u * Math.PI), () => txt('prrr', 820 + u * 30, 860 - u * 140, 34, '#495057', { weight: 800 })); }
  } else { // Köpfchen geben
    const bump = Math.max(0, Math.sin(lt * Math.PI * 1.6)) ** 2;
    hand(700 - bump * 18, 860, 1, 0.15);
    catHead(lerp(430, 520, bump), 950 - bump * 20, 0.95, { t, tilt: 0.35 * bump, lid: 0.4 + 0.4 * bump, pupil: 12 });
    for (const tb of [0.32, 1.57, 2.82]) hearts(t, EV.s5 + tb, 600, 820);
  }
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#fff4e6'); g.addColorStop(1, '#ffe8cc'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  dots(t, '#f08c00', 0.08, 3);
  pill('katzen-wissen', 540, 168, 30, '#f08c00', WHITE, { lw: 0 });
  drangCaption(['5 katzen-signale,', 'die du kennen musst 😼']);
  let idx = -1; KEYS.forEach((k, i) => { if (t >= EV[k]) idx = i; });
  if (t < EV.card) {
    // Fortschritt
    for (let i = 0; i < 5; i++) { const x = 540 + (i - 2) * 72; circ(x, 420, 26); fs(i <= idx ? '#f08c00' : WHITE, 5, '#f08c00'); txt(String(i + 1), x, 422, 28, i <= idx ? WHITE : '#f08c00', { weight: 900 }); }
    const lt = t - EV[KEYS[idx]], sl = 1 - eOut(prog(lt, 0, 0.3));
    ctx.save(); ctx.translate(sl * W, 0);
    rr(60, 480, 960, 1000, 50); fs(WHITE, 0); rr(60, 480, 960, 1000, 50); fs(null, 6, '#ffd8a8');
    txt(`${idx + 1}. ${SIG[idx].title}`, 540, 560, 60, INK, { weight: 900, maxW: 900 });
    ctx.save(); rr(60, 480, 960, 1000, 50); ctx.clip(); illu(idx, t, lt); ctx.restore();
    SIG[idx].mean.forEach((m, k) => at(540, 1330 + k * 66, pop(t, EV[KEYS[idx]] + 0.5 + k * 0.25, 0.35), 0, () => textLine(m, 0, 0, k ? 40 : 50, k ? '#ffe066' : WHITE)));
    ctx.restore();
  } else {
    const p = pop(t, EV.card, 0.4);
    at(540, 760, p, 0, () => { rr(-420, -150, 840, 300, 50); fs(WHITE, 6, '#f08c00'); emo('📌', -300, 0, 110); txt('speichern', 60, -40, 84, INK, { weight: 900 }); txt('für später', 60, 50, 50, '#868e96', { weight: 800 }); });
    at(540, 1050, pop(t, EV.card + 0.35, 0.4), 0, () => textLine('welches signal kennst du? 👇', 0, 0, 52, WHITE));
    at(540, 1160, pop(t, EV.card + 0.6, 0.4), 0, () => textLine('schick’s jemandem mit katze 😼', 0, 0, 46, '#ffe066'));
    catLoaf(560, 1470, 0.45, { t, lid: blinkLid(t, EV.card + 0.8) * 0.9, pupil: 14 });
  }
};
window.EP_SCENES = {};
