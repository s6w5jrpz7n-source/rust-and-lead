// node render.js <folge> stills t1,t2,...  |  node render.js <folge> video startFrame endFrame out.mp4
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
(async () => {
  const ep = process.argv[2];
  const mode = process.argv[3];
  const arg = process.argv.slice(4);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await page.goto('file://' + path.join(__dirname, ep, 'index.html'));
  await page.evaluate(async () => { await document.fonts.load('900 80px "Inter Display"'); await document.fonts.load('800 80px "Inter Display"'); await document.fonts.load('600 80px "Inter Display"'); });
  if (errs.length) { console.error(errs.join('\n')); }
  const canvas = await page.$('canvas');
  if (mode === 'stills') {
    const times = arg[0].split(',').map(Number);
    const dir = path.join(__dirname, 'stills', ep); require('fs').mkdirSync(dir, { recursive: true });
    for (const t of times) {
      await page.evaluate(async t => { await window.renderFrame(t); }, t);
      await canvas.screenshot({ path: path.join(dir, `t_${t.toFixed(2)}.png`) });
    }
  } else {
    const [a, b, out] = [Number(arg[0]), Number(arg[1]), arg[2]];
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
