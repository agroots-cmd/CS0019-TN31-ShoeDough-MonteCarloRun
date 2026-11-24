function [incline_factor, incline_cost] = track_conditions(pos, scenario)
%TRACK_CONDITIONS Position-dependent track modifiers for one horse.
%   Member 2 deliverable (spec Sections 5, 6.2, 10). simulate_race.m calls
%   this once per horse per time step and applies the outputs as:
%       v_i   = v_base * track_factor * incline_factor * stamina_factor * (1+eps)
%       drain = k_drain * (v_i/v_base)^2 * drain_multiplier * (1 + incline_cost) * dt
%
%   The scenario struct carries an 'inclines' matrix of track segments,
%   [start_m, end_m, grade] per row (grade = rise/run; + uphill,
%   - downhill). Positions not covered by any segment use flat-ground
%   defaults (factor 1.0, cost 0.0). If the scenario has no 'inclines'
%   field, the track is treated as flat.
%
%   Grade-to-modifier conversion (justified in scenario_assumptions.md):
%     uphill   (g > 0): incline_factor = 1 - 1.5*g
%                       incline_cost   = 3.0*g
%     downhill  (g < 0): incline_factor = 1 + 0.8*|g|, capped at 1.10
%                       incline_cost   = 0.5*|g|

    % Calibration constants (see scenario_assumptions.md)
    K_UP_SPEED    = 1.5;   % speed loss per unit uphill grade
    K_DOWN_SPEED  = 0.8;   % speed gain per unit downhill grade
    K_UP_DRAIN    = 3.0;   % extra drain per unit uphill grade
    K_DOWN_DRAIN  = 0.5;   % extra drain per unit downhill grade (footing)
    MAX_DOWN_GAIN = 1.10;  % cap on downhill speed boost
    MIN_FACTOR    = 0.5;   % safety floor on incline_factor

    incline_factor = 1.0;
    incline_cost = 0.0;

    if ~isfield(scenario, 'inclines') || isempty(scenario.inclines)
        return;
    end

    segs = scenario.inclines;
    for k = 1:size(segs, 1)
        if pos >= segs(k, 1) && pos < segs(k, 2)
            g = segs(k, 3);
            if g >= 0
                incline_factor = 1.0 - K_UP_SPEED * g;
                incline_cost = K_UP_DRAIN * g;
            else
                incline_factor = min(1.0 + K_DOWN_SPEED * abs(g), MAX_DOWN_GAIN);
                incline_cost = K_DOWN_DRAIN * abs(g);
            end
            incline_factor = max(incline_factor, MIN_FACTOR);
            return;
        end
    end
end
