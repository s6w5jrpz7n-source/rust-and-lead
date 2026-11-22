'use strict';
/* Die Rettungsflitzer – Folge 1: „Flitzi steckt fest“ */
window.EP_LOGO = false;
window.EP_NAMES = TL.data.names;
window.EP_CAPCOL = { N: '#ffd43b', F: '#66d9e8', T: '#ffa94d', R: '#ff8787' };
const FX = 470, TX = 960, RX = 0, Z = 0.7, CY = 909, SF = 0.95, ST = 0.8, SR = 0.75;
const C1 = 990;  // Kamera-Mitte y bei Zoom 1
const tStuck = () => T('k3') - 0.15, tFree = () => T('k10') - 0.15;
function flitziState(t) {
  // Position, Einsinken, Schlamm, Stimmung
  if (t < tStuck()) { const u = clamp(t / tStuck()); return { x: lerp(-260, FX, eOut(u)), sink: 0, mud: 0, mood: 'happy', spin: t * 14, moving: true }; }
  if (t < tFree()) { const k = prog(t, tStuck(), 0.4); const spinning = t > T('k4') - 0.1 && t < T('k5'); return { x: FX, sink: 0.7 * k, mud: 0.8 * k, mood: t < T('k3') + 0.4 ? 'surprised' : 'worried', spin: spinning ? t * 30 : 0 }; }
  const u = prog(t, tFree(), 0.5), clean = 1 - prog(t, T('k11') + 0.6, 2.2);
  return { x: lerp(FX, FX + 100, eOut(u)), y: -Math.sin(Math.PI * u) * 140, sink: 0.7 * (1 - u), mud: 0.8 * clean, mood: 'happy', spin: u < 1 ? t * 20 : 0 };
}
function scene(t, o = {}) {
  const f = flitziState(t);
  world(t, { puddles: [-100, 160, 1160], scroll: f.moving ? -t * 300 : 0, rainbow: o.rainbow || 0 });
  const soft = TL.cues.spritz && t > C('spritz') + 0.8 ? 1 : 0;
  mudPit(FX, 1 - prog(t, T('k11'), 1.0), soft);
  // Frida
  if (o.frida) {
    const inn = eOut(prog(t, T('k7') - 0.6, 1.0));
    car(lerp(-900, RX, inn), GROUND + 20, SR, { t, type: 'fire', mood: o.fridaMood || 'happy', mouth: mouthOf('R', t), lights: t < T('k8'), spin: (1 - inn) * t * 16, look: 1 });
  }
  // Toni
  if (o.toni) {
    const inn = eOut(prog(t, T('k5') - 0.6, 1.1));
    const strain = o.strain ? Math.sin(t * 40) * 4 : 0;
    car(lerp(1700, TX, inn) + strain, GROUND + 20, ST, { t, type: 'tow', mood: o.toniMood || 'happy', mouth: mouthOf('T', t), lights: inn < 1, spin: o.strain ? -t * 25 : (1 - inn) * -t * 16, look: -1, hookY: -130 });
    if (o.rope) rope(TX - 360 * ST, GROUND + 20 - 112 * ST, f.x + 190 * SF, GROUND + 20 - 90 * SF + f.sink * 30, o.strain);
  }
  car(f.x, GROUND + 20 + (f.y || 0) + f.sink * 36, SF, { t, type: 'mini', mood: o.flitziMood || f.mood, mouth: mouthOf('F', t), spin: f.spin, mud: f.mud, sink: f.sink, look: o.flitziLook ?? 0.6 });
  // Matsch vorn über den Rädern
  if (f.sink > 0.05) alpha(1 - prog(t, T('k11'), 1.0), () => { ell(f.x, GROUND + 40, 220, 30 + f.sink * 20); fs(soft ? '#a9744f' : '#7a4a24', 0); });
  if (f.spin && t > T('k4') - 0.1 && t < T('k5')) for (let i = 0; i < 8; i++) { const u = (t * 2.5 + i / 8) % 1; circ(f.x - 160 - u * 220, GROUND - 40 - Math.sin(u * Math.PI) * 160, 12); ctx.fillStyle = '#7a4a24'; ctx.fill(); }
  splash(-100, GROUND + 40, t, 0.9 * tStuck() * 0.35);
  splash(160, GROUND + 40, t, tStuck() * 0.7);
  splash(FX, GROUND + 30, t, tStuck(), '#7a4a24', 14, 320);
  // Wasserstrahl
  if (o.spray) {
    const x0 = RX + 100 * SR, y0 = GROUND + 20 - 340 * SR, x1 = o.sprayAt ?? FX, y1 = GROUND - (o.sprayHigh ? 160 : 0);
    for (let i = 0; i < 26; i++) { const u = ((t * 1.6 + i / 26) % 1); const x = lerp(x0, x1, u), y = lerp(y0, y1, u) - Math.sin(u * Math.PI) * 220; circ(x, y, 10 + 6 * rnd(i)); ctx.fillStyle = 'rgba(77,171,247,0.85)'; ctx.fill(); }
  }
  if (o.wash) { for (let i = 0; i < 10; i++) { const u = (t * 0.7 + i / 10) % 1; alpha(Math.sin(u * Math.PI), () => emo('🫧', f.x - 180 + rnd(i) * 360, GROUND - 120 - u * 300, 50)); } }
  if (o.sparkle) sparkles(t, f.x + 40, GROUND - 170, 200);
}
const SHOTS = () => [
  [0, (t) => camA(470, C1, 1, () => scene(t))],
  [T('k2') - 0.1, (t) => { const f = flitziState(t); camA(f.x + 40, 1010, 1.6, () => scene(t)); }],
  [tStuck() - 0.1, (t) => camA(470, C1, 1, () => scene(t))],
  [T('k4') - 0.1, (t) => camA(FX + 40, 1010, 1.6, () => scene(t))],
  [T('k5') - 0.7, (t) => camA(740, C1, 1, () => scene(t, { toni: true }))],
  [T('k6') - 0.1, (t) => camA(740, C1, 1, () => scene(t, { toni: true, rope: true, strain: t < TOK('k6', 2) - 0.1, toniMood: t < TOK('k6', 2) - 0.1 ? 'strain' : 'sad', flitziMood: 'worried' }))],
  [T('k7') - 0.7, (t) => camA(200, C1, 1, () => scene(t, { toni: true, rope: true, frida: true, toniMood: 'sad', flitziMood: 'worried' }))],
  [T('k8') - 0.1, (t) => camA(220, C1, 1, () => scene(t, { toni: true, rope: true, frida: true, spray: true, fridaMood: 'proud', flitziMood: 'surprised', flitziLook: -0.8 }))],
  [T('k9') - 0.1, (t) => camA(760, C1, 1, () => scene(t, { toni: true, rope: t < tFree(), strain: t < tFree(), frida: true, toniMood: t < tFree() ? 'strain' : 'happy' }))],
  [T('k11') - 0.1, (t) => camA(260, C1, 1, () => scene(t, { toni: true, frida: true, spray: t < T('k11') + 2.8, sprayAt: FX + 140, sprayHigh: true, wash: true, sparkle: t > T('k11') + 2.0 }))],
  [T('k12') - 0.1, (t) => { const f = flitziState(t); camA(f.x + 40, 1010, 1.6, () => scene(t, { toni: true, frida: true, sparkle: true })); }],
  [T('k13') - 0.2, (t) => camA(480, 956, 0.85, () => scene(t, { toni: true, frida: true, rainbow: prog(t, T('k13') - 0.2, 1.0), sparkle: true }))],
];
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  let cur = SHOTS()[0]; for (const s of SHOTS()) if (t >= s[0]) cur = s;
  cur[1](t);
  seriesTitle(t, 3.2, 'Folge 1: Flitzi steckt fest');
  if (TL.cues.frida && t > T('k7') && t < T('k8')) at(540 + (RX + 80 - 200), 960 + (GROUND - 300 - C1), pop(t, T('k7') + 0.3, 0.35), 0, () => emo('💡', 0, 0, 110));
  if (t > T('k13') - 0.1 && t < T('k14')) at(540, 520, pop(t, T('k13'), 0.45), 0, () => { txt('Zusammen schaffen', 0, -40, 72, '#fff', { stroke: 14, sc: OUTL }); txt('wir alles! 💪', 0, 50, 72, '#ffd43b', { stroke: 14, sc: OUTL }); });
  if (t > T('k14') - 0.1) at(540, 520, pop(t, T('k14'), 0.45), 0, () => { rr(-440, -110, 880, 220, 40); fs('#fff', 8, OUTL); txt('Wer erlebt das nächste', 0, -40, 54, OUTL); txt('Abenteuer? 🚓 🚑 🚜 👇', 0, 40, 54, '#e03131'); });
  drawCaptions(t);
};
window.EP_SCENES = {};
