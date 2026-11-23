'use strict';
/* Dr. Gurke erklärt – gemeinsame Engine (Figuren, Primitive, Untertitel, Szenenwechsel).
   Jede Folge liefert window.EP_SCENES = {szene: fn(t)} und optional window.EP_STAMPS = [cue-Namen fürs Wackeln]. */
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
function mouthOf(spk, t) {  // Mund eines bestimmten Sprechers, nur während seiner Zeilen
  const l = TL.lines.find(l => l.spk === spk && t >= l.start - 0.04 && t <= l.end + 0.04);
  return l && TL.mouths && TL.mouths[spk] ? (TL.mouths[spk][Math.round(t * FPS)] || 0) : 0;
}
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
  const size = o.size || 130, col = o.col || RED;
  alpha(a, () => at(x, y, sc, rot, () => {
    const w = tw(s, size) + 90, h = size * 1.5;
    rr(-w / 2, -h / 2, w, h, 26); fs('rgba(255,255,255,0.88)', 14, col);
    rr(-w / 2 + 16, -h / 2 + 16, w - 32, h - 32, 16); fs(null, 5, col);
    txt(s, 0, 6, size, col);
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
  const arm = (side, a, hand) => {
    const sx = side * 98, sy = -300, len = 160;
    const [hx, hy] = hand || [sx + side * Math.sin(a) * len, sy + Math.cos(a) * len];
    limb(sx, sy, hx, hy, 22, armCol);
    return [hx, hy];
  };
  const [lhx, lhy] = arm(-1, o.armL ?? 0.35, o.handL);
  const [rhx, rhy] = arm(1, o.armR ?? 0.35, o.handR);
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
  if (mood === 'squeeze' || mood === 'disgust') {
    ctx.lineWidth = 10; ctx.strokeStyle = INK; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    P(); ctx.moveTo(-64, -452); ctx.lineTo(-30, -432); ctx.lineTo(-64, -412); ctx.stroke();
    P(); ctx.moveTo(64, -452); ctx.lineTo(30, -432); ctx.lineTo(64, -412); ctx.stroke();
  } else {
    const bl = o.blink ?? blinkAt(t, o.blinkOff || 0);
    for (const sd of [-1, 1]) {
      ctx.save(); ctx.translate(sd * ex, ey); ctx.scale(1, bl ? 0.12 : 1);
      circ(0, 0, 30); fs(WHITE, 6);
      const lx = (o.lookX ?? (mood === 'whisper' ? 0.8 : 0)) * 10, ly = (o.lookY || 0) * 9;
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
  else if (mood === 'squeeze' || mood === 'disgust') { seg(-72, -480, -22, -470, 11); seg(72, -480, 22, -470, 11); }
  else { for (const sd of [-1, 1]) { P(); ctx.arc(sd * 42, -462, 30, Math.PI * 1.2, Math.PI * 1.8); fs(null, 10); } }
  // Brille
  if (o.glasses !== false && mood !== 'squeeze' && mood !== 'disgust') {
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
  else if (mood === 'disgust') {
    ell(4, my + 16, 16, 20); fs('#ff6b81', 6);
    P(); ctx.moveTo(-34, my + 4); for (let i = 1; i <= 6; i++) ctx.lineTo(-34 + i * 11.3, my + 4 + (i % 2 ? -8 : 6)); fs(null, 8);
  }
  else if (mood === 'whisper') { ell(0, my, 11, 9); fs('#6b1424', 6); }
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

function drawGurkeCam(x, y, r, sc, o = {}) {
  if (sc <= 0.001) return;
  at(x, y, sc, 0, () => {
    circ(0, 0, r + 12); fs(WHITE, 8);
    ctx.save(); circ(0, 0, r); ctx.clip();
    ctx.fillStyle = o.bg || '#ffe38a'; ctx.fillRect(-r, -r, 2 * r, 2 * r);
    drawGurke(0, 400, 0.92, Object.assign({ noShadow: true, hat: 'mirror' }, o));
    ctx.restore();
    circ(0, 0, r); fs(null, 8);
    if (o.live) { circ(-r * 0.66, -r * 0.66, 13); fs(RED, 4); }
  });
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
  const lbl = window.EP_LOGO === undefined ? 'DR. GURKE ERKLÄRT' : window.EP_LOGO;
  if (!lbl) return;
  alpha(fade(t, 0.15, 0.4) * 0.95, () => {
    if (window.EP_LOGO === undefined) at(76, 214, 0.85, -0.5, () => { rr(-14, -34, 28, 68, 14); fs(GREEN, 5); });
    txt(lbl, window.EP_LOGO === undefined ? 104 : 60, 216, 28, WHITE, { align: 'left', stroke: 8 });
  });
}

function titleBlock(t, tIn, tUp, tag, big, tagCol, bigSize = 140) {
  const up = eIO(prog(t, tUp, 0.5));
  const y = lerp(470, 330, up), s = lerp(1, 0.6, up) * pop(t, tIn, 0.4);
  at(540, y, s, 0, () => {
    pill(tag, 0, -125, 50, tagCol, WHITE);
    txt(big, 0, 20, bigSize, WHITE, { stroke: 22, maxW: 960 });
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
  const hi = (window.EP_CAPCOL && window.EP_CAPCOL[c.line.spk]) || (isG ? '#9dff6a' : YELLOW);
  if (window.EP_NAMES && window.EP_NAMES[c.line.spk]) {
    const nm = window.EP_NAMES[c.line.spk];
    alpha(fade(t, c.line.start - 0.1, 0.15), () => pill(nm, cx, y - 92, 30, hi, INK, { lw: 5 }));
  }
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
function shake(t) {
  let a = 0;
  for (const s of (window.EP_STAMPS || [])) { const c = C(s); if (t >= c) a += 26 * Math.exp(-(t - c) * 9); }
  return { x: Math.sin(t * 93) * a, y: Math.cos(t * 71) * a };
}
function drawScene(name, t, dx, dy) {
  ctx.save(); ctx.translate(dx, dy);
  window.EP_SCENES[name](t);
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
