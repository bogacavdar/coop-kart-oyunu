// Oyunun web sürümünü gerçek bir Chrome'da açıp ekran görüntüleri alır.
// Kullanım: node ekran.js savas:tas_golem savas:lich_kral ...
const { chromium } = require('playwright');
(async () => {
  const tarayici = await chromium.launch({
    channel: 'chrome',
    args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--ignore-gpu-blocklist', '--enable-webgl'],
  });
  const sayfa = await tarayici.newPage({ viewport: { width: 1280, height: 720 } });
  sayfa.on('console', m => { const t = m.text(); if (/error|hata/i.test(t)) console.log('KONSOL:', t); });
  for (const ad of process.argv.slice(2)) {
    const adres = 'http://localhost:8000/index.html' + (ad === 'ana' ? '' : '?onizleme=' + encodeURIComponent(ad));
    await sayfa.goto(adres);
    await sayfa.waitForTimeout(16000);
    const dosya = 'ekran_' + ad.replace(/[^a-z0-9_]/gi, '_') + '.png';
    await sayfa.screenshot({ path: dosya });
    console.log('Görüntü alındı:', dosya);
  }
  await tarayici.close();
})();
