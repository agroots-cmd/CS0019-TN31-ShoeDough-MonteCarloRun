# A Simulation on Horse Racing Events: Project Specifications

* **Simulation approach:** Monte Carlo Simulation
* **Implementation:** MATLAB
* **Group roster:** Baldonado, Arthur John F.; Grutas, Aaron Nathaniel L.; Sangil, Justine Fernando C.; Rodriguez, Jhon Marco C.

*Roles below are labeled Member 1 to Member 4 for now. Replace each label with a real name once tasks are assigned.*

---

## 1. Project Overview

This project builds a Monte Carlo simulation of standard horse racing events. Each horse has individual capabilities (speed, stamina, and performance variance), and each race is affected by external factors such as track condition, inclines, and race distance. By running thousands of randomized races, the simulation estimates win probabilities, finish-time distributions, margins of victory, upset rates, and the betting outcomes that follow from them.

### 1.1 Main Question
Which race condition affects a horse's win probability consistency the most, and how do variations in horse attributes and external track environments impact calculated betting outcomes across multiple race scenarios?

### 1.2 Objectives
1. Build a baseline race model that moves each horse forward per time step using its speed and stamina.
2. Implement three track scenarios (Balanced, Mixed, Endurance) with scenario-specific parameters.
3. Run $N$ randomized races per scenario and compute win probabilities, standard deviations, upset rates, and confidence intervals.
4. Visualize results with line graphs, bar charts, and histograms, then compare scenarios.
5. Identify which condition produces the largest change in win-probability consistency, and translate probabilities into betting outcomes.

### 1.3 Scope
* **In scope:** single-race simulation for a fixed field of horses, three scenarios, randomized performance variation, statistical summaries, MATLAB plots, validation tests, and simple betting metrics (implied odds, expected value).
* **Out of scope:** jockey behavior, horse-to-horse collisions or drafting, real historical data fitting, live betting interfaces, and multi-race season tracking.

---

## 2. System Description

A Monte Carlo simulation that models horse races in which each horse's speed, stamina, and variance interact with environmental factors to produce a finish time. Randomness enters each race through a performance noise term, so repeating the race many times reveals the distribution of outcomes instead of one fixed result.

---

## 3. Inputs (Conditions to Change)

| Input | Description | Type / Unit | Example Default |
| :--- | :--- | :--- | :--- |
| **Speed** | Base running speed of each horse | $\text{m/s}$ | $16$ to $18$ |
| **Stamina** | Total stamina pool; drains as the horse runs | arbitrary units | $80$ to $120$ |
| **Performance variance** | Standard deviation of the random per-step performance noise | fraction of speed | $0.02$ to $0.08$ |
| **Track condition** | Dry, muddy/rocky, slippery, and so on; sets speed and drain multipliers | categorical | Per scenario |
| **Race distance** | Total length of the race | meters | $1200$ to $3200$ |
| **Number of simulations ($N$)** | Number of races simulated per scenario | integer | $10,000$ |
| **Number of horses** | Field size | integer | $6$ to $8$ |
| **Time step ($dt$)** | Simulation time resolution | seconds | $0.5$ |

---

## 4. Expected Outputs and Results

| Output | What it shows |
| :--- | :--- |
| **Overall performance** | Combined effect of speed and stamina on results |
| **Performance in longer tracks** | How stamina separates horses as distance grows |
| **Standard deviation of finish times** | Consistency of each horse |
| **Rate of random upsets** | How often the lowest-rated horse wins, or the pre-race favorite loses |
| **Margin of victory** | Gap between 1st and 2nd place (seconds or meters) |
| **Confidence interval** | $95\%$ interval for each win probability |
| **Finish time distribution** | Spread of completion times per horse and per finishing place |
| **Betting outcomes** | Implied fair odds and expected value per horse and scenario |

---

## 5. Scenarios

| Scenario | What changes | Parameter intent |
| :--- | :--- | :--- |
| **Balanced Track** *(balanced track and horses)* | Flat dirt track, standard stamina decay | Baseline: speed multiplier $1.0$, drain multiplier $1.0$, incline $0$ |
| **Mixed Track** *(muddy/rocky)* | Muddy/rocky surface with steep inclines; doubles stamina drain and favors high-endurance runners | Speed multiplier below $1.0$, drain multiplier $2.0$, inclines on selected segments |
| **Endurance Track** *(longer distance)* | Increased race distance that tests the limits of the stamina pool | Distance increased (for example $1.5\times$ to $2\times$ baseline), standard drain |

All scenarios use the same horse field so that differences in results come from the track and not from the horses. Final parameter values are fixed in the scenario assumptions document delivered by Member 2.

---

## 6. Model Specification

### 6.1 State of each horse
For horse $i$ at time step $t$: position $x_i(t)$, remaining stamina $s_i(t)$, and current speed $v_i(t)$.

### 6.2 Update rules (baseline)
1. **Effective speed:**
   $$v_i(t) = v_{\text{base}, i} \times \text{track\_factor} \times \text{incline\_factor}(x) \times \text{stamina\_factor}(s_i) \times (1 + \varepsilon)$$
   where $\varepsilon \sim \mathcal{N}(0, \sigma_i)$ is the random performance variation.
2. **Stamina factor:** Equals $1$ while stamina is above a threshold fraction of its pool, then falls linearly to a minimum floor (for example $0.6$) as stamina reaches $0$.
3. **Stamina drain per step:**
   $$s_i(t + dt) = s_i(t) - k_{\text{drain}} \times \left(\frac{v_i(t)}{v_{\text{base}, i}}\right)^2 \times \text{drain\_multiplier} \times (1 + \text{incline\_cost}(x)) \times dt$$
4. **Position update:**
   $$x_i(t + dt) = x_i(t) + v_i(t) \times dt$$
5. **Finish:** The first time $x_i \ge$ race distance $D$, record finish time by linear interpolation between steps. The race ends when all horses finish (or a time cap is reached).

### 6.3 Assumptions
* Horses do not interact with each other.
* Noise terms are independent across horses and time steps (can be changed to a per-race constant to test other behavior).
* Track conditions are applied uniformly or by defined segments.
* All parameters are documented and justified in the scenario assumptions.

---

## 7. Monte Carlo Procedure and Statistics

**Loop:** For each scenario, run $N$ races. In each race, draw the noise, simulate to the finish, and store finish times and finishing order for every horse.

### Computed statistics
* **Win probability:** $p_i = \frac{\text{wins of horse } i}{N}$
* **Standard error:** $\text{SE} = \sqrt{\frac{p_i(1 - p_i)}{N}}$
* **$95\%$ confidence interval:** $p_i \pm 1.96 \times \text{SE}$
* **Mean and standard deviation** of finish times per horse
* **Upset rate:** Share of races won by a horse that was not the favorite (the horse with the highest $p_i$ in the Balanced scenario, or the fastest base speed)
* **Margin of victory:** Mean and distribution of $(\text{2nd finish time} - \text{1st finish time})$
* **Consistency measure:** Variability of win probability and finish time (standard deviation or coefficient of variation) across scenarios, used to answer the main question

### Betting metrics
* **Fair decimal odds:** $\frac{1}{p_i}$
* **Expected value** of a $1$-unit bet at posted odds $O$: $\text{EV} = p_i \times O - 1$
* Compare $\text{EV}$ across scenarios to show how track conditions change betting outcomes

**Reproducibility:** Set a fixed random seed (`rng`) so results can be repeated, and confirm that results stabilize as $N$ increases.

---

## 8. Planned MATLAB Output

1. **Line graph:** Dynamic speed and stamina profiles of each horse over the total race distance.
2. **Bar chart:** Win probability per horse across the different scenarios (with confidence-interval error bars).
3. **Histogram:** Frequency distribution of total completion times for the top contenders (1st, 2nd, 3rd).
4. **Tables:** Scenario comparison table (win probability, mean finish time, standard deviation, upset rate, margin of victory, confidence interval, $\text{EV}$).

---

## 9. Task Delegation

| Member | Main Responsibility | Specific Tasks | Deliverables |
| :--- | :--- | :--- | :--- |
| **Member 1** | Horse and race model | Define horse attributes, speed, stamina, race distance, movement per time step, and finish-time calculations. Create the baseline race model. | Horse parameter file, baseline simulation function, explanation of race mechanics |
| **Member 2** | Track conditions and scenarios | Implement balanced, muddy/rocky, and endurance tracks. Model stamina drain, inclines, terrain effects, and scenario-specific parameters. | Track-condition functions, three scenario configurations, scenario assumptions |
| **Member 3** | Monte Carlo simulation and statistics | Run repeated race simulations, randomize performance variation, calculate win probabilities, upset rates, standard deviation, and confidence intervals. | Monte Carlo loop, statistical calculations, numerical results table |
| **Member 4** | MATLAB outputs and validation | Create line graphs, bar charts, and histograms. Compare all scenarios, check results for errors, and organize the final MATLAB program. | Figures, comparison tables, validation tests, final integrated MATLAB files |

### 9.1 Dependencies and Handoffs
* **Member 1** delivers the baseline race function and horse parameter file first; Members 2 and 3 both build on it.
* **Member 2** supplies track functions and scenario structs that plug into Member 1's step update.
* **Member 3** calls the race function with each scenario configuration and returns a results struct.
* **Member 4** consumes the results struct for plotting and validation, and integrates all files into one runnable program.

---

## 10. Suggested MATLAB File Structure

| File | Owner | Purpose |
| :--- | :--- | :--- |
| `horse_params.m` | Member 1 | Defines horse speed, stamina, and variance values |
| `simulate_race.m` | Member 1 | Runs one race and returns finish times, order, and profiles |
| `track_conditions.m` | Member 2 | Returns speed, drain, and incline modifiers for a track |
| `scenario_config.m` | Member 2 | Defines Balanced, Mixed, and Endurance configurations |
| `run_monte_carlo.m` | Member 3 | Loops $N$ races per scenario and stores results |
| `compute_stats.m` | Member 3 | Win probabilities, upset rate, standard deviation, confidence intervals |
| `plot_results.m` | Member 4 | Line graphs, bar charts, histograms |
| `validate_model.m` | Member 4 | Sanity and validation tests |
| `main.m` | Member 4 | Runs the whole program end to end |

---

## 11. Validation Plan

* **Determinism check:** With variance set to $0$, the fastest horse should always win and results should repeat exactly.
* **Symmetry check:** Two identical horses should each win about $50\%$ of the time (within their confidence interval).
* **Monotonic checks:** Higher speed should raise win probability; higher stamina should help more in the Endurance and Mixed scenarios.
* **Bounds check:** Win probabilities across all horses must sum to $1$, and no position may exceed the race distance at finish.
* **Convergence check:** Win probabilities should stabilize as $N$ grows (for example $1,000$ vs. $10,000$ vs. $100,000$).
* **Scenario check:** Doubling drain in the Mixed scenario should visibly shift results toward high-stamina horses.

---

## 12. Final Deliverables

1. Integrated MATLAB program (all files above) that runs with one command.
2. **Figures:** Dynamic profile line graph, win-probability bar chart, finish-time histograms.
3. Scenario comparison table with all computed statistics and betting metrics.
4. Written answer to the main question, supported by the results.
5. Explanation of race mechanics and scenario assumptions.