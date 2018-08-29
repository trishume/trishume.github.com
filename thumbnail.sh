#!/bin/sh
# find assets/itempics/fullsize -type f -iname \*.jpg -exec convert {} -thumbnail 200 \
# -set filename:name '%t' 'assets/itempics/thumbs/%[filename:name]_200px.jpg' \;

cd assets/itempics/fullsize
for i in *; do
  if [ ! -f ../thumbs/$i ]; then
    sips --resampleWidth 200 $i --out ../thumbs/$i
    open -a ImageOptim ../thumbs/$i
  fi
done
