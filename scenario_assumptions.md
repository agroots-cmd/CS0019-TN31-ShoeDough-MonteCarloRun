# Scenario Assumptions — Member 2 (Track Conditions and Scenarios)

This document fixes the parameter values used by `scenario_config.m` and
`track_conditions.m`, as required by spec Sections 5 and 9. All three
scenarios reuse the same horse field from `horse_params.m`, so differences
in results come from the track, not the horses.

## 1. Interface with `simulate_race.m` (Member 1)

The simulator reads `scenario.distance`, `scenario.track_factor`, and
`scenario.drain_multiplier` directly, and calls
`[incline_factor, incline_cost] = track_conditions(pos, scenario)` once per
horse per time step. The outputs enter the model exactly as in spec 6.2:

- Effective speed: `v = v_base * track_factor * incline_factor * stamina_factor * (1 + eps)`
- Drain per step: `drain = k_drain * (v/v_base)^2 * drain_multiplier * (1 + incline_cost) * dt`

So `track_factor` and `drain_multiplier` are **uniform** (apply everywhere),
while `incline_factor` and `incline_cost` are **position-dependent** and come
from the segment table described below.

## 2. Incline model

Each scenario may carry an `inclines` matrix — one row per segment as
`[start_m, end_m, grade]`, where `grade` is rise over run (0.08 = an 8%
climb). A position outside every segment gets flat defaults
(`incline_factor = 1.0`, `incline_cost = 0.0`).

Grade is converted to the two modifiers with fixed coefficients:

| Direction | `incline_factor` | `incline_cost` | Rationale |
| :--- | :--- | :--- | :--- |
| Uphill (`g > 0`) | `1 - 1.5·g` | `3.0·g` | Climbing trades speed for effort; drain rises faster than speed falls |
| Downhill (`g < 0`) | `1 + 0.8·|g|`, capped at `1.10` | `0.5·|g|` | Descents give a modest speed gain but still cost stamina on bad footing |

Justification for coefficients:

- **Uphill speed penalty (1.5):** an 8–10% grade cuts effective speed by
  12–15%. Real runners/horses lose more speed uphill than they regain
  downhill, so the uphill coefficient is deliberately larger.
- **Uphill drain cost (3.0):** climbing is where stamina separates horses;
  combined with the Mixed scenario's `drain_multiplier = 2.0`, a 10% climb
  multiplies drain by `2.0 × 1.30 = 2.6` — enough to visibly shift wins
  toward high-stamina horses (spec Section 11 scenario check).
- **Downhill gain (0.8, capped 1.10):** horses do not fully exploit
  descents; the cap prevents unrealistic speed spikes.
- **Downhill cost (0.5):** descending muddy/rocky ground is still tiring
  (footing, braking), so drain does not drop below flat rates.
- **Floor (`incline_factor ≥ 0.5`):** safety bound against pathological
  segment definitions; `simulate_race` also clamps `v ≥ 1.0`.

## 3. Scenario parameters

| Parameter | Balanced | Mixed | Endurance |
| :--- | :--- | :--- | :--- |
| `distance` | 1600 m | 1600 m | 2800 m |
| `track_factor` | 1.0 | 0.90 | 1.0 |
| `drain_multiplier` | 1.0 | 2.0 | 1.0 |
| `inclines` | none | see below | none |
| Surface | flat dirt | muddy/rocky + inclines | flat dirt, extended |

**Balanced** is the baseline: every multiplier is 1.0 and the track is flat,
so results reflect horse attributes only. Distance 1600 m matches the
default in `simulate_race.m` and sits inside the spec's 1200–3200 m range.

**Mixed** keeps the same 1600 m distance so any result shift is attributable
to terrain, not distance. `track_factor = 0.90` models mud slowing all
horses uniformly; `drain_multiplier = 2.0` is the spec-mandated doubling.
Incline segments:

| Segment | Position | Grade | Effect |
| :--- | :--- | :--- | :--- |
| Early climb | 300–600 m | +8% | `incline_factor = 0.88`, drain ×2.48 with multiplier |
| Mid descent | 800–1000 m | −5% | `incline_factor = 1.04`, drain ×2.05 with multiplier |
| Late climb | 1200–1500 m | +10% | `incline_factor = 0.85`, drain ×2.6 with multiplier |

Flat muddy stretches remain at 0–300, 600–800, 1000–1200, and 1500–1600 m,
so the last 100 m is a flat sprint after the decisive late climb.

**Endurance** extends the distance to 2800 m (1.75× baseline, inside the
spec's 1.5–2× band) with otherwise standard parameters. Drain outpaces the
80–120 stamina pool well before the finish, so low-stamina horses spend a
long closing stretch at the `stamina_floor` speed while high-stamina horses
hold pace — this is what makes stamina the deciding factor.

## 4. Notes for Members 3 and 4

- `scenario_config()` returns the scenarios as a struct array; loop with
  `for s = 1:numel(scenarios)`.
- Expected behavior for validation (spec Section 11): the Mixed scenario
  should shift win probability toward high-stamina horses, the Endurance
  scenario should amplify it further, and Balanced should track raw speed.
- `track_conditions` is called `num_horses × num_steps` times per race; it
  is intentionally a short loop over a small segment table.
