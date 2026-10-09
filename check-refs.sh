#!/usr/bin/env bash
# Prüft Bib-Dateien und Zitate vor dem Build.
cd "$(dirname "$0")"
err=0
for f in Datasheet-Quellen/*/*.bib; do
  grep -nE '^@[A-Za-z]+\{\s*,' "$f" | sed "s|^|LEERER KEY  $f:|" && err=1
  biber --tool --validate-datamodel -q -O /dev/null "$f" 2>&1 | grep -E 'ERROR' | sed "s|^|SYNTAX     $f: |" && err=1
done
keys=$(grep -hoE '^@[A-Za-z]+\{[^,]+' Datasheet-Quellen/*/*.bib | grep -vi '^@comment' | sed 's/.*{//' | sort)
dups=$(uniq -d <<<"$keys"); [ -n "$dups" ] && { echo "DOPPELT: $dups"; err=1; }
for k in $(grep -rhoE '\\[a-zA-Z]*cite[a-z]*(\[[^]]*\])*\{[^}]+\}' Kapitel main.tex | sed 's/.*{//;s/}//' | tr ',' '\n' | tr -d ' ' | sort -u); do
  grep -qxF "$k" <<<"$keys" || { echo "FEHLT      \\cite{$k}: $(grep -rlF "{$k}" Kapitel | head -1)"; err=1; }
done
for img in $(grep -rhoE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' Kapitel | sed 's/.*{//;s/}//'); do
  [ -f "$img" ] || { echo "BILD FEHLT $img"; err=1; continue; }
  case "$img" in *.png) file -b "$img" | grep -q '^PNG' || { echo "KEIN PNG   $img ($(file -b "$img" | cut -d, -f1))"; err=1; };; esac
done
[ $err = 0 ] && echo "Alles OK."; exit $err
