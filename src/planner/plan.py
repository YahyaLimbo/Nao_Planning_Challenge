from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path

from planner.catalogue import ROOT, Catalogue

def plan(catalogue: Catalogue, seed: int | None = None) -> list[str]:
    raise NotImplementedError(
        ""
    )

def _report(catalogue: Catalogue, sequence: list[str]) -> int:
    errors = catalogue.check(sequence)
    width = max(len(n) for n in sequence) if sequence else 10
    for i, name in enumerate(sequence, 1):
        p = catalogue.positions[name]
        tag = "mandatory" if name in catalogue.mandatory else (
            "intermediate" if p.intermediate else "")
        print(f"  {i:2d}. {name:<{width}}  {p.duration_s:5.1f}s  {tag}")
    print(f"\n  total {catalogue.duration(sequence):.0f}s "
          f"/ {catalogue.max_duration_s:.0f}s limit")
    distinct = len({n for n in sequence if catalogue.positions[n].intermediate})
    print(f"  distinct intermediate positions: {distinct} "
          f"(min {catalogue.min_intermediate})")
    if errors:
        print("\n  INVALID:")
        for e in errors:
            print(f"    - {e}")
        return 1
    print("\n  valid")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--validate", metavar="PLAN.json",
                    help="check an existing plan instead of generating one")
    ap.add_argument("-o", "--out", metavar="PLAN.json",
                    help="where to write the generated plan")
    ap.add_argument("--name", default="algorithm-A plan")
    ap.add_argument("--seed", type=int)
    args = ap.parse_args(argv)

    catalogue = Catalogue.load()

    if args.validate:
        data = json.loads(Path(args.validate).read_text())
        sequence = [s["position"] for s in data["steps"]]
        print(f"{args.validate}: {data.get('name', 'unnamed')}\n")
        return _report(catalogue, sequence)

    sequence = plan(catalogue, seed=args.seed)
    print(f"{args.name}\n")
    rc = _report(catalogue, sequence)

    if args.out:
        out = Path(args.out)
        if not out.is_absolute():
            out = ROOT / out
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(
            {"name": args.name, "steps": [{"position": n} for n in sequence]},
            indent=2) + "\n")
        print(f"\n  -> {args.out}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
