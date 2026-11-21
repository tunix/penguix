#!/usr/bin/env python3
"""Compare the live dconf user database against TRUE schema defaults.

dconf only stores explicitly-set keys, and `gsettings get` returns the
effective value (user db wins) — so to see the real default we point gsettings
at an EMPTY dconf profile (fresh XDG_CONFIG_HOME): every read then falls back
to the compiled schema default.

Output buckets:
  SAME-AS-DEFAULT  — user db value equals the schema default; safe to
                     `dconf reset` (the repo also shouldn't carry it)
  DIFFERS          — real customization; keep
  UNKNOWN          — no schema found locally (extension/app schemas); the
                     script cannot judge these

Read-only: nothing is reset automatically. The reset commands are printed.
"""

import os
import re
import subprocess
import sys
import tempfile

SPLIT_DIRS = {
    "org/gnome/shell/extensions/": "extensions.ini",
    "org/gnome/desktop/app-folders": "shell.ini",
    "org/gnome/shell": "shell.ini",
    "org/gnome/Ptyxis": "apps.ini",
    "io/github/": "apps.ini",
    "org/fedoraproject/": "apps.ini",
}


# dconf path -> schema id for schemas whose id differs from the path
# (gsettings needs the CamelCase id, not the path-derived dotted form)
SCHEMA_ALIASES = {
    "org/gtk/settings/file-chooser": "org.gtk.Settings.FileChooser",
    "org/gtk/gtk4/settings/file-chooser": "org.gtk.gtk4.Settings.FileChooser",
}


def run(cmd, env=None, timeout=10):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=env)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def norm(v: str) -> str:
    return re.sub(r"^(?:@[a-zA-Z0-9_\{\}\[\]\(\)]+\s+)+", "", v.strip())


def parse_dump(text):
    sections, cur = [], None
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.startswith("[") and s.endswith("]"):
            cur = (s[1:-1], {})
            sections.append(cur)
        elif "=" in s and cur:
            k, _, v = s.partition("=")
            cur[1][k.strip()] = v.strip()
    return sections


def file_for(path: str) -> str:
    for prefix, fname in sorted(SPLIT_DIRS.items(), key=lambda kv: -len(kv[0])):
        if path.startswith(prefix) or path == prefix.rstrip("/"):
            return fname
    return "desktop.ini"


def main() -> int:
    live_dump = run(["dconf", "dump", "/"])
    if live_dump is None:
        print("ERROR: dconf dump failed", file=sys.stderr)
        return 1

    # Empty-profile environment: every gsettings read returns the schema default.
    empty_xdg = tempfile.mkdtemp(prefix="dconf-defaults-")
    env = dict(os.environ, XDG_CONFIG_HOME=empty_xdg)

    schemas = set((run(["gsettings", "list-schemas"], env=env) or "").split())

    same, differs, unknown = [], [], []
    for path, keys in parse_dump(live_dump):
        dotted = SCHEMA_ALIASES.get(path) or path.replace("/", ".")
        sp = path.strip("/").split("/")
        # exact schema, or longest relocatable prefix + full path
        schema = relpath = None
        if dotted in schemas:
            schema, relpath = dotted, None
        else:
            for cut in range(len(sp) - 1, 0, -1):
                cand = ".".join(sp[:cut])
                if cand in schemas:
                    schema, relpath = cand, "/" + path.strip("/") + "/"
                    break
        for key, value in keys.items():
            fq = f"{path} {key}"
            if schema is None:
                unknown.append(fq)
                continue
            args = ["gsettings", "get", f"{schema}:{relpath}", key] if relpath else ["gsettings", "get", schema, key]
            default = run(args, env=env)
            if default is None:
                unknown.append(fq + " [key not in schema]")
            elif norm(default) == norm(value):
                same.append((fq, f"dconf reset /{path.strip('/')}/{key}"))
            else:
                differs.append(fq)

    def bucket(title, items):
        print(f"\n== {title} ({len(items)})")
        for it in items:
            print("  ", it[0] if isinstance(it, tuple) else it)

    by_file = {}
    for fq, cmd in same:
        by_file.setdefault(file_for(fq.split(" ")[0]), []).append((fq, cmd))
    print("== SAME-AS-DEFAULT — safe to reset (per repo file):")
    for fname in sorted(by_file):
        print(f"  [{fname}]")
        for fq, cmd in by_file[fname]:
            print(f"    {fq}\n        -> {cmd}")
    bucket("DIFFERS — real customization, keep", differs)
    bucket("UNKNOWN — no local schema (extensions/apps), cannot judge", unknown)
    return 0


if __name__ == "__main__":
    sys.exit(main())
