'use strict';
/* der drang #8: im wichtigsten meeting aufzutauchen */
const EV = TL.data.ev;
const TX0 = 40, TY0 = 440, TW = 1000, TH = 580;
function emoji(e, x, y, size) { ctx.save(); ctx.font = `${size}px "Noto Color Emoji"`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(e, x, y); ctx.restore(); }
function human(x, y, s, sweat) {
  at(x, y, s, 0, () => {
    rr(-170, -40, 340, 220, 90); fs('#4c6ef5', 6, '#1c2b6b');
    circ(0, -150, 110); fs('#f2c7a5', 6, '#7a4a2a');
    P(); ctx.arc(0, -170, 112, Math.PI * 1.05, Math.PI * 1.95); ctx.closePath(); ctx.fillStyle = '#3d2a1a'; ctx.fill();
    for (const sd of [-1, 1]) { circ(sd * 38, -150, 12); ctx.fillStyle = INK; ctx.fill(); }
    P(); ctx.arc(0, -105, 28, Math.PI * 0.15, Math.PI * 0.85); fs(null, 6, '#7a1f2b');
    if (sweat) { ell(90, -200, 10, 16); fs('#74c0fc', 3, '#1c7ed6'); }
  });
}
function tile(x, y, w, h, who, face, speaking) {
  rr(x, y, w, h, 18); ctx.fillStyle = '#2c2f38'; ctx.fill();
  emoji(face, x + w / 2, y + h / 2 - 10, h * 0.48);
  pill(who, x + 70, y + h - 30, 22, 'rgba(0,0,0,0.55)', WHITE, { lw: 0 });
  rr(x, y, w, h, 18); fs(null, speaking ? 6 : 2, speaking ? '#40c057' : '#3a3d4d');
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
  ctx.fillStyle = '#18191d'; ctx.fillRect(0, 0, W, H);
  txt('Q4-Meeting · 4 Teilnehmer', 60, 405, 30, '#ced4da', { align: 'left', weight: 800 }); circ(1010, 405, 10); ctx.fillStyle = RED; ctx.fill();
  // eigene Kachel
  ctx.save(); rr(TX0, TY0, TW, TH, 22); ctx.clip();
  const bg = ctx.createLinearGradient(0, TY0, 0, TY0 + TH); bg.addColorStop(0, '#d8cbb5'); bg.addColorStop(1, '#bfae92'); ctx.fillStyle = bg; ctx.fillRect(TX0, TY0, TW, TH);
  rr(TX0 + 60, TY0 + 60, 260, 170, 8); fs('#fff', 4, '#8d6e63'); txt('Q4 ↗', TX0 + 190, TY0 + 145, 50, '#2b8a3e');
  human(540, TY0 + TH - 10, 1.25, t > EV.leave);
  // Schwanz quer durchs Bild (Anfang und Ende → Schleife)
  const sweep = (a, d) => { const u = prog(t, a, d); if (u <= 0 || u >= 1) return; const x = lerp(TX0 - 300, TX0 + TW + 300, u); P(); ctx.moveTo(x - 260, TY0 + TH + 60); ctx.bezierCurveTo(x - 120, TY0 + 200, x + 80, TY0 + 120, x + 200, TY0 + 260); ctx.lineWidth = 150; ctx.strokeStyle = CAT.line; ctx.lineCap = 'round'; ctx.stroke(); ctx.lineWidth = 130; ctx.strokeStyle = CAT.fur; ctx.stroke(); for (let i = 0; i < 4; i++) circ(x - 180 + i * 90, TY0 + 330 - i * 50, 26), ctx.fillStyle = CAT.dark, ctx.fill(); };
  sweep(-0.6, 1.8); sweep(8.6, 1.8);
  if (t >= EV.butt && t < EV.face) catBack(540, TY0 + TH + 200, 1.45 + 0.05 * Math.sin(t * 3), { t });
  if (t >= EV.face && t < EV.lie) { const z = 1.3 + 0.25 * kk(t, EV.face, EV.face + 0.8); catHead(540 + Math.sin(t * 2) * 20, TY0 + 330, z, { t, pupil: 40, gaze: [0, 0.2] }); }
  if (t >= EV.lie && t < EV.leave + 0.5) {
    const out = kk(t, EV.leave, EV.leave + 0.5);
    catLoaf(560 + out * 900, TY0 + TH + 40, 1.0, { t, pupil: 14, lid: 0.4 });
    rr(TX0 + 20, TY0 + 20, 520, 64, 14); ctx.fillStyle = 'rgba(0,0,0,0.6)'; ctx.fill();
    txt('🔇  Du bist stummgeschaltet', TX0 + 40, TY0 + 52, 30, WHITE, { align: 'left', weight: 800 });
  }
  if (t >= EV.butt && t < EV.lie) for (let i = 0; i < 6; i++) { const u = ((t - EV.butt) * 0.7 + i / 6) % 1; alpha(1 - u, () => emoji(['😂', '😂', '👏', '😹', '❤️', '😂'][i], TX0 + 120 + i * 150, TY0 + TH - 60 - u * 420, 64)); }
  ctx.restore();
  rr(TX0, TY0, TW, TH, 22); fs(null, 6, '#40c057');
  pill('Du (präsentierst)', TX0 + 150, TY0 + TH - 34, 24, 'rgba(0,0,0,0.6)', WHITE, { lw: 0 });
  // Kollegen
  const chef = t >= EV.butt && t < EV.leave ? '😐' : t >= EV.leave ? '😑' : '🙂';
  const anna = t >= EV.butt ? '😂' : '🙂', jonas = t >= EV.face ? '😍' : '🙂';
  tile(40, 1040, 320, 200, 'Chef', chef, t >= EV.chat1 && t < EV.chat1 + 0.8);
  tile(380, 1040, 320, 200, 'Anna', anna, false);
  tile(720, 1040, 320, 200, 'Jonas', jonas, false);
  const chat = (tt0, who, msg, y) => { if (t < tt0) return; at(540, y, pop(t, tt0, 0.3), 0, () => { const w = tw(`${who}: ${msg}`, 32, 800) + 60; rr(-w / 2, -36, w, 72, 24); ctx.fillStyle = 'rgba(255,255,255,0.95)'; ctx.fill(); txt(`${who}: ${msg}`, 0, 2, 32, INK, { weight: 800 }); }); };
  chat(EV.chat1, 'Chef', 'Ist das Teil der Präsentation?', 1292);
  chat(EV.chat2, 'Anna', 'Bitte mehr davon 😂', 1370);
  drangBadge(8);
  drangCaption(['der drang, im wichtigsten', 'meeting aufzutauchen 😼']);
  shareBand(t, EV.band, 'schick das deinen kollegen 😼');
};
window.EP_SCENES = {};
