# Card artwork — not published

These product shots are staged, not live. `.vercelignore` keeps `cards/`
out of every deployment, so nothing under this folder is served from
creditcardspicks.com.

Held back until the affiliate programs (Discover, Capital One, Chase,
American Express) confirm we may use their card artwork. Each program's
agreement governs this; approval is per issuer, not blanket.

## To publish, once approved

1. Delete the `cards/` line from `.vercelignore`.
2. In `compare.html`, replace each `<div class="plastic p-*">` with:
   `<img class="card-photo" src="cards/NAME.jpg" alt="CARD NAME" width="280" height="186"/>`
3. Same for `es/comparar.html`, using `../cards/NAME.jpg`.
4. The `.card-photo` CSS is already in `styles.css`.
5. `vercel --prod --yes`

Files are 796x534 JPEG. The 280x186 attributes are a layout hint only;
`height:auto` uses the real ratio.
