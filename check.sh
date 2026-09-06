#!/usr/bin/env bash
# Pre-push checks for the CardPick static site.
# Catches the regressions that rewriting a whole HTML file keeps causing.
# Usage: ./check.sh    (exit 0 = clean, 1 = problems found)

cd "$(dirname "$0")" || exit 1
BASE="https://creditcardspicks.com"
fail=0
FAILFLAG=$(mktemp)
note() { echo "  $1"; : > "$FAILFLAG.hit"; }

pages() { find . -name '*.html' -not -path './.git/*'; }

echo "1. rel=canonical on every page"
for f in $(pages); do
  grep -q 'rel="canonical"' "$f" || note "missing canonical: ${f#./}"
done

echo "2. internal links and assets resolve"
for f in $(pages); do
  dir=$(dirname "$f")
  { grep -o 'href="[^"]*"' "$f"; grep -o 'src="[^"]*"' "$f"; } \
    | sed 's/^[a-z]*="//;s/"$//' | while read -r L; do
      case "$L" in http*|mailto:*|data:*|\#*|"") continue ;; esac
      t="${L%%#*}"; [ -z "$t" ] && continue
      case "$t" in /*) p=".$t" ;; *) p="$dir/$t" ;; esac
      [ -e "$p" ] || echo "  broken link: ${f#./} -> $L"
    done
done | sort -u | { grep . && : > "$FAILFLAG.hit"; true; }

echo "3. CSS classes used in HTML but not defined in styles.css"
for c in $(grep -ho 'class="[^"]*"' $(pages) | sed 's/class="//;s/"$//' | tr ' ' '\n' | sort -u); do
  case "$c" in ""|*[!a-zA-Z0-9_-]*) continue ;; esac
  grep -q "\.$c[ ,{:]" styles.css || note "class used but undefined: .$c"
done

echo "4. every canonical URL is in sitemap.xml"
grep -ho 'rel="canonical" href="[^"]*"' $(pages) | sed 's/.*href="//;s/"$//' | sort -u \
  | while read -r u; do grep -qF "<loc>$u</loc>" sitemap.xml || echo "  not in sitemap: $u"; done \
  | { grep . && : > "$FAILFLAG.hit"; true; }

echo "5. robots.txt points at the live domain"
grep -q "Sitemap: $BASE/sitemap.xml" robots.txt || note "robots.txt sitemap URL is wrong"

echo "6. held-back assets are not referenced by any page"
if [ -f .vercelignore ]; then
  grep -v '^#' .vercelignore | grep -v '^$' | sed 's:/$::' | while read -r d; do
    grep -lE "(src|href)=\"(\.\./)*$d/" $(pages) 2>/dev/null | while read -r f; do
      echo "  ${f#./} references $d/ but .vercelignore excludes it from deploys"
    done
  done | { grep . && : > "$FAILFLAG.hit"; true; }
fi

echo
if [ -e "$FAILFLAG.hit" ]; then
  echo "FAIL - see above"; rc=1
else
  echo "PASS - nothing to fix"; rc=0
fi
rm -f "$FAILFLAG" "$FAILFLAG.hit"
exit $rc
