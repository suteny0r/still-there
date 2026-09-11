#!/usr/bin/env bash
# Export every printable part to hardware/stl and render preview PNGs.
# Usage: ./render.sh [path/to/openscad]
set -e
cd "$(dirname "$0")"
OPENSCAD="${1:-/f/openscad-2021.01/openscad.com}"
mkdir -p stl
for p in base base_lid yoke head head_lid; do
  echo "== $p"
  "$OPENSCAD" -o "stl/$p.stl" -D "part=\"$p\"" turret.scad
done
echo "== previews"
"$OPENSCAD" -o stl/assembly.png --imgsize=1600,1200 --camera=140,-170,150,0,0,60 --projection=p --colorscheme=Tomorrow -D 'part="assembly"' turret.scad
"$OPENSCAD" -o stl/plate.png    --imgsize=1600,1100 --camera=45,-190,280,45,45,0 --projection=o --colorscheme=Tomorrow -D 'part="plate"' turret.scad
echo "done -> stl/"
