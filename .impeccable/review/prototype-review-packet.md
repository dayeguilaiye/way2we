# Prototype finish review packet

Target: `/Users/zz-b191/code/way2we/prototype/index.html`, `style.css`, `app.js`, `model.js`.

Run: `http://127.0.0.1:56446/prototype/` (project-local server is running). Portable artifact `prototype/way2we-demo.html` is generated with `python3 prototype/package-demo.py`; repackage after final fixes.

Direction contract: `docs/design/prototype-brief.md`. Product: `PRODUCT.md`, `docs/product/rules.md`. Authority: `.impeccable/mocks/themes/apricot-reference.png`, `.impeccable/mocks/actions-v1/refund-confirm-v2.png`, other approved core/actions images listed in docs/design/visual-reference.md.

User scope: stage 2.3 interactive prototype after accepting revised refund sheet. Warm, refined, clear. App-first Flutter + Go remains production direction. Current artifact is a browser-based memory demo, with simulated identities and network controls outside the phone. Do not redesign, add business rules, or imply this is a production client.

Required viewed evidence (all in `.impeccable/review/`): `desktop.png` (1440×1080), `mobile.png` (390×846), `refund.png`, `refund-large.png` (320×780, 160% reading size with long names), `score.png`, `agreement-form.png`, `shop.png`, `themes.png`. Captures are settled; parent has opened each. Other current state captures: agreements, item-form, my-shop, order, buy, home-celadon, refund-rose, narrow-large.

Verified in browser: initial A10/B0; scoring to A20; purchasing two 10-point items to A0 with B0 unchanged; B completion followed by full refund to A20; invitation accepted by C remains waiting until B agrees; seller exit refunds initial pending order to A30, restore retains cancelled history; B rose preference persists in weekend space. Form failure retains entered name and succeeds on retry. Standalone `file://` opens with zero broken images and no external script/style dependencies. Models also exercised repeated refund/revoke, changed agreement original-value reversal, negative balances, all-members-exit restore.

Boundaries: network failure is simulated before mutation. Real Go transactions, persistent identity, recovery after a committed timeout, concurrent requests, native OS back/keyboard/push require stage 3 implementation. Browser large-text controls exercise layout; they do not substitute for native-device validation.

Visual/tool evidence: comp-diff at exact 851×1847 reports overall 0.8641 (`match`) but some local-region flags remain. Main action uses approved token #A65A40 for white-text contrast; generated reference was #C87858. New avatar photos are independent generated assets. Activity actor avatars now match the record actor (reference second row pictured cat beside A's action). Photos, glyphs, and semantic color deltas produce local heuristic flags even where visible content is present. Do not claim the entire comp gate passed: build-phase state remains `plates`; my-avatar and avatar-b detail-density checks failed after two generations (68%,46%), parent viewed originals and new photos and proceeded with usable images. Thresholds and original comp unchanged. Report remaining fidelity limitations at actual scope.

Detector: `.impeccable/review/detector.json`, only cream-palette warning, justified by user-selected warm design. Shipping raster provenance scan: 12 rasters, 0 missing. Source/output paths and alpha QA in `.impeccable/build/asset-provenance.json` and `asset-alpha-qa.png`. Noto Serif SC self-hosted subset with OFL license in prototype/assets/fonts.

Review the existing artifact for material interaction, accessibility and visual failures. Fresh review and a bounded actionable fix list; no generic redesign and no code edits. Save your finding table and disposition in `.impeccable/review/prototype-finish-review.md`.
