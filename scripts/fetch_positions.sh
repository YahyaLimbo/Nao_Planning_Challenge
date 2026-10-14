set -euo pipefail
cd "$(dirname "$0")/.."

REPO="ProjectsAI/NAO_Planning_Challenge"
BRANCH="master"
DEST="positions"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}/RobotPositions"

mkdir -p "${DEST}/cgrFiles"

files=(
  "1-Rotation_handgun_object.py" "2-Right_arm.py" "3-Double_movement.py"
  "4-Arms_opening.py" "5-Union_arms.py" "6-Crouch.py" "7-Move_forward.py"
  "8-Move_backward.py" "9-Diagonal_left.py" "10-Diagonal_right.py"
  "11-Stand.py" "12-Rotation_foot_RLeg.py" "13-Rotation_foot_LLeg.py"
  "14-StandInit.py" "15-StandZero.py" "16-Sit.py" "17-SitRelax.py"
)
crg=(
  "birthday_dance_no_sound.crg" "sing_with_me.crg" "sprinkler.crg" "workout.crg"
)

for f in "${files[@]}"; do
    echo "==> ${f}"
    curl -fsSL "${RAW}/${f}" | tr '\r' '\n' > "${DEST}/${f}"
done

for f in "${crg[@]}"; do
    echo "==> cgrFiles/${f}"
    curl -fsSL "${RAW}/cgrFiles/${f}" -o "${DEST}/cgrFiles/${f}"
done

echo
echo "${#files[@]} position scripts + ${#crg[@]} .crg files in ./${DEST}"
echo "The .crg files are Choregraphe projects: import them in Choregraphe, they"
echo "are not runnable Python."
