function scenarios = scenario_config()
%SCENARIO_CONFIG Defines the Balanced, Mixed, and Endurance track scenarios.
%   Member 2 deliverable (spec Sections 5 and 10). Returns a 1x3 struct
%   array. Each scenario plugs into Member 1's simulate_race(horses,
%   scenario, dt), which reads .distance, .track_factor, and
%   .drain_multiplier directly and passes the whole struct to
%   track_conditions(pos, scenario) for position-dependent modifiers.
%
%   Fields:
%     name             - scenario label for tables and plots
%     surface          - short surface description for reporting
%     distance         - race distance D in meters
%     track_factor     - uniform speed multiplier (surface quality)
%     drain_multiplier - uniform stamina drain multiplier
%     inclines         - Kx3 matrix [start_m, end_m, grade] per row.
%                        grade = rise/run; positive = uphill, negative =
%                        downhill. Empty matrix = flat track.

    scenarios = struct();

    % --- 1. Balanced Track (baseline: flat dirt, standard drain) ---
    scenarios(1).name = 'Balanced';
    scenarios(1).surface = 'flat dirt';
    scenarios(1).distance = 1600;          % matches simulate_race default
    scenarios(1).track_factor = 1.0;
    scenarios(1).drain_multiplier = 1.0;
    scenarios(1).inclines = [];

    % --- 2. Mixed Track (muddy/rocky, steep inclines, 2x drain) ---
    scenarios(2).name = 'Mixed';
    scenarios(2).surface = 'muddy/rocky with steep inclines';
    scenarios(2).distance = 1600;          % same distance as Balanced so
                                           % differences come from terrain
    scenarios(2).track_factor = 0.90;      % mud slows everyone ~10%
    scenarios(2).drain_multiplier = 2.0;   % spec Section 5
    % [start_m, end_m, grade]: +8% climb, -5% descent, +10% finishing climb
    scenarios(2).inclines = [ 300  600   0.08;
                              800 1000  -0.05;
                             1200 1500   0.10];

    % --- 3. Endurance Track (extended distance, standard drain) ---
    scenarios(3).name = 'Endurance';
    scenarios(3).surface = 'flat dirt, extended distance';
    scenarios(3).distance = 2800;          % 1.75x baseline (spec: 1.5x-2x)
    scenarios(3).track_factor = 1.0;
    scenarios(3).drain_multiplier = 1.0;
    scenarios(3).inclines = [];
end
