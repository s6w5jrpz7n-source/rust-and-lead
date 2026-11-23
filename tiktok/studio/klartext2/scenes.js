'use strict';
/* KLARTEXT #2 – Wohnungsanzeigen. Konfiguration für ../klartext.js */
window.KT = {
  bpm: 92,
  hook: ['WOHNUNGS-', 'ANZEIGEN'],
  cardLabel: 'WOHNUNGSANZEIGE', cardLang: 'Deutsch (Makler)',
  cardBg: '#fff1e6', cardInk: '#d9480f', cardMute: '#b98a6a',
  meta: '2 Zi. · 38 m² · 1.450 € warm',
  button: 'Besichtigung anfragen →',
  placeholderTop: 'Inserat einfügen …', placeholderBottom: 'Warte auf Maklersprech',
  source: 'Quelle: jede Wohnungsanzeige jemals.',
  notif: { title: 'Vermieter', time: 'gerade eben', lines: ['Die Wohnung ist leider schon vergeben.', 'Viel Erfolg weiterhin! LG, Horst'] },
  outroWidget: { type: 'counter', label: 'Bewerbungen verschickt:', sub: 'Antworten: 0', from: 139, to: 147 },
  o1Size: 108,
  end: { tag: 'TEIL 3', lines: ['Was dein Vermieter', 'wirklich meint.'], tagline: 'Folgen. Oder nicht. Mir doch egal.' },
};
