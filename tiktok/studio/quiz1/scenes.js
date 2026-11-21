'use strict';
/* HAUPTSTÄDTE-QUIZ – Gameshow-Optik, eigener renderFrame. Fragen identisch zu script.py halten. */
const QUIZ = [
  ['Frankreich', 'FRA', ['Lyon', 'Paris', 'Marseille'], 1],
  ['Italien', 'ITA', ['Rom', 'Mailand', 'Neapel'], 0],
  ['Spanien', 'ESP', ['Barcelona', 'Sevilla', 'Madrid'], 2],
  ['Kanada', 'CAN', ['Toronto', 'Ottawa', 'Vancouver'], 1],
  ['Australien', 'AUS', ['Canberra', 'Sydney', 'Melbourne'], 0],
  ['Türkei', 'TUR', ['Istanbul', 'Izmir', 'Ankara'], 2],
  ['Brasilien', 'BRA', ['Rio de Janeiro', 'Brasília', 'São Paulo'], 1],
  ['Kasachstan', 'KAZ', ['Astana', 'Almaty', 'Schymkent'], 0],
  ['Myanmar', 'MMR', ['Rangun', 'Mandalay', 'Naypyidaw'], 2],
  ['Burkina Faso', 'BFA', ['Bamako', 'Ouagadougou', 'Niamey'], 1],
];
const LEVELS = [['LEICHT', '#40c057'], ['LEICHT', '#40c057'], ['LEICHT', '#40c057'], ['MITTEL', '#fab005'], ['MITTEL', '#fab005'],
  ['MITTEL', '#fab005'], ['SCHWER', '#fd7e14'], ['SCHWER', '#fd7e14'], ['GENIE', '#fa5252'], ['GENIE', '#fa5252']];
const QBEAT = 60 / 128;
const MONO4 = '"JetBrains Mono", monospace';

function qIndex(t) { let k = 0; for (let i = 1; i <= 10; i++) if (t >= T('q' + i) - 0.12) k = i; return k; }
function beatPulse(t) { return Math.exp(-((t % QBEAT) / QBEAT) * 6); }

function qbg(t, hot) {
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, hot ? '#3b0a1e' : '#1b0b45'); g.addColorStop(1, hot ? '#170410' : '#07123f');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  rays(540, 760, '#ffffff', 0.05 + 0.03 * beatPulse(t), t * 0.25, 20);
  dots(t, '#9775fa', 0.25, 61);
}
function header(t) {
  const p = beatPulse(t);
  at(540, 255, 1 + 0.015 * p, 0, () => txt('HAUPTSTÄDTE-QUIZ', 0, 0, 92, YELLOW, { stroke: 16, maxW: 980 }));
  txt('Nur Genies schaffen 10/10', 540, 335, 36, WHITE, { weight: 800, stroke: 8 });
}
function progressDots(t, k, revealed) {
  for (let i = 1; i <= 10; i++) {
    const x = 120 + (i - 1) * 93, y = 410;
    const done = i < k || (i === k && revealed);
    const cur = i === k && !revealed;
    const r = cur ? 26 + 4 * beatPulse(t) : 20;
    circ(x, y, r); fs(done ? '#40c057' : cur ? YELLOW : '#343a63', 5, done || cur ? INK : '#4c5490');
    txt(String(i), x, y + 2, cur ? 26 : 22, done || cur ? INK : '#8e96d6', { weight: 900 });
  }
  if (k > 0) {
    const [lab, col] = LEVELS[k - 1];
    at(540, 478, pop(t, T('q' + k) - 0.12, 0.3), 0, () => pill('SCHWIERIGKEIT: ' + lab, 0, 0, 30, col, INK, { lw: 5 }));
  }
}
function drawShape(iso, cx, cy, maxW, maxH, col, t, capP, capLabel) {
  const s = SHAPES[iso]; const k = Math.min(maxW / s.w, maxH / s.h);
  const ox = cx - (s.w * k) / 2, oy = cy - (s.h * k) / 2;
  ctx.save();
  ctx.beginPath();
  for (const r of s.rings) { for (let i = 0; i < r.length; i += 2) { const x = ox + r[i] * k, y = oy + r[i + 1] * k; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); } ctx.closePath(); }
  const g = ctx.createLinearGradient(cx, cy - maxH / 2, cx, cy + maxH / 2); g.addColorStop(0, col[0]); g.addColorStop(1, col[1]);
  ctx.shadowColor = 'rgba(0,0,0,0.45)'; ctx.shadowBlur = 30; ctx.shadowOffsetY = 12;
  ctx.fillStyle = g; ctx.fill('evenodd'); ctx.shadowColor = 'transparent';
  ctx.lineWidth = 5; ctx.strokeStyle = WHITE; ctx.lineJoin = 'round'; ctx.stroke();
  ctx.restore();
  if (capP > 0) {
    const px = ox + s.cap[0] * k, py = oy + s.cap[1] * k;
    const drop = (1 - eOut(clamp(capP))) * 160;
    at(px, py - drop, 1, 0, () => {
      ell(0, 0, 18, 7); ctx.fillStyle = 'rgba(0,0,0,0.35)'; ctx.fill();
      P(); ctx.moveTo(0, 0); ctx.bezierCurveTo(-30, -40, -30, -80, 0, -80); ctx.bezierCurveTo(30, -80, 30, -40, 0, 0); fs(RED, 5, INK);
      circ(0, -58, 11); fs(WHITE, 0);
    });
    const side = s.cap[0] > 0.55 ? -1 : 1, lw = tw(capLabel, 34) + 40;
    if (capP > 0.5) at(px + side * (lw / 2 + 34), py - 52, eOut(clamp((capP - 0.5) * 2)), 0, () => pill(capLabel, 0, 0, 34, WHITE, INK, { lw: 5 }));
  }
}
function questionCard(t, k, slide) {
  const [land, iso, opts, right] = QUIZ[k - 1];
  const q = L['q' + k], a = L['a' + k];
  const revealed = t >= a.start - 0.05;
  ctx.save(); ctx.translate(slide * W, 0);
  rr(50, 520, 980, 590, 40); ctx.fillStyle = 'rgba(255,255,255,0.08)'; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = 'rgba(255,255,255,0.25)'; ctx.stroke();
  txt(`FRAGE ${k}/10`, 100, 565, 30, '#b197fc', { align: 'left', weight: 900 });
  txt('Hauptstadt von …', 540, 600, 40, '#dee2e6', { weight: 800 });
  at(540, 675, pop(t, q.start - 0.1, 0.35), 0, () => txt(land, 0, 0, 104, WHITE, { stroke: 14, maxW: 900 }));
  const col = k >= 9 ? ['#ff8787', '#c92a2a'] : k >= 7 ? ['#ffc078', '#e8590c'] : k >= 4 ? ['#ffe066', '#f08c00'] : ['#8ce99a', '#2f9e44'];
  at(0, 0, 1, 0, () => drawShape(iso, 540, 905, 640, 330, col, t, revealed ? prog(t, a.start, 0.45) : 0, opts[right]));
  // Countdown
  const c0 = q.end + 0.05, c1 = a.start - 0.05;
  if (t >= c0 && t < c1 + 0.05) {
    const p = clamp((t - c0) / (c1 - c0));
    const n = Math.max(1, 3 - Math.floor(p * 3));
    at(930, 580, 1 + 0.15 * Math.exp(-(((t - c0) % ((c1 - c0) / 3)) * 10)), 0, () => { circ(0, 0, 50); fs(n === 1 ? RED : YELLOW, 6, INK); txt(String(n), 0, 3, 56, INK); });
    rr(110, 1440, 860, 22, 11); ctx.fillStyle = 'rgba(255,255,255,0.15)'; ctx.fill();
    const bc = p < 0.5 ? '#40c057' : p < 0.8 ? YELLOW : RED;
    rr(110, 1440, Math.max(22, 860 * (1 - p)), 22, 11); ctx.fillStyle = bc; ctx.fill();
  }
  // Antworten
  opts.forEach((o, i) => {
    const y = 1140 + i * 96;
    const appear = pop(t, q.start + 0.05 + i * 0.07, 0.3);
    const isRight = i === right;
    let bg = '#ffffff', fg = INK, sc = 1;
    if (revealed) {
      const rp = prog(t, a.start - 0.05, 0.25);
      if (isRight) { bg = '#40c057'; fg = WHITE; sc = 1 + 0.06 * Math.sin(rp * Math.PI); }
      else { bg = '#5c2b3a'; fg = '#ff8fa3'; }
    }
    at(540, y + 38, appear * sc, 0, () => {
      rr(-420, -38, 840, 76, 38); fs(bg, 6, INK);
      circ(-372, 0, 28); fs(revealed && isRight ? WHITE : '#7048e8', 0);
      txt('ABC'[i], -372, 2, 32, revealed && isRight ? '#2b8a3e' : WHITE, { weight: 900 });
      txt(o, 10, 2, 46, fg, { weight: 900, maxW: 640 });
      if (revealed && isRight) { P(); ctx.moveTo(338, 0); ctx.lineTo(356, 18); ctx.lineTo(388, -18); ctx.lineWidth = 10; ctx.strokeStyle = WHITE; ctx.lineCap = 'round'; ctx.stroke(); }
      if (revealed && !isRight) { seg(340, -16, 376, 16, 8, '#ff8fa3'); seg(376, -16, 340, 16, 8, '#ff8fa3'); }
    });
  });
  ctx.restore();
  if (k === 10) confetti(t, a.start, 540, 900, 110);
}
function banner(t, id, text, col) {
  const l = L[id]; if (!l || t < l.start - 0.1 || t > T('q' + id.slice(1)) + 0.5) return;
  const a = fade(t, l.start - 0.1, 0.15) * (1 - fade(t, T('q' + id.slice(1)) + 0.2, 0.25));
  alpha(a, () => {
    ctx.fillStyle = col; at(540, 960, 1, -0.06, () => { ctx.fillRect(-700, -110, 1400, 220); txt(text, 0, 4, 92, WHITE, { stroke: 14, maxW: 1000 }); });
  });
}
function intro(t) {
  const go = C('go');
  const outP = eIn(prog(t, T('q1') - 0.32, 0.22));
  alpha(1 - outP, () => {
    at(540, 760, 1.04 - 0.04 * eOut(prog(t, 0, 0.8)) + 0.03 * beatPulse(t), 0, () => {
      txt('10 FRAGEN', 0, -120, 150, WHITE, { stroke: 18 });
      txt('IMMER SCHWERER', 0, 30, 104, '#ff8787', { stroke: 16, maxW: 980 });
    });
    at(540, 1060, pop(t, C('genie') - 0.1, 0.4), -0.05, () => { rr(-400, -80, 800, 160, 30); fs(YELLOW, 8); txt('10/10 = GENIE', 0, 4, 96, INK); });
  });
}
function outro(t) {
  const t0 = C('outro');
  alpha(fade(t, t0 - 0.2, 0.3), () => {
    ctx.fillStyle = 'rgba(10,5,30,0.82)'; ctx.fillRect(0, 0, W, H);
    at(540, 560, pop(t, t0 - 0.1, 0.4), 0, () => txt('Wie viele hattest du?', 0, 0, 82, WHITE, { stroke: 12, maxW: 980 }));
    [['0–4', 'Tourist', '#868e96'], ['5–7', 'Weltenbummler', '#40c057'], ['8–9', 'Professor', '#fd7e14'], ['10', 'GENIE', '#fa5252']].forEach(([r, n, c], i) => {
      at(540, 730 + i * 120, pop(t, t0 + 0.2 + i * 0.18, 0.35), 0, () => {
        rr(-380, -48, 760, 96, 48); fs(c, 6, INK);
        txt(r, -270, 3, 52, WHITE, { stroke: 8 }); txt(n, 90, 3, 56, WHITE, { stroke: 8 });
      });
    });
    at(540, 1260, pop(t, t0 + 1.2, 0.4), 0, () => txt('Schreib’s in die Kommentare 👇'.replace(' 👇', ''), 0, 0, 50, YELLOW, { stroke: 10, weight: 900 }));
  });
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  const k = qIndex(t);
  qbg(t, k >= 8);
  header(t);
  if (k === 0) intro(t);
  else if (t < C('outro') + 0.2) {
    const a = L['a' + k];
    progressDots(t, k, t >= a.start - 0.05);
    const slideIn = 1 - eOut(prog(t, T('q' + k) - 0.12, 0.3));
    if (k > 1 && slideIn > 0) {
      const pk = k - 1;
      ctx.save(); ctx.globalAlpha = slideIn; ctx.translate(-(1 - slideIn) * W, 0); questionCard(t, pk, 0); ctx.restore();
    }
    questionCard(t, k, slideIn);
  }
  banner(t, 'h8', 'JETZT WIRD’S SCHWER', 'rgba(232,89,12,0.95)');
  banner(t, 'h10', 'LETZTE FRAGE – NUR FÜR GENIES', 'rgba(201,42,42,0.95)');
  if (t >= C('outro') - 0.2) outro(t);
};
window.EP_SCENES = {};
