'use strict';
/* STORYTIME – „Der Nice Guy“ */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { I: '#74c0fc', K: '#ffa94d' };
const ICH = { stand: true, shirt: '#2f9e44', hood: '#2b8a3e', pants: '#343a40', hair: 'slick', hairCol: '#5c3d2e', browCol: '#3b2a20' };
const KOL = { stand: true, shirt: '#e9ecef', collar: WHITE, tie: '#c92a2a', pants: '#1c3d5a', hair: 'slick', hairCol: '#e0b84f', browCol: '#b8902a' };
const FRAU = { stand: true, shirt: '#f783ac', pants: '#495057', skirt: '#ffd8e8', hair: 'long', hairCol: '#6b3a1e', browCol: '#3b2314', lips: '#e64980', earrings: true };
const MAMA = { stand: true, shirt: '#9c36b5', pants: '#5f3dc4', skirt: '#9c36b5', hair: 'bun', hairCol: '#dee2e6', browCol: '#adb5bd', glasses: true, skin: SKIN_OLD };
function office(t) {
  bg('#dbe4f0', '#c5d3e6');
  rr(80, 420, 360, 300, 10); fs('#a5d8ff', 10, '#f8f9fa'); seg(260, 420, 260, 720, 8, '#f8f9fa');
  rr(640, 430, 300, 200, 8); fs('#fff', 5, '#adb5bd'); txt('TEAMBUILDING', 790, 500, 30, '#1c7ed6'); txt('FREITAG! 🎉', 790, 560, 34, '#e64980');
  ctx.fillStyle = '#868e96'; ctx.fillRect(-80, 1150, W + 160, 900); seg(-80, 1150, W + 80, 1150, 8, '#495057');
  rr(860, 760, 160, 380, 14); fs('#343a40', 6); rr(890, 800, 100, 80, 8); fs('#74c0fc', 4); circ(940, 950, 18); fs('#e03131', 4); rr(900, 1040, 80, 70, 8); fs('#212529', 4);
  rr(40, 980, 120, 170, 10); fs('#c97b4a', 5); for (const [dx, dy] of [[-30, -40], [0, -70], [30, -40]]) { ell(100 + dx, 980 + dy, 40, 60, dx * 0.01); fs('#40c057', 5); }
}
function dog(x, y, s, o = {}) {
  const t = o.t || 0;
  at(x, y, s, o.dead ? 0 : 0, () => {
    if (o.dead) {
      ell(0, -40, 150, 55); fs('#c08552', 6); circ(-150, -60, 60); fs('#c08552', 6);
      for (const dx of [-170, -130]) { seg(dx - 10, -76, dx + 10, -56, 6); seg(dx + 10, -76, dx - 10, -56, 6); }
      for (const lx of [-80, -20, 60, 110]) limb(lx, -10, lx + 20, 20, 22, '#c08552');
      ell(-150, -150, 60, 16); ctx.lineWidth = 8; ctx.strokeStyle = '#ffd43b'; ctx.stroke();
      return;
    }
    const wag = Math.sin(t * 14) * 0.5;
    at(120, -110, 1, -0.6 + wag, () => { seg(0, 0, 70, -60, 18); seg(0, 0, 70, -60, 10, '#c08552'); });
    for (const lx of [-90, -40, 50, 100]) limb(lx, -60, lx, 0, 24, '#c08552');
    ell(0, -110, 140, 70); fs('#c08552', 6);
    circ(-130, -170, 70); fs('#c08552', 6);
    for (const sd of [-1, 1]) { ell(-130 + sd * 62, -170, 26, 50, sd * 0.3); fs('#8a5a32', 5); }
    circ(-155, -185, 10); fs(INK, 0); circ(-105, -185, 10); fs(INK, 0); ell(-130, -150, 16, 12); fs(INK, 0);
    ell(-130, -118, 14, 22); fs('#ff8787', 4);
  });
}
function figK(t, x, y, s, o = {}) { figur(x, y, s, Object.assign({ t, mood: o.mood || 'smug', mouth: mouthOf('K', t) * (o.bigMouth ? 1.8 : 1), lookX: o.lookX ?? 0 }, KOL, o.extra || {})); }
function figI(t, x, y, s, o = {}) { figur(x, y, s, Object.assign({ t, mood: o.mood || 'neutral', mouth: mouthOf('I', t), lookX: o.lookX ?? 0 }, ICH, o.extra || {})); }
function stampT(t, t0, s, x, y, col = '#e03131', rot = -0.12) {
  if (t < t0) return;
  at(x, y, lerp(2, 1, eOut(prog(t, t0, 0.25))), rot, () => alpha(clamp(prog(t, t0, 0.1) * 3), () => { const w = tw(s, 58, 900) + 50; rr(-w / 2, -50, w, 100, 10); fs('rgba(255,255,255,0.85)', 8, col); txt(s, 0, 4, 58, col); }));
}
function pixelate(x, y, w, h, t) {
  const cs = 26, cols = ['#f2c7a5', '#e8b894', '#d9a383', '#c98f6f'];
  for (let i = 0; i < w / cs; i++) for (let j = 0; j < h / cs; j++) { ctx.fillStyle = cols[Math.floor(rnd(i * 7 + j * 13 + Math.floor(t * 6)) * 4)]; ctx.fillRect(x + i * cs, y + j * cs, cs, cs); }
}
function graveyard(t) {
  bg('#2b2d42', '#4a4e69');
  circ(820, 480, 80); fs('#f1f3f5', 0);
  ctx.fillStyle = '#2f3e46'; ctx.fillRect(-80, 1100, W + 160, 900);
  for (const [x, h] of [[120, 220], [300, 180], [760, 200], [940, 240]]) { P(); ctx.moveTo(x - 70, 1110); ctx.lineTo(x - 70, 1110 - h + 60); ctx.arc(x, 1110 - h + 60, 70, Math.PI, 0); ctx.lineTo(x + 70, 1110); ctx.closePath(); fs('#adb5bd', 6, '#495057'); txt('R.I.P.', x, 1110 - h + 90, 30, '#495057'); }
  for (const x of [420, 660]) { rr(x - 14, 620, 28, 490, 6); fs('#343a40', 5); }
  P(); ctx.arc(540, 640, 120, Math.PI, 0); ctx.lineWidth = 14; ctx.strokeStyle = '#343a40'; ctx.stroke();
  txt('FRIEDHOF', 540, 560, 40, '#f1f3f5', { stroke: 8 });
  for (let x = 440; x < 660; x += 30) seg(x, 640, x, 1100, 6, '#343a40');
}
const SHOTS = () => [
  [0, (t) => cam(380, 760, 1.6, () => { office(t); figK(t, 820, 1200, 0.85); figI(t, 380, 1200, 0.85, { mood: 'bored' }); })],
  [C('nice') - 0.1, (t) => { office(t); ctx.save(); ctx.shadowColor = '#ffd43b'; ctx.shadowBlur = 60; ell(540, 640, 110, 24); ctx.lineWidth = 12; ctx.strokeStyle = '#ffd43b'; ctx.stroke(); ctx.restore(); figK(t, 540, 1250, 1.05, { mood: 'excited' }); at(540, 430, pop(t, C('nice'), 0.35), -0.04, () => pill('„Ich bin der Nice Guy“ 😇', 0, 0, 46, '#fff', INK, { lw: 6 })); }],
  [T('n2') - 0.1, (t) => { office(t); figur(330, 1220, 0.85, Object.assign({ t, mood: t > T('k1') + 0.6 ? 'shocked' : 'neutral', mouth: 0, lookX: 1 }, FRAU)); figK(t, 760, 1220, 0.85, { mood: 'excited', lookX: -1, extra: { handL: [-150, -250] } }); at(540, 420, pop(t, T('n2'), 0.35), 0, () => pill('„Komplimente“', 0, 0, 44, '#fff', INK, { lw: 6 })); if (t > C('gew') + 0.4) at(300, 560, pop(t, C('gew') + 0.4, 0.3), 0, () => emo('⚖️', 0, 0, 100)); }],
  [T('n3') - 0.1, (t) => { office(t); figI(t, 780, 1220, 0.8, { mood: 'bored', lookX: -1 }); figK(t, 320, 1220, 0.95, { mood: 'excited', bigMouth: true, lookX: 1 }); at(470, 640, 1 + 0.08 * Math.sin(t * 20), 0.3, () => emo('📢', 0, 0, 110)); }],
  [T('k2') - 0.1, (t) => cam(420, 760, 1.9, () => { office(t); figK(t, 420, 1220, 0.95, { mood: 'smug', lookX: 1 }); }) || stampT(t, C('alter'), 'FÜR IHR ALTER 👵', 540, 1180)],
  [T('n4') - 0.1, (t) => { cam(540, 760, 1.9, () => { office(t); figI(t, 540, 1220, 0.95, { mood: 'smug' }); }); at(780, 520, pop(t, T('n4') + 0.2, 0.3), 0, () => emo('🙂', 0, 0, 110)); }],
  [T('n5') - 0.1, (t) => {
    bg('#2b1d3a', '#12081c');
    at(540, 900, 1, 0, () => { rr(-300, -540, 600, 1080, 70); fs('#212529', 10, '#000'); rr(-270, -500, 540, 1000, 40); fs('#fff0f6', 0);
      txt('❤️ SwipeLove', 0, -440, 38, '#e64980'); rr(-220, -380, 440, 520, 30); fs('#f8f9fa', 6, '#dee2e6'); circ(0, -200, 110); fs('#ffd8a8', 5); txt('Seine Ex, 31', 0, 0, 40, INK); txt('2 km entfernt', 0, 50, 26, '#868e96', { weight: 700 });
      if (t > C('status') - 0.1) at(0, 240, pop(t, C('status') - 0.1, 0.35), 0, () => { rr(-250, -80, 500, 160, 24); fs('#fff', 5, '#e64980'); txt('Status: „Suche jemanden, der', 0, -30, 26, INK, { weight: 800 }); txt('wenigstens weiß, wo die', 0, 6, 26, INK, { weight: 800 }); txt('Klitoris ist.“', 0, 42, 26, INK, { weight: 800 }); });
      if (t > E('n5') - 1.2) at(0, -100, pop(t, E('n5') - 1.2, 0.4), -0.1, () => txt("IT'S A MATCH!", 0, 0, 64, '#e64980', { stroke: 10, sc: WHITE })); });
  }],
  [T('n6') - 0.1, (t) => { office(t); figK(t, 230, 1220, 0.75, { mood: 'excited', lookX: 1 }); dog(560, 1180, 0.8, { t }); figur(880, 1220, 0.75, Object.assign({ t, mood: 'angry', mouth: 0, lookX: -1 }, MAMA));
    at(380, 600, pop(t, T('n6') + 0.6, 0.3), 0, () => { emo('❤️', 0, 0, 90); txt('100 %', 0, 80, 40, '#e03131', { stroke: 8, sc: WHITE }); }); at(880, 600, pop(t, T('n6') + 1.6, 0.3), 0, () => { emo('🤍', 0, 0, 70); txt('12 %', 0, 70, 40, '#868e96', { stroke: 8, sc: WHITE }); }); }],
  [T('n7') - 0.1, (t) => { office(t); ctx.fillStyle = 'rgba(20,20,40,0.35)'; ctx.fillRect(0, 0, W, H); dog(560, 1180, 0.9, { t, dead: true }); emo('🕯️', 300, 1080, 90); emo('🕯️', 820, 1080, 90); stampT(t, C('lw') ?? 1e9, 'Todesursache: Langeweile 🥱', 540, 760, '#495057', -0.06); }],
  [T('n9') - 0.1, (t) => { cam(540, 760, 1.7, () => { office(t); figK(t, 540, 1220, 0.95, { mood: 'shocked', extra: { hair: 'curls', hairCol: '#f8f9fa' } }); }); for (let i = 0; i < 4; i++) { const a = t * 3 + i * 1.6; emo('🪰', 540 + Math.cos(a) * 280, 560 + Math.sin(a * 1.3) * 120, 50); } emo('🐩', 860, 1000, 110); if (t > E('n9') - 0.9) at(300, 500, pop(t, E('n9') - 0.9, 0.3), 0, () => { rr(-90, -60, 180, 120, 40); fs('#fff', 6); txt('Hä?', 0, 2, 64, INK); }); }],
  [T('n10') - 0.1, (t) => { office(t); figK(t, 360, 1220, 0.9, { mood: 'shocked', lookX: 1 }); figI(t, 700, 1220, 0.9, { mood: 'smug', lookX: -1, extra: { handL: [-330, -300] } }); at(540, 440, pop(t, T('n10') + 0.8, 0.35), 0, () => pill('Nice Guy ✔️', 0, 0, 46, '#fff', '#2f9e44', { lw: 6 })); stampT(t, C('niemand'), '… DEN NIEMAND WILL', 540, 560); }],
  [T('n11') - 0.1, (t) => { office(t); const u = prog(t, T('n11'), 2.4); figI(t, lerp(620, 1250, u), 1220, 0.85, { mood: 'smug', lookX: 1, extra: { walk: u < 1 } }); figK(t, 320, 1220, 0.9, { mood: t > C('schrei') ? 'furious' : 'shocked', lookX: 1, extra: { handR: t > C('schrei') ? [150, -420] : [130, -40] } }); if (t > C('schrei')) at(320, 520, 1 + 0.1 * Math.sin(t * 30), 0, () => { emo('💢', -80, 0, 80); txt('!!!', 60, 0, 90, '#e03131', { stroke: 10, sc: WHITE }); }); }],
  [T('n12') - 0.1, (t) => { cam(540, 760, 1.7, () => { office(t); figI(t, 540, 1220, 0.95, { mood: 'smug', extra: { handR: [150, -420] } }); }); const hx = 540 + 150 * 0.95 * 1.7, hy = 960 + (1220 - 420 * 0.95 - 760) * 1.7; pixelate(hx - 110, hy - 200, 220, 230, t); at(hx, hy - 240, 1, 0, () => pill('ZENSIERT', 0, 0, 30, INK, '#fff', { lw: 0 })); }],
  [T('n13') - 0.1, (t) => { graveyard(t); figK(t, 540, 1260, 0.7, { mood: 'shocked' }); stampT(t, C('ablehn'), 'ABGELEHNT', 540, 860); }],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  cutAt(t, SHOTS());
  sketchTitle(t, 'Der Nice Guy', '😇', 2.4);
  endCard(t, TL.duration - 1.3, 'Kennt ihr so einen? 👇', 'Markier deinen Nice Guy 😇');
  drawCaptions(t);
};
window.EP_SCENES = {};
