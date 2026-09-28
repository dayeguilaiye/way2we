const fs = require('node:fs');
const { chromium } = require('/Users/zz-b191/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root = '/Users/zz-b191/code/way2we';
const items = [
 ['暖杏枝叶', 'assets/plates/botanical.png'],
 ['青瓷叶影', 'prototype/assets/botanical-celadon.png'],
 ['雾玫花枝', 'prototype/assets/botanical-rose.png'],
 ['盆栽头像', 'assets/plates/my-avatar.png'],
 ['猫头像', 'assets/plates/avatar-b.png']
];
const cells = items.map(([label, path]) => {
 const uri = 'data:image/png;base64,' + fs.readFileSync(root + '/' + path).toString('base64');
 return `<section><h2>${label}</h2><div class="light"><img src="${uri}"></div><div class="dark"><img src="${uri}"></div></section>`;
}).join('');
(async () => {
 const browser = await chromium.launch({headless: true, executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'});
 const page = await browser.newPage({viewport: {width: 1300, height: 650}, deviceScaleFactor: 1});
 await page.setContent(`<style>*{box-sizing:border-box}body{margin:0;padding:20px;background:#ece9e4;display:grid;grid-template-columns:repeat(5,1fr);gap:12px;font-family:sans-serif}h2{font-size:16px;font-weight:500}section>div{width:100%;height:255px;padding:6px;margin-bottom:10px;display:grid;place-items:center}.light{background:#f8f4ee}.dark{background:#252624}img{display:block;width:100%;height:auto;max-height:245px;object-fit:contain}</style>${cells}`);
 await page.locator('img').evaluateAll(images => Promise.all(images.map(image => image.decode())));
 await page.screenshot({path: root + '/.impeccable/build/asset-alpha-qa.png', fullPage:true});
 await browser.close();
})();
