set -euo pipefail
cd "$(dirname "$0")/.."

PY3="${PY3:-python3}"
VENV="${VENV:-.venv}"

if ! "${PY3}" -c "import ensurepip" 2>/dev/null; then
    ver="$("${PY3}" -c 'import sys;print("%d.%d"%sys.version_info[:2])')"
    cat >&2 <<MSG
!! ${PY3} cannot create venvs: the stdlib ensurepip module is missing.
   On Debian/Ubuntu that module is split into a separate package:

       sudo apt install python${ver}-venv

   Then re-run this script. (Or skip the venv entirely - the planner only
   needs the stdlib unless you uncomment the optional planner libraries.)
MSG
    exit 1
fi

echo "==> planner venv (${PY3})"
"${PY3}" -m venv "${VENV}"
"${VENV}/bin/pip" install --quiet --upgrade pip
"${VENV}/bin/pip" install --quiet -r requirements-planner.txt
echo "    $("${VENV}/bin/python" --version 2>&1) in ${VENV}"
grep -vE '^\s*(#|$)' requirements-planner.txt | sed 's/^/    + /'

echo
echo "==> executor (Python 2.7 + NAOqi)"
if command -v python2.7 >/dev/null 2>&1; then
    echo "    python2.7 found: $(command -v python2.7)"
else
    cat <<'MSG'
    python2.7 NOT found on this machine.
    The NAOqi Python SDK is a Python 2.7 binary tarball - it is not on PyPI and
    a venv cannot conjure a 2.7 interpreter. Options:
      - install python2.7 from your distro (32-bit if your SDK is linux32), or
      - use the Docker path instead: ./scripts/build.sh   (see README)
MSG
fi

cat <<'MSG'

    Then point PYTHONPATH at the extracted SDK, per the install guide
    (http://doc.aldebaran.com/2-1/dev/python/install_guide.html):

      cp scripts/env.example.sh scripts/env.sh   
      source scripts/env.sh

Usage without Docker:
    source .venv/bin/activate
    PYTHONPATH=src python -m planner.plan --validate choreography/plan.example.json
    PYTHONPATH=src python -m planner.plan -o choreography/out/plan.json
    deactivate
    source scripts/env.sh
    python2.7 src/executor/run_choreography.py choreography/out/plan.json
MSG
