"""Build the Flash Studio (Orca-Flashforge) project turret_creator5pro.3mf from stl/*.stl.

Steps:
  1. flatten the preset inheritance chains (machine / process / filament) into single JSON
     files with a "type" field, which is what the slicer CLI accepts;
  2. run `flash studio.exe --export-3mf` with those presets and the five STLs;
  3. rewrite the build-item transforms for a fixed, unrotated layout on the 256 x 256 bed
     and set the bed type (PETG profiles have cool_plate_temp = 0).

Usage:  python make_project.py [--slice]
        --slice additionally slices the result to report time / weight and slicing warnings.
Run render.ps1 / render.sh first so stl/ is current.
"""
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
STL = os.path.join(HERE, "stl")
OUT = os.path.join(HERE, "turret_creator5pro.3mf")
EXE = r"C:\Program Files\Flashforge\Flash Studio Desktop\flash studio.exe"
PROFILES = r"C:\Program Files\Flashforge\Flash Studio Desktop\resources\profiles"
USER_DIR = os.path.join(os.environ.get("APPDATA", ""), "Orca-Flashforge", "user")

MACHINE = "Flashforge Creator 5 Pro 0.4 nozzle"
PROCESS = "0.20mm Standard @FF C5"              # stock Flashforge preset for the Creator 5 / 5 Pro 0.4
FILAMENT = "Flashforge PETG Basic @FF C5P"
BED_TYPE = "High Temp Plate"

PARTS = ["base", "base_lid", "yoke", "head", "head_lid"]
# XY centers on the bed. Footprints in print orientation: base d78, base_lid d71,
# yoke 56x56, head ~36x29 (laser saddle adds 6.5), head_lid 29x29.
PLACE = {"base": (52, 52), "base_lid": (52, 150), "yoke": (150, 46), "head": (150, 140), "head_lid": (215, 140)}


def index_presets():
    idx = {}
    for root in (PROFILES, USER_DIR):
        for f in glob.glob(os.path.join(root, "**", "*.json"), recursive=True):
            try:
                d = json.load(open(f, encoding="utf-8"))
            except Exception:
                continue
            if isinstance(d, dict) and "name" in d:
                idx.setdefault(d["name"], f)
    return idx


def flatten(idx, name):
    d = json.load(open(idx[name], encoding="utf-8"))
    parent = d.get("inherits")
    if parent:
        base = flatten(idx, parent)
        base.update({k: v for k, v in d.items() if k != "inherits"})
        return base
    return d


def write_preset(idx, name, typ, path):
    d = flatten(idx, name)
    d["type"] = typ
    d["name"] = name
    if typ == "process":
        d["curr_bed_type"] = BED_TYPE      # PETG profiles have cool_plate_temp = 0
    d.pop("inherits", None)
    d.pop("instantiation", None)
    json.dump(d, open(path, "w", encoding="utf-8"), indent=1)


def run(args):
    p = subprocess.run([EXE, "--debug", "2"] + args, capture_output=True, text=True, errors="replace")
    log = p.stdout + p.stderr
    bad = [l for l in log.splitlines() if re.search(r"\[error\]|\[warning\] plate", l)
           and not re.search(r"OpenGL|GLFW|GLAD|thumbnail|NozzleVolumeType", l)]
    return p.returncode, bad, log


def main():
    idx = index_presets()
    process = PROCESS
    tmp = tempfile.mkdtemp(prefix="turret3mf_")
    m, pr, fi = (os.path.join(tmp, n) for n in ("machine.json", "process.json", "filament.json"))
    write_preset(idx, MACHINE, "machine", m)
    write_preset(idx, process, "process", pr)
    write_preset(idx, FILAMENT, "filament", fi)

    raw = os.path.join(tmp, "raw.3mf")
    stls = [os.path.join(STL, p + ".stl") for p in PARTS]
    rc, bad, log = run(["--load-settings", f"{m};{pr}", "--load-filaments", fi, "--arrange", "1",
                        "--export-3mf", raw] + stls)
    if rc != 0 or not os.path.exists(raw):
        print(log)
        sys.exit("export failed")

    zin = zipfile.ZipFile(raw)
    ms = zin.read("Metadata/model_settings.config").decode()
    id2name = dict(re.findall(r'<object id="(\d+)">\s*<metadata key="name" value="([^"]+)"', ms))
    model = zin.read("3D/3dmodel.model").decode()

    def fix(mt):
        part = id2name[mt.group(1)].replace(".stl", "")
        x, y = PLACE[part]
        return mt.group(0).replace(mt.group(2), f"1 0 0 0 1 0 0 0 1 {x} {y} 0")

    model = re.sub(r'<item objectid="(\d+)"[^>]*transform="([^"]+)"', fix, model)
    ps = json.loads(zin.read("Metadata/project_settings.config").decode())
    ps["curr_bed_type"] = BED_TYPE
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            data = zin.read(it.filename)
            if it.filename == "3D/3dmodel.model":
                data = model.encode()
            elif it.filename == "Metadata/project_settings.config":
                data = json.dumps(ps, indent=4).encode()
            zout.writestr(it, data)
    print(f"wrote {OUT}  ({os.path.getsize(OUT)} bytes)  printer={MACHINE}  process={process}  filament={FILAMENT}")

    if "--slice" in sys.argv:
        sliced = os.path.join(tmp, "sliced.3mf")
        rc, bad, log = run(["--slice", "0", "--export-3mf", sliced, OUT])
        if rc != 0 or not os.path.exists(sliced):
            print(log)
            sys.exit("slice failed")
        info = zipfile.ZipFile(sliced).read("Metadata/slice_info.config").decode()
        pred = dict(re.findall(r'<metadata key="(prediction|weight|outside|support_used)" value="([^"]*)"', info))
        secs = int(pred.get("prediction", 0))
        print(f"slice ok: {secs // 3600}h{(secs % 3600) // 60:02d}m, {pred.get('weight')} g, outside={pred.get('outside')}, support={pred.get('support_used')}")
        for l in bad:
            print("  ", l)


if __name__ == "__main__":
    main()
