# A Simulation on Horse Racing Events

**CS0019-TN31 — ShoeDough — Monte Carlo Simulation in MATLAB**

A Monte Carlo simulation of standard horse racing events. Each horse has
individual capabilities (speed, stamina, performance variance), and each
race is affected by track condition, inclines, and race distance. Running
thousands of randomized races estimates win probabilities, finish-time
distributions, margins of victory, upset rates, and betting outcomes.

See [`project_specifications.md`](project_specifications.md) for the full
spec and [`scenario_assumptions.md`](scenario_assumptions.md) for the
track/scenario parameter rationale.

## Group Roster

- Baldonado, Arthur John F.
- Grutas, Aaron Nathaniel L.
- Sangil, Justine Fernando C.
- Rodriguez, Jhon Marco C.

## Scenarios

| Scenario | Distance | Surface | Speed factor | Drain factor |
| :--- | :--- | :--- | :--- | :--- |
| Balanced | 1600 m | flat dirt | 1.0 | 1.0 |
| Mixed | 1600 m | muddy/rocky + graded inclines | 0.90 | 2.0 |
| Endurance | 2800 m | flat dirt, extended | 1.0 | 1.0 |

All scenarios run the same horse field so differences come from the track.

## File Structure

| File | Owner | Purpose | Status |
| :--- | :--- | :--- | :--- |
| `horse_params.m` | Member 1 | Randomized horse speed, stamina, drain, variance | Done |
| `simulate_race.m` | Member 1 | One race: per-step speed, stamina drain, finish times | Done |
| `track_conditions.m` | Member 2 | Position-dependent incline speed/drain modifiers | Done |
| `scenario_config.m` | Member 2 | Balanced / Mixed / Endurance scenario structs | Done |
| `run_monte_carlo.m` | Member 3 | N races per scenario, stores results | Pending |
| `compute_stats.m` | Member 3 | Win probs, upset rate, std dev, confidence intervals | Pending |
| `plot_results.m` | Member 4 | Line graphs, bar charts, histograms | Pending |
| `validate_model.m` | Member 4 | Sanity and validation tests | Pending |
| `main.m` | Member 4 | End-to-end runner | Pending |

## Usage

```matlab
horses    = horse_params(6);            % generate the field
scenarios = scenario_config();          % 3 scenario structs
result    = simulate_race(horses, scenarios(2));   % one Mixed race

disp(result.standings);                 % finishing order table
disp(result.winner_name);               % race winner
```

`simulate_race(horses)` with no scenario runs the built-in Balanced
default. `result` also carries `time`, `position`, `speed`, and `stamina`
histories for the profile line graphs.
