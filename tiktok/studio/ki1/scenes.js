'use strict';
/* KI-VIDEO – „Ich lasse eine KI meine TikToks machen“ (Blick hinter die Kulissen) */
window.EP_LOGO = false;
window.EP_CAPCOL = { N: '#ff8a5b' };
const CORAL = '#ff8a5b', VIO = '#9775fa', MINT = '#63e6be', DARK = '#0f1020';
const PX = 540, PY = 880, PW = 470, PH = 836;
const IMGS = {};
function clipImg(name, i) {
  const k = name + i;
  if (!IMGS[k]) IMGS[k] = new Promise(res => { const im = new Image(); im.onload = () => res(im); im.onerror = () => res(null); im.src = `../build/ki1/clips/${name}/f${String(i).padStart(4, '0')}.jpg`; });
  return IMGS[k];
}
const CLIPLEN = { katze: 90, philo: 36, hist: 36, hell: 36, iw: 36, quiz: 36, emc: 36, auto: 120, autowide: 180 };
async function clipFrame(name, lt) { const n = CLIPLEN[name]; return clipImg(name, Math.min(n - 1, Math.max(0, Math.floor(lt * 30) % n))); }
function bgK(t) {
  const g = ctx.createLinearGradient(0, 0, W, H); g.addColorStop(0, '#141533'); g.addColorStop(1, '#2a1846'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.strokeStyle = 'rgba(255,255,255,0.05)'; ctx.lineWidth = 2; for (let x = (t * 20) % 60; x < W; x += 60) { P(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke(); } for (let y = (t * 20) % 60; y < H; y += 60) { P(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }
  for (let i = 0; i < 3; i++) { const x = 540 + Math.cos(t * 0.4 + i * 2) * 380, y = 900 + Math.sin(t * 0.3 + i * 2) * 600; const rg = ctx.createRadialGradient(x, y, 0, x, y, 420); rg.addColorStop(0, i === 1 ? 'rgba(255,138,91,0.18)' : 'rgba(151,117,250,0.18)'); rg.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = rg; ctx.fillRect(0, 0, W, H); }
}
function phone(fn, s = 1, x = PX, y = PY) {
  at(x, y, s, 0, () => {
    rr(-PW / 2 - 18, -PH / 2 - 18, PW + 36, PH + 36, 60); fs('#0b0b10', 6, '#3b3d52');
    ctx.save(); rr(-PW / 2, -PH / 2, PW, PH, 44); ctx.clip(); ctx.fillStyle = '#000'; ctx.fillRect(-PW / 2, -PH / 2, PW, PH); fn(); ctx.restore();
    rr(-60, -PH / 2 - 4, 120, 26, 13); ctx.fillStyle = '#0b0b10'; ctx.fill();
  });
}
function drawClip(im) { if (im) ctx.drawImage(im, -PW / 2, -PH / 2, PW, PH); }
function typed(s, t, t0, cps = 22) { return s.slice(0, Math.max(0, Math.floor((t - t0) * cps))); }
function chatUI(t, msgs) {
  ctx.fillStyle = '#f8f9fa'; ctx.fillRect(-PW / 2, -PH / 2, PW, PH);
  ctx.fillStyle = '#fff'; ctx.fillRect(-PW / 2, -PH / 2, PW, 110); seg(-PW / 2, -PH / 2 + 110, PW / 2, -PH / 2 + 110, 2, '#dee2e6');
  circ(-PW / 2 + 60, -PH / 2 + 62, 26); fs(CORAL, 0); txt('KI', -PW / 2 + 60, -PH / 2 + 63, 22, '#fff');
  txt('Claude', -PW / 2 + 100, -PH / 2 + 62, 30, INK, { align: 'left', weight: 800 });
  let y = -PH / 2 + 170;
  for (const m of msgs) {
    if (!m.text) continue;
    ctx.save(); ctx.font = `700 34px ${FONT}, "Noto Color Emoji"`;
    const words = m.text.split(' '), lines = []; let cur = '';
    for (const w of words) { const tst = cur ? cur + ' ' + w : w; if (ctx.measureText(tst).width > PW - 150) { lines.push(cur); cur = w; } else cur = tst; }
    if (cur) lines.push(cur);
    const bw = Math.max(...lines.map(l => ctx.measureText(l).width)) + 44, bh = lines.length * 44 + 30;
    const bx = m.me ? PW / 2 - 24 - bw : -PW / 2 + 24;
    rr(bx, y, bw, bh, 24); ctx.fillStyle = m.me ? CORAL : '#e9ecef'; ctx.fill();
    ctx.fillStyle = m.me ? '#fff' : INK; ctx.textBaseline = 'middle'; ctx.textAlign = 'left';
    lines.forEach((l, i) => ctx.fillText(l, bx + 22, y + 37 + i * 44));
    ctx.restore();
    y += bh + 24;
  }
  if (msgs.typing) { const x = -PW / 2 + 60; for (let i = 0; i < 3; i++) { circ(x + i * 26, y + 30 + Math.sin(t * 10 + i) * 6, 9); fs('#adb5bd', 0); } }
}
const SCRIPT = [['FLITZI', 'Tüt tüt! Pfützen sind die besten!'], ['FLITZI', 'Oh nein! Ich stecke im Matsch fest!'], ['TONI', 'Keine Sorge, Flitzi! Ich zieh dich raus!'], ['FRIDA', 'Ich hab eine Idee! Wasser marsch!']];
const CODE = ['function car(x, y, s, o) {', '  const col = "#22b8cf";', '  bodyPath(); fill(col);', '  rr(-110, -250, 90, 90, 30);', '  eyes(52, -205, 26, o);', '  mouth(168, -98, 60, o);', '  wheel(-125, -45, 46);', '  wheel(125, -45, 46);', '}'];
function bigText(t, t0, a, b, y = 330, col = '#fff') { at(540, y, pop(t, t0, 0.35), 0, () => { txt(a, 0, 0, 66, col, { stroke: 12, sc: DARK, maxW: 980 }); if (b) txt(b, 0, 78, 50, CORAL, { stroke: 10, sc: DARK, maxW: 980 }); }); }
async function scene(t) {
  const L1 = TL.lines.reduce((acc, l) => (t >= l.start - 0.15 ? l : acc), TL.lines[0]);
  const id = L1.id, lt = t - (L1.start - 0.15);
  bgK(t);
  if (id === 'ki1') {
    const boom = C('boom');
    if (t < boom - 0.1) { phone(() => chatUI(t, [{ me: true, text: typed('Mach mir ein Video über Katzen 🐱', t, 0.4, 16) }])); bigText(t, 0.2, 'Ich schreibe 1 Satz …', null); }
    else { const im = await clipFrame('katze', t - boom); phone(() => drawClip(im), 1 + 0.06 * Math.exp(-(t - boom) * 5)); bigText(t, boom, '… und die KI macht', 'ein ganzes Video daraus'); for (let i = 0; i < 12; i++) { const u = prog(t, boom, 0.8), a = i / 12 * Math.PI * 2; alpha(1 - u, () => emo('✨', PX + Math.cos(a) * (300 + u * 200), PY + Math.sin(a) * (420 + u * 200), 56)); } }
  } else if (id === 'ki2') {
    const list = TL.data.montage, k = Math.min(list.length - 1, Math.floor(lt / 0.55)), name = list[k];
    const im = await clipFrame(name, lt - k * 0.55);
    phone(() => drawClip(im));
    if (lt - k * 0.55 < 0.06) { ctx.fillStyle = 'rgba(255,255,255,0.4)'; ctx.fillRect(0, 0, W, H); }
    at(540, 330, pop(t, L1.start, 0.35), 0, () => pill('gezeichnet von Menschen: 0', 0, 0, 40, CORAL, '#fff', { lw: 0 }));
    if (t > C('stimme0')) at(540, 420, pop(t, C('stimme0'), 0.35), 0, () => pill('gesprochen von Menschen: 0', 0, 0, 40, VIO, '#fff', { lw: 0 }));
  } else if (id === 'ki3') {
    const b = C('bsp'), q = 'Mach ein Video über Autos, die sich helfen. Verspielte Musik.';
    const msgs = [{ me: true, text: t > b ? typed(q, t, b, 24) : '' }];
    const done = b + q.length / 24 + 0.3;
    if (t > done + 0.6) msgs.push({ me: false, text: 'Mache ich! 🚗 Ich schreibe das Drehbuch, zeichne die Figuren und vertone alles.' });
    msgs.typing = t > done && t < done + 0.6;
    phone(() => chatUI(t, msgs));
    bigText(t, L1.start, 'Die KI heißt Claude', null);
  } else if (id === 'ki4') {
    bigText(t, L1.start, 'Schritt 1', 'Das Drehbuch');
    at(540, 960, pop(t, L1.start, 0.4), -0.02, () => {
      rr(-420, -420, 840, 840, 20); fs('#fffdf5', 6, '#ced4da');
      txt('DIE RETTUNGSFLITZER – Folge 1', -380, -360, 30, INK, { align: 'left', weight: 900 });
      SCRIPT.forEach(([who, line], i) => { const tt0 = L1.start + 0.3 + i * 0.55; if (t < tt0) return; txt(who, -380, -270 + i * 150, 30, CORAL, { align: 'left', weight: 900 }); txt(typed(line, t, tt0, 40), -380, -228 + i * 150, 32, INK, { align: 'left', weight: 600, maxW: 760 }); });
    });
  } else if (id === 'ki5') {
    bigText(t, L1.start, 'Schritt 2', 'Figuren aus Code');
    at(540, 700, 1, 0, () => {
      rr(-460, -230, 920, 460, 24); fs('#1e1e2e', 4, '#3b3d52');
      CODE.forEach((l, i) => { const tt0 = L1.start + 0.2 + i * 0.28; if (t < tt0) return; ctx.save(); ctx.font = `600 30px "DejaVu Sans Mono", monospace`; ctx.fillStyle = l.includes('function') || l.trim() === '}' ? '#c792ea' : l.includes('"') ? '#c3e88d' : '#82aaff'; ctx.textBaseline = 'middle'; ctx.fillText(typed(l, t, tt0, 60), -430, -195 + i * 46); ctx.restore(); });
    });
    const rev = clamp((lt - 0.3) / 2.8);
    ctx.save(); P(); ctx.rect(0, 960, W * rev, 700); ctx.clip();
    car(540, 1330, 1.0, { t, type: 'mini', mood: rev > 0.95 ? 'happy' : 'surprised', mouth: 0, spin: 0, look: 0.6 }); ctx.restore();
    if (rev < 1) at(W * rev, 1160, 1, 0, () => emo('✏️', 0, 0, 80));
    if (TL.cues.pinsel && t > C('pinsel')) at(540, 1500, pop(t, C('pinsel'), 0.35), 0, () => { emo('🖌️', -120, 0, 80); txt('❌', -60, 30, 50, '#e03131'); emo('💻', 80, 0, 80); txt('✅', 140, 30, 50, '#2f9e44'); });
  } else if (id === 'ki6') {
    bigText(t, L1.start, 'Schritt 3', 'KI-Stimmen + Sound');
    const amp = mouthOf('N', t);
    for (let i = 0; i < 24; i++) { const h = 40 + 360 * amp * (0.4 + 0.6 * Math.abs(Math.sin(i * 1.7 + t * 9))); rr(140 + i * 34 - 12, 880 - h / 2, 24, h, 12); ctx.fillStyle = i % 2 ? CORAL : VIO; ctx.fill(); }
    at(540, 1120, 1, 0, () => pill('🔊 KI-Sprachmodell (kostenlos)', 0, 0, 38, '#fff', INK, { lw: 0 }));
    if (t > C('musik')) for (let i = 0; i < 8; i++) { const u = ((t - C('musik')) * 0.8 + i / 8) % 1; alpha(Math.sin(u * Math.PI), () => emo(['🎵', '🎶', '💥', '🥁'][i % 4], 140 + i * 110, 1450 - u * 380, 60)); }
  } else if (id === 'ki7') {
    bigText(t, L1.start, 'Schritt 4', 'Bild für Bild zum Video');
    const fw = 260, fh = 462, off = (lt * 340) % (fw + 30);
    ctx.fillStyle = '#111'; ctx.fillRect(0, 640, W, fh + 80);
    for (let i = -1; i < 6; i++) {
      const x = -off + i * (fw + 30) + 30, idx = Math.floor(lt * 12) + i * 3;
      const im = await clipImg('autowide', Math.max(0, Math.min(179, (idx * 5) % 180)));
      if (im) ctx.drawImage(im, x, 680, fw, fh); ctx.strokeStyle = '#fff'; ctx.lineWidth = 4; ctx.strokeRect(x, 680, fw, fh);
    }
    for (let x = (-lt * 340) % 40; x < W; x += 40) { rr(x, 652, 22, 18, 4); ctx.fillStyle = '#fff'; ctx.fill(); rr(x, 680 + fh + 12, 22, 18, 4); ctx.fill(); }
    at(540, 1250, 1, 0, () => pill(`Bild ${Math.floor(lt * 300) + 1} von 1309`, 0, 0, 38, '#fff', INK, { lw: 0 }));
    if (t > C('fps')) at(540, 1250, pop(t, C('fps'), 0.35), 0, () => pill('30 Bilder pro Sekunde', 0, 0, 46, CORAL, '#fff', { lw: 0 }));
  } else if (id === 'ki8') {
    const g = C('groesser'), z = t < g ? 0.55 : lerp(0.55, 1, eBack(prog(t, g, 0.5)));
    const im = await clipFrame('autowide', lt);
    at(540, 330, 1, 0, () => { rr(-360, -56, 720, 112, 40); ctx.fillStyle = CORAL; ctx.fill(); txt(typed('„Mach die Autos größer.“', t, L1.start + 1.0, 20), 0, 2, 44, '#fff'); });
    phone(() => { ctx.fillStyle = '#74c0fc'; ctx.fillRect(-PW / 2, -PH / 2, PW, PH); if (im) { const w = PW * z, h = PH * z; ctx.drawImage(im, -w / 2, -h / 2 + (1 - z) * 160, w, h); } });
    if (t > g) at(860, 560, pop(t, g, 0.3), 0.1, () => txt('✅ erledigt', 0, 0, 44, MINT, { stroke: 8, sc: DARK }));
  } else if (id === 'ki9') {
    const pst = C('post');
    phone(() => { ctx.fillStyle = '#16161a'; ctx.fillRect(-PW / 2, -PH / 2, PW, PH); txt('Neuer Beitrag', 0, -PH / 2 + 80, 34, '#fff');
      rr(-150, -300, 300, 420, 20); ctx.fillStyle = '#2b2b33'; ctx.fill(); txt('🎬', 0, -100, 90, '#fff');
      const press = t > pst && t < pst + 0.25 ? 0.92 : 1; at(0, 300, press, 0, () => { rr(-170, -50, 340, 100, 50); ctx.fillStyle = '#fe2c55'; ctx.fill(); txt('Posten', 0, 3, 44, '#fff'); }); });
    bigText(t, L1.start, 'Komplett ohne Arbeit?', null);
    if (t > C('fast')) at(540, 400, pop(t, C('fast'), 0.35), -0.04, () => txt('Fast. 😅', 0, 0, 60, CORAL, { stroke: 12, sc: DARK }));
    if (t > pst - 0.4) { const u = eOut(prog(t, pst - 0.4, 0.4)); emo('👆', PX + 60, lerp(1500, PY + 330, u), 110); }
  } else {
    const im = await clipFrame('auto', lt);
    phone(() => drawClip(im), 0.82, 540, 1000);
    at(540, 300, pop(t, L1.start, 0.4), 0, () => { txt('Was soll Claude als', 0, -40, 62, '#fff', { stroke: 12, sc: DARK }); txt('Nächstes machen? 👇', 0, 40, 62, CORAL, { stroke: 12, sc: DARK }); });
  }
}
window.renderFrame = async function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  await scene(t);
  pill('🤖 KI-STUDIO · hinter den Kulissen', 540, 150, 28, 'rgba(255,255,255,0.12)', '#fff', { lw: 0 });
  drawCaptions(t);
};
window.EP_SCENES = {};
