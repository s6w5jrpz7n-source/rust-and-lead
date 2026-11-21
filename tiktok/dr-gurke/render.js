// node render.js stills t1,t2,...  |  node render.js video startFrame endFrame out.mp4
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
(async () => {
  const mode = process.argv[2];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await page.goto('file://' + path.join(__dirname, 'index.html'));
  await page.evaluate(async () => { await document.fonts.load('900 80px "Inter Display"'); await document.fonts.load('800 80px "Inter Display"'); await document.fonts.load('600 80px "Inter Display"'); });
  if (errs.length) { console.error(errs.join('\n')); }
  const canvas = await page.$('canvas');
  if (mode === 'stills') {
    const times = process.argv[3].split(',').map(Number);
    for (const t of times) {
      await page.evaluate(t => window.renderFrame(t), t);
      await canvas.screenshot({ path: path.join(__dirname, 'stills', `t_${t.toFixed(2)}.png`) });
    }
  } else {
    const [a, b, out] = [Number(process.argv[3]), Number(process.argv[4]), process.argv[5]];
    const ff = spawn('ffmpeg', ['-y', '-v', 'error', '-f', 'image2pipe', '-framerate', '30', '-c:v', 'mjpeg', '-i', '-',
      '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-r', '30', out], { stdio: ['pipe', 'inherit', 'inherit'] });
    for (let f = a; f < b; f++) {
      await page.evaluate(t => window.renderFrame(t), f / 30);
      const buf = await canvas.screenshot({ type: 'jpeg', quality: 93 });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  if (errs.length) console.error('ERRORS:', errs.join('\n'));
  await browser.close();
})();
