from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE_PATH = ROOT / "choreography" / "positions.json"

@dataclass(frozen=True)
class Position:
    name: str
    kind: str
    duration_s: float
    start_posture: str
    end_posture: str
    intermediate: bool = False
    script: str | None = None
    animation: str | None = None
    crg: str | None = None
    note: str | None = None

    @property
    def runnable(self) -> bool:
        return self.kind in {"posture", "motion", "animation"}


@dataclass
class Catalogue:
    positions: dict[str, Position]
    initial: str
    goal: str
    mandatory: list[str]
    min_intermediate: int
    max_duration_s: float
    mandatory_order_matters: bool = False
    _raw: dict = field(repr=False, default_factory=dict)

    @classmethod
    def load(cls, path: Path | str = CATALOGUE_PATH) -> "Catalogue":
        raw = json.loads(Path(path).read_text())
        positions = {
            name: Position(
                name=name,
                kind=spec.get("kind", "motion"),
                duration_s=float(spec.get("duration_s", 0)),
                start_posture=spec.get("start_posture", "any"),
                end_posture=spec.get("end_posture", "any"),
                intermediate=bool(spec.get("intermediate", False)),
                script=spec.get("script"),
                animation=spec.get("animation"),
                crg=spec.get("crg"),
                note=spec.get("note"),
            )
            for name, spec in raw["positions"].items()
        }
        return cls(
            positions=positions,
            initial=raw["initial_position"],
            goal=raw["goal_position"],
            mandatory=list(raw["mandatory_positions"]),
            min_intermediate=int(raw["min_intermediate_positions"]),
            max_duration_s=float(raw["max_total_duration_s"]),
            mandatory_order_matters=bool(raw.get("mandatory_order_matters", False)),
            _raw=raw,
        )

    @property
    def intermediates(self) -> list[Position]:
        return [p for p in self.positions.values() if p.intermediate]

    def duration(self, sequence: list[str]) -> float:
        return sum(self.positions[n].duration_s for n in sequence if n in self.positions)

    def transition_ok(self, a: str, b: str) -> bool:
        end = self.positions[a].end_posture
        start = self.positions[b].start_posture
        return "any" in (end, start) or end == start

    def check(self, sequence: list[str]) -> list[str]:
        errors: list[str] = []

        unknown = [n for n in sequence if n not in self.positions]
        if unknown:
            return [f"unknown position(s): {', '.join(unknown)}"]

        if not sequence or sequence[0] != self.initial:
            errors.append(f"must start from {self.initial}")
        if not sequence or sequence[-1] != self.goal:
            errors.append(f"must end in {self.goal}")

        missing = [m for m in self.mandatory if m not in sequence]
        if missing:
            errors.append(f"missing mandatory position(s): {', '.join(missing)}")

        if self.mandatory_order_matters:
            order = [sequence.index(m) for m in self.mandatory if m in sequence]
            if order != sorted(order):
                errors.append(
                    "mandatory positions are not in the order listed in "
                    "positions.json"
                )

        used = {n for n in sequence if self.positions[n].intermediate}
        if len(used) < self.min_intermediate:
            errors.append(
                f"only {len(used)} distinct intermediate position(s), "
                f"at least {self.min_intermediate} required"
            )

        for a, b in zip(sequence, sequence[1:]):
            if not self.transition_ok(a, b):
                errors.append(
                    f"illegal transition {a} ({self.positions[a].end_posture}) "
                    f"-> {b} (needs {self.positions[b].start_posture})"
                )

        not_runnable = sorted({n for n in sequence if not self.positions[n].runnable})
        if not_runnable:
            errors.append(
                f"not replayable by the executor (Choregraphe-only): {', '.join(not_runnable)}"
            )

        total = self.duration(sequence)
        if total > self.max_duration_s:
            errors.append(f"too long: {total:.0f}s > {self.max_duration_s:.0f}s")

        return errors
