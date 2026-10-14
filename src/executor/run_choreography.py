import argparse
import imp
import json
import os
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CATALOGUE = os.path.join(ROOT, "choreography", "positions.json")


def load_json(path):
    f = open(path)
    try:
        return json.load(f)
    finally:
        f.close()


def run_script(path, ip, port):
    full = os.path.join(ROOT, path)
    if not os.path.exists(full):
        raise IOError("%s not found - run scripts/fetch_positions.sh" % path)
    name = "pos_" + os.path.basename(full).replace("-", "_").replace(".py", "")
    module = imp.load_source(name, full)
    if not hasattr(module, "main"):
        raise AttributeError("%s has no main(robotIP, port)" % path)
    module.main(ip, port)


def run_animation(animation, ip, port):
    from naoqi import ALProxy
    player = ALProxy("ALAnimationPlayer", ip, port)
    player.run(animation)


def execute(plan, catalogue, ip, port, dry_run):
    positions = catalogue["positions"]
    timings = []
    total = 0.0
    failures = 0

    for i, step in enumerate(plan.get("steps", []), 1):
        key = step["position"]
        if key not in positions:
            print "[%02d] %-24s SKIP (not in catalogue)" % (i, key)
            continue
        spec = positions[key]
        kind = spec.get("kind")

        print "[%02d] %-24s (%s)" % (i, key, kind),
        sys.stdout.flush()

        if dry_run:
            est = float(spec.get("duration_s", 0))
            total += est
            print "dry-run, est %.1fs" % est
            continue

        started = time.time()
        try:
            if kind in ("posture", "motion"):
                run_script(spec["script"], ip, port)
            elif kind == "animation":
                run_animation(spec["animation"], ip, port)
            elif kind == "crg":
                print "skipped: .crg is a Choregraphe project, not a script"
                continue
            else:
                print "skipped: unknown kind %r" % kind
                continue
        except Exception, e:
            print "FAILED: %s: %s" % (type(e).__name__, e)
            failures += 1
            continue
        elapsed = time.time() - started
        total += elapsed
        timings.append({"position": key, "duration_s": round(elapsed, 2)})
        print "%.1fs" % elapsed

    limit = catalogue.get("max_total_duration_s", 120)
    print
    print "total: %.1fs / %ds limit %s" % (
        total, limit, "OK" if total <= limit else "** OVER **")
    if failures:
        print "%d move(s) failed" % failures
    return (1 if failures else 0), timings


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("plan", help="plan JSON produced by the planner")
    ap.add_argument("--ip", default=os.environ.get("NAO_IP", "127.0.0.1"))
    ap.add_argument("--port", type=int, default=int(os.environ.get("NAO_PORT", "9559")))
    ap.add_argument("--dry-run", action="store_true",
                    help="no robot needed: validate the plan and sum the estimates")
    ap.add_argument("--timings", metavar="FILE",
                    help="write measured per-step durations here (use them to "
                         "replace the placeholders in positions.json)")
    args = ap.parse_args()

    catalogue = load_json(CATALOGUE)
    plan = load_json(args.plan)

    print "plan   : %s (%s)" % (plan.get("name", "unnamed"), args.plan)
    if not args.dry_run:
        print "target : %s:%d" % (args.ip, args.port)
    print

    rc, timings = execute(plan, catalogue, args.ip, args.port, args.dry_run)

    if args.timings and timings:
        out = os.path.join(ROOT, args.timings) if not os.path.isabs(args.timings) else args.timings
        d = os.path.dirname(out)
        if d and not os.path.isdir(d):
            os.makedirs(d)
        f = open(out, "w")
        try:
            json.dump(timings, f, indent=2)
        finally:
            f.close()
        print "timings -> %s" % args.timings
    return rc


if __name__ == "__main__":
    sys.exit(main())
