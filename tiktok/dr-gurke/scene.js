'use strict';
/* Dr. Gurke erklärt – Canvas-Animation, 1080x1920, deterministisch über renderFrame(t) */
const W = 1080, H = 1920;
const cv = document.getElementById('c');
const ctx = cv.getContext('2d');
const TL = window.TL;
const FPS = TL.fps;
const L = {}; TL.lines.forEach(l => (L[l.id] = l));
const T = id => L[id].start, E = id => L[id].end;
const C = n => TL.cues[n];
const SC = TL.scenes, ORDER = TL.sceneOrder;
const TOK = (id, k) => L[id].tokens[k].s;

const INK = '#1d1f3a', GREEN = '#69c04b', DGREEN = '#3c8a2c', LGREEN = '#9fe07a', WHITE = '#ffffff',
  RED = '#ff4757', YELLOW = '#ffd23f', BLUE = '#3fa7f5', SKIN = '#ffd0a6', PURPLE = '#7b5cff',
  ORANGE = '#ff9f1c', OLIVE = '#6f7f3a';
const FONT = '"Inter Display", "Inter", sans-serif';

const clamp = (x, a = 0, b = 1) => Math.max(a, Math.min(b, x));
const lerp = (a, b, t) => a + (b - a) * t;
const prog = (t, t0, d) => clamp((t - t0) / d);
const eOut = x => 1 - Math.pow(1 - x, 3);
const eIn = x => x * x * x;
const eIO = x => (x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2);
const eBack = x => { const c1 = 1.9, c3 = c1 + 1; return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2); };
const pop = (t, t0, d = 0.38) => (t < t0 ? 0 : eBack(prog(t, t0, d)));
const fade = (t, t0, d = 0.3) => eOut(prog(t, t0, d));
const rnd = i => { const x = Math.sin(i * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };

function mouthAt(t) { return TL.mouth[Math.round(t * FPS)] || 0; }
function gLineAt(t) { return TL.lines.find(l => l.spk === 'G' && t >= l.start - 0.04 && t <= l.end + 0.04); }
function gMouth(t) { return gLineAt(t) ? mouthAt(t) : 0; }
function blinkAt(t, off = 0) { const ph = (t + off) % 3.3; return ph > 3.18; }

/* ---------- Primitive ---------- */
function P() { ctx.beginPath(); }
function fs(fill, lw = 8, stroke = INK) {
  if (fill) { ctx.fillStyle = fill; ctx.fill(); }
  if (lw) { ctx.lineWidth = lw; ctx.strokeStyle = stroke; ctx.lineJoin = 'round'; ctx.lineCap = 'round'; ctx.stroke(); }
}
function circ(x, y, r) { ctx.beginPath(); ctx.arc(x, y, Math.max(0.01, r), 0, Math.PI * 2); }
function ell(x, y, rx, ry, rot = 0) { ctx.beginPath(); ctx.ellipse(x, y, Math.max(0.01, rx), Math.max(0.01, ry), rot, 0, Math.PI * 2); }
function rr(x, y, w, h, r) { ctx.beginPath(); ctx.roundRect(x, y, w, h, r); }
function seg(x1, y1, x2, y2, lw, col = INK) {
  ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2);
  ctx.lineWidth = lw; ctx.strokeStyle = col; ctx.lineCap = 'round'; ctx.stroke();
}
function limb(x1, y1, x2, y2, w, col) { seg(x1, y1, x2, y2, w + 12); seg(x1, y1, x2, y2, w, col); }
function at(x, y, s, rot, fn) {
  if (s <= 0.001) return;
  ctx.save(); ctx.translate(x, y); if (rot) ctx.rotate(rot); if (s !== 1) ctx.scale(s, s); fn(); ctx.restore();
}
function alpha(a, fn) { if (a <= 0.001) return; ctx.save(); ctx.globalAlpha *= a; fn(); ctx.restore(); }
function txt(s, x, y, size, col, o = {}) {
  ctx.save();
  ctx.font = `${o.weight || 900} ${size}px ${FONT}`;
  ctx.textAlign = o.align || 'center';
  ctx.textBaseline = 'middle';
  ctx.translate(x, y);
  if (o.rot) ctx.rotate(o.rot);
  if (o.maxW) { const w = ctx.measureText(s).width; if (w > o.maxW) ctx.scale(o.maxW / w, o.maxW / w); }
  if (o.alpha !== undefined) ctx.globalAlpha *= o.alpha;
  if (o.stroke) { ctx.lineWidth = o.stroke; ctx.strokeStyle = o.sc || INK; ctx.lineJoin = 'round'; ctx.miterLimit = 2; ctx.strokeText(s, 0, 0); }
  ctx.fillStyle = col; ctx.fillText(s, 0, 0);
  ctx.restore();
}
function tw(s, size, weight = 900) { ctx.save(); ctx.font = `${weight} ${size}px ${FONT}`; const w = ctx.measureText(s).width; ctx.restore(); return w; }
function pill(s, x, y, size, bg, fg, o = {}) {
  const w = tw(s, size, o.weight || 900) + size * 1.15, h = size * 1.6;
  rr(x - w / 2, y - h / 2, w, h, h / 2); fs(bg, o.lw ?? 7);
  txt(s, x, y + size * 0.05, size, fg, { weight: o.weight || 900 });
}
function bg(c1, c2) {
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, c1); g.addColorStop(1, c2);
  ctx.fillStyle = g; ctx.fillRect(-80, -80, W + 160, H + 160);
}
function rays(cx, cy, col, a, rot, n = 16) {
  ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = col; ctx.translate(cx, cy); ctx.rotate(rot);
  for (let i = 0; i < n; i++) {
    ctx.beginPath(); ctx.moveTo(0, 0);
    const a0 = (i / n) * Math.PI * 2, a1 = a0 + Math.PI / n;
    ctx.lineTo(Math.cos(a0) * 2400, Math.sin(a0) * 2400); ctx.lineTo(Math.cos(a1) * 2400, Math.sin(a1) * 2400);
    ctx.closePath(); ctx.fill();
  }
  ctx.restore();
}
function stripes(col, a, off, gap = 120) {
  ctx.save(); ctx.globalAlpha *= a; ctx.strokeStyle = col; ctx.lineWidth = gap * 0.35;
  for (let x = -H; x < W + H; x += gap) { const xx = x + (off % gap); seg(xx, -100, xx + H + 200, H + 100, gap * 0.35, col); }
  ctx.restore();
}
function dots(t, col, a, seed = 1) {
  ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = col;
  for (let i = 0; i < 26; i++) {
    const x = rnd(i * 3 + seed) * W, sp = 30 + rnd(i * 7 + seed) * 60;
    const y = H - ((t * sp + rnd(i * 11 + seed) * H) % (H + 100));
    circ(x + Math.sin(t + i) * 12, y, 6 + rnd(i * 5 + seed) * 18); ctx.fill();
  }
  ctx.restore();
}
function stamp(s, x, y, t, t0, rot, o = {}) {
  if (t < t0) return;
  const p = prog(t, t0, 0.2);
  const sc = lerp(2.6, 1, eOut(p)) * (1 + 0.06 * Math.sin(prog(t, t0 + 0.2, 0.3) * Math.PI));
  const a = clamp(p * 3) * (o.fadeAt ? 1 - prog(t, o.fadeAt, 0.3) : 1);
  const size = o.size || 130;
  alpha(a, () => at(x, y, sc, rot, () => {
    const w = tw(s, size) + 90, h = size * 1.5;
    rr(-w / 2, -h / 2, w, h, 26); fs('rgba(255,255,255,0.88)', 14, RED);
    rr(-w / 2 + 16, -h / 2 + 16, w - 32, h - 32, 16); fs(null, 5, RED);
    txt(s, 0, 6, size, RED);
  }));
}
function arrowHead(x, y, ang, size, col) {
  ctx.save(); ctx.translate(x, y); ctx.rotate(ang);
  P(); ctx.moveTo(size, 0); ctx.lineTo(-size * 0.7, -size * 0.75); ctx.lineTo(-size * 0.7, size * 0.75); ctx.closePath();
  fs(col, 7); ctx.restore();
}
function check(x, y, s, col = GREEN) {
  at(x, y, s, 0, () => {
    circ(0, 0, 50); fs(col, 8);
    P(); ctx.moveTo(-24, 2); ctx.lineTo(-6, 22); ctx.lineTo(26, -18); ctx.lineWidth = 14; ctx.strokeStyle = WHITE; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.stroke();
  });
}
function confetti(t, t0, cx, cy, n = 80) {
  const dt = t - t0; if (dt < 0 || dt > 2.6) return;
  const cols = [RED, YELLOW, BLUE, GREEN, PURPLE, ORANGE];
  for (let i = 0; i < n; i++) {
    const a = -Math.PI * (0.1 + 0.8 * rnd(i)), v = 700 + rnd(i + 99) * 1100;
    const x = cx + Math.cos(a) * v * dt * 0.8, y = cy + Math.sin(a) * v * dt + 1300 * dt * dt;
    ctx.save(); ctx.translate(x, y); ctx.rotate(dt * (6 + rnd(i + 5) * 8) + i);
    ctx.globalAlpha *= 1 - prog(dt, 2.0, 0.6);
    ctx.fillStyle = cols[i % cols.length]; ctx.fillRect(-12, -7, 24, 14); ctx.restore();
  }
}

/* ---------- Dr. Gurke ---------- */
const BUMPS = [[-62, -468], [48, -505], [-72, -255], [66, -282], [-28, -150], [58, -118], [-78, -372], [78, -400], [4, -215], [-45, -92], [30, -470], [-20, -522]];
function drawGurke(x, y, s, o = {}) {
  if (s <= 0.001) return;
  const t = o.t || 0, mood = o.mood || 'happy', m = o.mouth || 0;
  const coat = o.coat !== false;
  ctx.save();
  ctx.translate(x, y);
  if (o.rot) ctx.rotate(o.rot);
  ctx.scale(s * (o.sx || 1), s * (o.sy || 1));
  if (!o.noShadow) { ell(0, 0, 125, 20); ctx.fillStyle = 'rgba(0,0,0,0.16)'; ctx.fill(); }
  // Beine
  seg(-40, -70, -48, -14, 16); seg(40, -70, 48, -14, 16);
  ell(-60, -10, 36, 17); fs('#2b2d42', 7); ell(60, -10, 36, 17); fs('#2b2d42', 7);
  // Körper
  rr(-105, -545, 210, 505, 105); fs(GREEN, 9);
  ctx.save(); rr(-105, -545, 210, 505, 105); ctx.clip();
  ell(-58, -330, 26, 190); ctx.fillStyle = LGREEN; ctx.fill();
  ell(78, -300, 34, 240); ctx.fillStyle = 'rgba(40,110,30,0.22)'; ctx.fill();
  for (const [bx, by] of BUMPS) { ell(bx, by, 8, 6); ctx.fillStyle = DGREEN; ctx.fill(); }
  ctx.restore();
  rr(-105, -545, 210, 505, 105); fs(null, 9);
  // Kittel / Drill-Shirt
  if (coat || o.drill) {
    const cc = coat ? WHITE : OLIVE;
    P(); ctx.moveTo(-104, -318); ctx.lineTo(104, -318); ctx.lineTo(122, -62); ctx.quadraticCurveTo(0, -46, -122, -62); ctx.closePath(); fs(cc, 8);
    P(); ctx.moveTo(-46, -318); ctx.lineTo(0, -222); ctx.lineTo(46, -318); ctx.closePath(); fs(GREEN, 7);
    if (coat) {
      seg(0, -222, 0, -66, 6);
      for (const by of [-185, -140, -95]) { circ(16, by, 7); fs('#cfd6e2', 4); }
      rr(-92, -205, 58, 46, 8); fs('#eef2f7', 6); seg(-76, -222, -76, -190, 9, '#3b82f6');
      seg(-46, -318, -14, -246, 6); seg(46, -318, 14, -246, 6);
    } else {
      // Pfeife an Kordel
      P(); ctx.moveTo(-40, -318); ctx.quadraticCurveTo(0, -200, 40, -318); ctx.lineWidth = 5; ctx.strokeStyle = RED; ctx.stroke();
      rr(-22, -246, 44, 26, 10); fs('#cfd6e2', 6);
    }
  }
  // Arme
  const armCol = coat ? WHITE : (o.drill ? OLIVE : GREEN);
  const arm = (side, a) => {
    const sx = side * 98, sy = -300, len = 160;
    const hx = sx + side * Math.sin(a) * len, hy = sy + Math.cos(a) * len;
    limb(sx, sy, hx, hy, 22, armCol);
    return [hx, hy];
  };
  const [lhx, lhy] = arm(-1, o.armL ?? 0.35);
  const [rhx, rhy] = arm(1, o.armR ?? 0.35);
  if (o.clip) {
    at(lhx + 10, lhy - 30, 1, -0.12, () => {
      rr(-55, -75, 110, 145, 12); fs('#b07d4f', 7);
      rr(-44, -60, 88, 118, 6); fs(WHITE, 4);
      for (let i = 0; i < 4; i++) seg(-30, -36 + i * 24, 30 - (i % 2) * 18, -36 + i * 24, 5, '#9aa4b2');
      rr(-22, -86, 44, 22, 6); fs('#9aa4b2', 5);
    });
  }
  circ(lhx, lhy, 22); fs(WHITE, 7);
  circ(rhx, rhy, 22); fs(WHITE, 7);
  if (o.point) { seg(rhx, rhy, rhx + Math.sin(o.armR) * 34, rhy + Math.cos(o.armR) * 34, 12, WHITE); }
  // Gesicht
  const ey = -432, ex = 42;
  if (mood === 'happy' || mood === 'squeeze' || mood === 'proud') {
    for (const sd of [-1, 1]) { ell(sd * 74, -372, 18, 11); ctx.fillStyle = 'rgba(255,110,140,0.45)'; ctx.fill(); }
  }
  if (mood === 'squeeze') {
    ctx.lineWidth = 10; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    P(); ctx.moveTo(-64, -452); ctx.lineTo(-30, -432); ctx.lineTo(-64, -412); ctx.stroke();
    P(); ctx.moveTo(64, -452); ctx.lineTo(30, -432); ctx.lineTo(64, -412); ctx.stroke();
  } else {
    const bl = o.blink ?? blinkAt(t, o.blinkOff || 0);
    for (const sd of [-1, 1]) {
      ctx.save(); ctx.translate(sd * ex, ey); ctx.scale(1, bl ? 0.12 : 1);
      circ(0, 0, 30); fs(WHITE, 6);
      const lx = (o.lookX || 0) * 10, ly = (o.lookY || 0) * 9;
      circ(lx, ly + 2, 13); ctx.fillStyle = INK; ctx.fill();
      circ(lx + 4, ly - 3, 4); ctx.fillStyle = WHITE; ctx.fill();
      if (mood === 'sus') { ctx.beginPath(); ctx.rect(-36, -36, 72, 30); ctx.fillStyle = GREEN; ctx.fill(); seg(-30, -6, 30, -6, 7); }
      if (mood === 'angry') {
        ctx.beginPath();
        if (sd < 0) { ctx.moveTo(-36, -36); ctx.lineTo(36, -36); ctx.lineTo(36, -4); ctx.lineTo(-36, -24); }
        else { ctx.moveTo(-36, -36); ctx.lineTo(36, -36); ctx.lineTo(36, -24); ctx.lineTo(-36, -4); }
        ctx.closePath(); ctx.fillStyle = GREEN; ctx.fill();
        if (sd < 0) seg(-30, -22, 30, -6, 7); else seg(-30, -6, 30, -22, 7);
      }
      ctx.restore();
    }
  }
  // Brauen
  if (mood === 'angry') { seg(-74, -492, -18, -470, 12); seg(74, -492, 18, -470, 12); }
  else if (mood === 'sus') { seg(-74, -476, -18, -474, 11); seg(18, -494, 74, -504, 11); }
  else if (mood === 'squeeze') { seg(-72, -480, -22, -470, 11); seg(72, -480, 22, -470, 11); }
  else { for (const sd of [-1, 1]) { P(); ctx.arc(sd * 42, -462, 30, Math.PI * 1.2, Math.PI * 1.8); fs(null, 10); } }
  // Brille
  if (o.glasses !== false && mood !== 'squeeze') {
    for (const sd of [-1, 1]) { circ(sd * ex, ey, 40); fs(null, 7); }
    seg(-4, -440, 4, -440, 7); seg(-82, -438, -104, -448, 7); seg(82, -438, 104, -448, 7);
  }
  // Mund
  const my = -362;
  if (m > 0.07) {
    const w = 28 + 12 * m, h = 8 + 36 * m;
    ell(0, my + h * 0.3, w, h); fs('#6b1424', 7);
    ctx.save(); ell(0, my + h * 0.3, w - 3, h - 3); ctx.clip();
    ell(0, my + h * 1.05, w * 0.7, h * 0.5); ctx.fillStyle = '#ff6b81'; ctx.fill();
    if (mood === 'angry') { ctx.fillStyle = WHITE; ctx.fillRect(-w, my + h * 0.3 - h, w * 2, h * 0.4); }
    ctx.restore();
  } else if (mood === 'angry') { P(); ctx.arc(0, my + 24, 26, Math.PI * 1.18, Math.PI * 1.82); fs(null, 8); }
  else if (mood === 'sus') { seg(-22, my + 2, 20, my - 6, 8); }
  else if (mood === 'squeeze') { ell(0, my, 12, 9); fs('#6b1424', 6); }
  else { P(); ctx.arc(0, my - 16, 30, Math.PI * 0.22, Math.PI * 0.78); fs(null, 8); }
  // Hut
  if (o.hat === 'mirror') {
    P(); ctx.ellipse(0, -500, 104, 26, 0, Math.PI * 1.02, Math.PI * 1.98); fs(null, 10, '#7d8796');
    circ(-36, -532, 33); fs('#e3e9f1', 7); circ(-36, -532, 15); fs(WHITE, 4);
  }
  if (o.hat === 'drill') {
    ell(0, -528, 152, 28); fs('#8a5a2b', 8);
    P(); ctx.moveTo(-78, -536); ctx.lineTo(-58, -642); ctx.quadraticCurveTo(-30, -612, 0, -650); ctx.quadraticCurveTo(30, -612, 58, -642); ctx.lineTo(78, -536); ctx.closePath(); fs('#a26b35', 8);
    rr(-78, -566, 156, 26, 6); fs('#3b2a1a', 6);
  }
  ctx.restore();
}

/* ---------- Menschen & Dinge ---------- */
function drawToiletFront() {
  rr(-120, -575, 240, 205, 26); fs('#f5f8fc', 8);
  rr(-40, -560, 80, 20, 8); fs('#cfd6e2', 5);
  P(); ctx.moveTo(-150, -340); ctx.lineTo(150, -340); ctx.quadraticCurveTo(140, -150, 70, -112); ctx.lineTo(82, 0); ctx.lineTo(-82, 0); ctx.lineTo(-70, -112); ctx.quadraticCurveTo(-140, -150, -150, -340); ctx.closePath(); fs('#f5f8fc', 8);
  rr(-162, -362, 324, 36, 18); fs('#e4eaf3', 8);
}
function drawSitter(x, y, s, o = {}) {
  const t = o.t || 0, mood = o.mood || 'bored';
  const sh = o.shake ? Math.sin(t * 46) * 5 : 0;
  const shirt = o.shirt || PURPLE, pants = o.pants || '#3a5bd9';
  at(x + sh, y, s, 0, () => {
    drawToiletFront();
    rr(-104, -372, 94, 104, 40); fs(pants, 8); rr(10, -372, 94, 104, 40); fs(pants, 8);
    rr(-88, -292, 62, 250, 28); fs(SKIN, 8); rr(26, -292, 62, 250, 28); fs(SKIN, 8);
    rr(-114, -118, 228, 62, 28); fs(pants, 8);
    ell(-58, -22, 54, 24); fs('#2b2d42', 8); ell(58, -22, 54, 24); fs('#2b2d42', 8);
    rr(-98, -615, 196, 262, 62); fs(shirt, 8);
    limb(-84, -575, -38, -462, 24, shirt); limb(84, -575, 38, -462, 24, shirt);
    rr(-44, -540, 88, 124, 14); fs('#222638', 7);
    ctx.save(); rr(-34, -528, 68, 100, 8); ctx.clip();
    ctx.fillStyle = '#9fe3ff'; ctx.fillRect(-34, -528, 68, 100);
    for (let i = 0; i < 5; i++) { const yy = -528 + ((i * 34 - t * 90) % 170 + 170) % 170 - 20; ctx.fillStyle = i % 2 ? '#ff8fab' : '#ffd23f'; ctx.fillRect(-26, yy, 52, 22); }
    ctx.restore();
    circ(-36, -455, 18); fs(SKIN, 6); circ(36, -455, 18); fs(SKIN, 6);
    circ(0, -705, 82); fs(SKIN, 8);
    P(); ctx.arc(0, -712, 84, Math.PI * 1.0, Math.PI * 2.0); ctx.quadraticCurveTo(40, -740, 0, -735); ctx.quadraticCurveTo(-50, -730, -84, -712); ctx.closePath(); fs('#4a2f23', 8);
    if (mood === 'whine') {
      seg(-42, -690, -18, -682, 8); seg(42, -690, 18, -682, 8);
      P(); ctx.moveTo(-26, -640); ctx.quadraticCurveTo(0, -668, 26, -640); fs(null, 8);
      for (const sd of [-1, 1]) { const dy = (t * 140) % 60; ell(sd * 36, -668 + dy, 7, 11); fs(BLUE, 3); }
    } else {
      circ(-28, -680, 8); ctx.fillStyle = INK; ctx.fill(); circ(28, -680, 8); ctx.fill();
      seg(-34, -700, -16, -698, 6); seg(34, -700, 16, -698, 6);
      seg(-16, -648, 16, -648, 7);
    }
    ell(0, -560, 70, 40); ctx.fillStyle = 'rgba(160,230,255,0.18)'; ctx.fill();
  });
}
function drawStander(x, y, s, o = {}) {
  const t = o.t || 0, ph = o.ph || 0;
  const b = Math.abs(Math.sin(t * 9 + ph)) * 16;
  at(x, y - b, s, Math.sin(t * 9 + ph) * 0.05, () => {
    limb(-34, -205, 22, -18, 18, o.pants || '#2f3e46'); limb(34, -205, -22, -18, 18, o.pants || '#2f3e46');
    ell(-30, -12, 32, 15); fs('#2b2d42', 6); ell(30, -12, 32, 15); fs('#2b2d42', 6);
    rr(-62, -415, 124, 222, 44); fs(o.shirt || ORANGE, 7);
    limb(-56, -380, -12, -222, 16, o.shirt || ORANGE); limb(56, -380, 12, -222, 16, o.shirt || ORANGE);
    circ(0, -218, 20); fs(SKIN, 6);
    circ(0, -478, 64); fs(SKIN, 7);
    P(); ctx.arc(0, -486, 66, Math.PI, Math.PI * 2); ctx.closePath(); fs(o.hair || '#2b2d42', 7);
    if (o.angry) { seg(-36, -486, -12, -476, 7); seg(36, -486, 12, -476, 7); }
    circ(-22, -466, 10); fs(WHITE, 4); circ(22, -466, 10); fs(WHITE, 4);
    circ(-22, -464, 4); ctx.fillStyle = INK; ctx.fill(); circ(22, -464, 4); ctx.fill();
    rr(-22, -440, 44, 18, 6); fs(WHITE, 5); seg(-20, -431, 20, -431, 3);
    const d = (t * 1.3 + ph) % 1; alpha(1 - d, () => { ell(52, -500 + d * 60, 9, 14); fs('#9fd8ff', 4); });
  });
}
function drawDoor(t) {
  rr(-220, -650, 440, 650, 10); fs('#6d4c41', 8);
  rr(-190, -620, 380, 620, 8); fs('#c08a5b', 8);
  rr(-150, -560, 300, 210, 10); fs('#b07a4c', 6);
  rr(-150, -300, 300, 240, 10); fs('#b07a4c', 6);
  circ(150, -330, 18); fs(YELLOW, 6);
  rr(-130, -520, 260, 96, 18); fs(RED, 7);
  txt('BESETZT', 0, -470, 50, WHITE);
  const sec = Math.floor(38 * 60 + t * 97);
  const str = `${String(Math.floor(sec / 60)).padStart(2, '0')}:${String(sec % 60).padStart(2, '0')}`;
  pill(str, 0, -720, 54, WHITE, INK);
}
function drawSideFigure(p, shirt, pants) {
  const [hx, hy] = p.hip, [kx, ky] = p.knee, [fx, fy] = p.foot, [sx, sy] = p.sh, [ex, ey] = p.el, [ax, ay] = p.hand;
  limb(hx, hy, kx, ky, 30, pants); limb(kx, ky, fx, fy, 26, pants);
  ell(fx + 18, fy + 4, 30, 14); fs('#2b2d42', 6);
  limb(hx, hy, sx, sy, 46, shirt);
  limb(sx, sy, ex, ey, 18, shirt); limb(ex, ey, ax, ay, 16, SKIN);
  circ(p.head[0], p.head[1], 46); fs(SKIN, 7);
  P(); ctx.arc(p.head[0], p.head[1] - 6, 48, Math.PI * 0.95, Math.PI * 2.0); ctx.closePath(); fs('#4a2f23', 7);
  circ(p.head[0] + 22, p.head[1] - 2, 6); ctx.fillStyle = INK; ctx.fill();
}
const POSE_SIT = { hip: [-40, -172], knee: [72, -176], foot: [76, -14], sh: [-46, -348], head: [-34, -412], el: [4, -268], hand: [58, -288] };
const POSE_STOOL = { hip: [-40, -172], knee: [58, -236], foot: [76, -96], sh: [-18, -340], head: [6, -400], el: [32, -252], hand: [78, -262] };
const POSE_SQUAT = { hip: [-38, -82], knee: [66, -160], foot: [52, -14], sh: [22, -290], head: [52, -350], el: [80, -196], hand: [96, -140] };
function lerpPose(a, b, k) { const o = {}; for (const key in a) o[key] = [lerp(a[key][0], b[key][0], k), lerp(a[key][1], b[key][1], k)]; return o; }
function drawToiletSide() {
  rr(-132, -300, 40, 150, 10); fs('#f5f8fc', 7);
  P(); ctx.moveTo(-112, -160); ctx.lineTo(42, -160); ctx.quadraticCurveTo(30, -70, -20, -60); ctx.lineTo(-10, 0); ctx.lineTo(-80, 0); ctx.lineTo(-74, -64); ctx.quadraticCurveTo(-112, -90, -112, -160); ctx.closePath(); fs('#f5f8fc', 7);
  rr(-120, -172, 172, 20, 10); fs('#e4eaf3', 6);
}
function drawStool(k) {
  at(76, 0, 1, 0, () => { rr(-62, -82, 124, 26, 10); fs('#ff9f1c', 7); limb(-44, -60, -52, 0, 12, '#ff9f1c'); limb(44, -60, 52, 0, 12, '#ff9f1c'); });
}
function drawHose(cx, cy, kink, t, o = {}) {
  const A = [cx - 160, cy - 30], J = [cx, cy - 30];
  const ang = lerp(0.28, 2.35, kink), len = 135;
  const B = [J[0] + Math.cos(ang) * len, J[1] + Math.sin(ang) * len];
  if (o.muscle !== undefined) {
    const tight = o.muscle;
    ctx.save();
    if (!tight) { ctx.setLineDash([18, 14]); ctx.globalAlpha *= 0.55; }
    ell(J[0] - 6, J[1] + 18, tight ? 58 : 84, tight ? 34 : 54, -0.5);
    ctx.lineWidth = (tight ? 15 : 10) + (o.hi || 0) * 7 * (0.5 + 0.5 * Math.sin(t * 14)); ctx.strokeStyle = RED; ctx.stroke();
    ctx.restore();
  }
  P(); ctx.moveTo(A[0], A[1]); ctx.lineTo(J[0], J[1]); ctx.lineTo(B[0], B[1]);
  ctx.lineJoin = 'round'; ctx.lineCap = 'round';
  ctx.lineWidth = 58; ctx.strokeStyle = INK; ctx.stroke();
  ctx.lineWidth = 42; ctx.strokeStyle = '#2fae5a'; ctx.stroke();
  ctx.lineWidth = 8; ctx.strokeStyle = 'rgba(255,255,255,0.35)'; ctx.stroke();
  // Wasser
  const L1 = 160, L2 = len, tot = L1 + L2;
  const ptAt = d => (d <= L1 ? [A[0] + (J[0] - A[0]) * d / L1, A[1]] : [J[0] + Math.cos(ang) * (d - L1), J[1] + Math.sin(ang) * (d - L1)]);
  if (kink < 0.5) {
    for (let i = 0; i < 7; i++) { const d = ((t * 0.8 + i / 7) % 1) * tot; const [px, py] = ptAt(d); circ(px, py, 10); fs(BLUE, 4); }
    for (let i = 0; i < 5; i++) {
      const u = (t * 1.6 + i / 5) % 1;
      const px = B[0] + Math.cos(ang) * u * 90 + (rnd(i) - 0.5) * 20 * u, py = B[1] + Math.sin(ang) * u * 90 + 120 * u * u;
      alpha(1 - u, () => { circ(px, py, 9 - u * 4); fs(BLUE, 3); });
    }
  } else {
    for (let i = 0; i < 6; i++) { const d = L1 - 18 - i * 26 + Math.sin(t * 7 + i) * 3; const [px, py] = ptAt(d); circ(px, py, 10); fs(BLUE, 4); }
    seg(J[0] - 14, J[1] - 34, J[0] + 10, J[1] - 20, 6); seg(J[0] - 22, J[1] + 26, J[0], J[1] + 34, 6);
  }
  return J;
}
function drawPie(cx, cy, r, frac, col) {
  circ(cx, cy, r); fs('#eef6ff', 8);
  if (frac > 0.001) { P(); ctx.moveTo(cx, cy); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2); ctx.closePath(); fs(col, 8); }
  circ(cx, cy, r * 0.55); fs(WHITE, 8);
}
function drawGauge(cx, cy, r, v, t) {
  const segs = [[GREEN, 0, 0.4], [YELLOW, 0.4, 0.7], [RED, 0.7, 1]];
  for (const [c, a, b] of segs) { P(); ctx.arc(cx, cy, r, Math.PI + a * Math.PI, Math.PI + b * Math.PI); ctx.lineWidth = 44; ctx.strokeStyle = c; ctx.lineCap = 'butt'; ctx.stroke(); }
  P(); ctx.arc(cx, cy, r + 22, Math.PI, Math.PI * 2); fs(null, 7); P(); ctx.arc(cx, cy, r - 22, Math.PI, Math.PI * 2); fs(null, 7);
  const ang = Math.PI + v * Math.PI + Math.sin(t * 30) * 0.03 * v;
  seg(cx, cy, cx + Math.cos(ang) * (r - 8), cy + Math.sin(ang) * (r - 8), 12);
  circ(cx, cy, 20); fs(INK, 0);
}
function drawPhoneBig(cx, cy, s, t) {
  at(cx, cy, s, Math.sin(t * 3) * 0.04, () => {
    rr(-110, -190, 220, 380, 34); fs('#222638', 8);
    ctx.save(); rr(-92, -160, 184, 320, 18); ctx.clip();
    ctx.fillStyle = '#f2f6ff'; ctx.fillRect(-92, -160, 184, 320);
    const cols = ['#ff8fab', '#ffd23f', '#9fe3ff', '#b8f2a1'];
    for (let i = 0; i < 6; i++) { const yy = -160 + (((i * 110 - t * 260) % 660) + 660) % 660 - 110; rr(-78, yy, 156, 92, 12); fs(cols[i % 4], 0); seg(-62, yy + 74, 30, yy + 74, 8, 'rgba(0,0,0,0.25)'); }
    ctx.restore();
    rr(-30, -178, 60, 10, 5); fs('#444a66', 0);
  });
}
function drawHammock(x1, x2, y, sag, k, t, label) {
  const col = `rgb(${Math.round(lerp(63, 255, k))},${Math.round(lerp(167, 71, k))},${Math.round(lerp(245, 87, k))})`;
  limb(x1, y - 40, x1, y + 140, 18, '#8d6e63'); limb(x2, y - 40, x2, y + 140, 18, '#8d6e63');
  const cy = y + sag;
  P(); ctx.moveTo(x1, y); ctx.quadraticCurveTo((x1 + x2) / 2, cy * 2 - y, x2, y);
  ctx.lineWidth = 34; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.stroke();
  ctx.lineWidth = 22; ctx.strokeStyle = col; ctx.stroke();
  if (k > 0.5) { for (let i = 0; i < 3; i++) { const u = (t * 2 + i / 3) % 1; alpha(1 - u, () => { seg(x1 + 40 + i * 30, y - 40 - u * 50, x1 + 50 + i * 30, y - 70 - u * 50, 6, RED); }); } }
  if (label) txt(label, x1 + 40, y - 78, 38, INK, { weight: 900 });
  return cy;
}
function drawGlass(s) {
  at(0, 0, s, 0, () => {
    P(); ctx.moveTo(-60, -80); ctx.lineTo(60, -80); ctx.lineTo(46, 80); ctx.lineTo(-46, 80); ctx.closePath(); fs('#eaf6ff', 7);
    P(); ctx.moveTo(-54, -30); ctx.quadraticCurveTo(0, -46, 54, -30); ctx.lineTo(46, 80); ctx.lineTo(-46, 80); ctx.closePath(); fs(BLUE, 7);
    circ(-14, 30, 8); fs('#bfe6ff', 0); circ(16, 0, 6); fs('#bfe6ff', 0);
  });
}
function drawBroccoli(s) {
  at(0, 0, s, 0, () => {
    P(); ctx.moveTo(-22, 80); ctx.lineTo(22, 80); ctx.lineTo(16, -10); ctx.lineTo(-16, -10); ctx.closePath(); fs('#9ed36a', 7);
    for (const [x, y, r] of [[-44, -30, 36], [44, -30, 36], [0, -56, 42], [-24, -8, 30], [24, -8, 30]]) { circ(x, y, r); fs('#3c9b3a', 7); }
  });
}
function drawNoPress(s, t) {
  at(0, 0, s, 0, () => {
    const sh = Math.sin(t * 40) * 2;
    circ(sh, 0, 62); fs('#ff9a8b', 7);
    seg(-30 + sh, -14, -10 + sh, -6, 7); seg(30 + sh, -14, 10 + sh, -6, 7);
    rr(-24 + sh, 16, 48, 18, 6); fs(WHITE, 5);
    circ(0, 0, 84); fs(null, 12, RED); seg(-60, 60, 60, -60, 12, RED);
  });
}
function drawTimer(s, t) {
  at(0, 0, s, 0, () => {
    rr(-16, -98, 32, 22, 6); fs('#9aa4b2', 6);
    circ(0, 0, 76); fs(WHITE, 8);
    txt('10', 0, 8, 58, INK);
    const a = -Math.PI / 2 + t * 2;
    seg(0, 0, Math.cos(a) * 58, Math.sin(a) * 58, 5, RED);
  });
}
function drawBowlBack(cx, cy) {
  ell(cx, cy, 240, 46); fs('#2f9e8f', 8);
  for (let i = 0; i < 7; i++) { const x = cx - 190 + i * 64; ell(x, cy - 18 - (i % 2) * 10, 44, 26, (i - 3) * 0.2); fs(i % 3 === 0 ? '#58b947' : '#7ad35c', 6); }
  circ(cx - 120, cy - 34, 26); fs(RED, 6); circ(cx + 140, cy - 30, 24); fs(RED, 6);
}
function drawBowlFront(cx, cy) {
  P(); ctx.moveTo(cx - 240, cy); ctx.ellipse(cx, cy, 240, 170, 0, Math.PI, 0, true); ctx.closePath(); fs('#3fc1b0', 8);
  P(); ctx.ellipse(cx, cy, 240, 46, 0, 0, Math.PI); fs(null, 8);
  seg(cx - 160, cy + 80, cx + 160, cy + 80, 6, 'rgba(255,255,255,0.4)');
}
function bubble(x, y, s, str, t0, t) {
  const sc = pop(t, t0, 0.4) * s;
  at(x, y, sc, Math.sin(t * 6) * 0.03, () => {
    const w = tw(str, 54, 800) + 70, h = 110;
    rr(-w / 2, -h / 2, w, h, 40); fs(WHITE, 7);
    P(); ctx.moveTo(-20, h / 2 - 4); ctx.lineTo(0, h / 2 + 42); ctx.lineTo(24, h / 2 - 4); ctx.closePath(); fs(WHITE, 0);
    seg(-20, h / 2, 0, h / 2 + 42, 7); seg(0, h / 2 + 42, 24, h / 2, 7);
    txt(str, 0, 4, 54, INK, { weight: 800 });
  });
}
function logo(t) {
  alpha(fade(t, 0.15, 0.4) * 0.95, () => {
    at(76, 214, 0.85, -0.5, () => { rr(-14, -34, 28, 68, 14); fs(GREEN, 5); });
    txt('DR. GURKE ERKLÄRT', 104, 216, 28, WHITE, { align: 'left', stroke: 8 });
  });
}

/* ---------- Szenen ---------- */
function titleBlock(t, tIn, tUp, tag, big, tagCol, bigSize = 140) {
  const up = eIO(prog(t, tUp, 0.5));
  const y = lerp(470, 330, up), s = lerp(1, 0.6, up) * pop(t, tIn, 0.4);
  at(540, y, s, 0, () => {
    pill(tag, 0, -125, 50, tagCol, WHITE);
    txt(big, 0, 20, bigSize, WHITE, { stroke: 22, maxW: 960 });
  });
}
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

/* ---------- Untertitel ---------- */
const CHUNKS = [];
for (const l of TL.lines) {
  let cur = [], chars = 0;
  const push = () => { if (cur.length) CHUNKS.push({ line: l, toks: cur }); cur = []; chars = 0; };
  l.tokens.forEach((tk, i) => {
    cur.push(tk); chars += tk.t.length + 1;
    const nxt = l.tokens[i + 1];
    if (cur.length >= 3 || chars >= 15 || /[.!?:…,]$/.test(tk.t) || (nxt && chars + nxt.t.length > 18)) push();
  });
  push();
}
CHUNKS.forEach((c, i) => {
  c.start = c.toks[0].s - 0.06;
  const n = CHUNKS[i + 1], lineEnd = c.line.end + 0.35;
  c.end = n ? Math.min(n.toks[0].s - 0.06, n.line === c.line ? Infinity : lineEnd) : lineEnd;
});
function drawCaptions(t) {
  const c = CHUNKS.find(c => t >= c.start && t < c.end);
  if (!c) return;
  const size = 82, gap = 22, y = 1395, cx = 515;
  const isG = c.line.spk === 'G';
  const hi = isG ? '#9dff6a' : YELLOW;
  ctx.save();
  ctx.font = `900 ${size}px ${FONT}`;
  const ws = c.toks.map(tk => ctx.measureText(tk.t).width);
  const total = ws.reduce((a, b) => a + b, 0) + gap * (ws.length - 1);
  const sc = Math.min(1, 900 / total) * (0.82 + 0.18 * eBack(prog(t, c.start, 0.14)));
  ctx.translate(cx, y); ctx.scale(sc, sc);
  let x = -total / 2;
  c.toks.forEach((tk, i) => {
    const nextS = c.toks[i + 1] ? c.toks[i + 1].s : c.end;
    const active = t >= tk.s - 0.04 && t < nextS - 0.04;
    ctx.save();
    ctx.translate(x + ws[i] / 2, 0);
    if (active) ctx.scale(1.08, 1.08);
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.lineWidth = 16; ctx.strokeStyle = INK; ctx.lineJoin = 'round'; ctx.miterLimit = 2;
    ctx.strokeText(tk.t, 0, 0);
    ctx.fillStyle = active ? hi : WHITE; ctx.fillText(tk.t, 0, 0);
    ctx.restore();
    x += ws[i] + gap;
  });
  ctx.restore();
}

/* ---------- Haupt-Loop ---------- */
const SCENE_FN = { hook: sceneHook, problem: sceneProblem, phone: scenePhone, posture: scenePosture, method: sceneMethod, tips: sceneTips, outro: sceneOutro };
const STAMPS = ['stamp1', 'stamp2', 'nirgendwo'];
function shake(t) {
  let a = 0;
  for (const s of STAMPS) { const c = C(s); if (t >= c) a += 26 * Math.exp(-(t - c) * 9); }
  return { x: Math.sin(t * 93) * a, y: Math.cos(t * 71) * a };
}
function drawScene(name, t, dx, dy) {
  ctx.save(); ctx.translate(dx, dy);
  SCENE_FN[name](t);
  ctx.restore();
}
const TR = 0.45;
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.globalAlpha = 1;
  ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, H);
  let idx = 0;
  for (let i = 0; i < ORDER.length; i++) if (t >= SC[ORDER[i]]) idx = i;
  const cur = ORDER[idx];
  const p = idx > 0 ? eIO(prog(t, SC[cur], TR)) : 1;
  const sh = shake(t);
  if (p < 1) {
    drawScene(ORDER[idx - 1], t, -p * W + sh.x, sh.y);
    drawScene(cur, t, (1 - p) * W + sh.x, sh.y);
  } else drawScene(cur, t, sh.x, sh.y);
  logo(t);
  drawCaptions(t);
};
window.DURATION = TL.duration;
window.READY = true;
