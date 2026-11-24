function result = simulate_race(horses, scenario, dt)

    if nargin < 3 || isempty(dt)
        dt = 0.5; % time step
    end

    % Default Balanced scenario (Testing purposes)
    if nargin < 2 || isempty(scenario)
        scenario.name = 'Balanced';
        scenario.distance = 1600;       % meters (1200 to 3200)
        scenario.track_factor = 1.0;    % speed multiplier
        scenario.drain_multiplier = 1.0;% drain multiplier
    end

    D = scenario.distance;
    num_horses = length(horses);

    % Stamina variables
    stamina_threshold = 0.25;
    stamina_floor = 0.60;   

    % Safety time cap to prevent infinite loops
    max_time = (D / 5.0);
    max_steps = ceil(max_time / dt);

    % State of each horse
    x = zeros(1, num_horses); % position x_i(t)
    s = [horses.max_stamina]; % remaining stamina s_i(t)
    v = zeros(1, num_horses); % current speed v_i(t)
    finish_times = inf(1, num_horses);
    finished = false(1, num_horses);

    % Preallocate history matrices for Member 4's line graphs (Section 8.1)
    time_hist = zeros(max_steps, 1);
    pos_hist = zeros(max_steps, num_horses);
    speed_hist = zeros(max_steps, num_horses);
    stamina_hist = zeros(max_steps, num_horses);

    step = 0;
    while ~all(finished) && step < max_steps
        step = step + 1;
        t = step * dt;
        time_hist(step) = t;

        for i = 1:num_horses
            if finished(i)
                % Keep finished horses clamped at D (Section 11 Bounds check)
                pos_hist(step, i) = D;
                speed_hist(step, i) = 0;
                stamina_hist(step, i) = s(i);
                continue;
            end

            % Use this for sloped terrain
            [incline_factor, incline_cost] = query_track_conditions(x(i), scenario);
          
            % Fatigue Speed Penalty (stamina factor)
            stamina_frac = s(i) / horses(i).max_stamina;
            if stamina_frac >= stamina_threshold
                stamina_factor = 1.0;
            elseif stamina_frac <= 0
                stamina_factor = stamina_floor;
            else
                stamina_factor = stamina_floor + (1.0 - stamina_floor) * (stamina_frac / stamina_threshold);
            end

            % Effective speed
            eps = horses(i).sigma * randn();
            v_i = horses(i).v_base * scenario.track_factor * incline_factor * stamina_factor * (1 + eps);
            v_i = max(v_i, 1.0); % Prevent zero or negative velocity
            v(i) = v_i;

            % Stamina drain per step
            effort_sq = (v_i / horses(i).v_base)^2;
            drain = horses(i).k_drain * effort_sq * scenario.drain_multiplier * (1 + incline_cost) * dt;
            s(i) = max(0.0, s(i) - drain);

            % Position update & linear interpolation on finish
            x_prev = x(i);
            x_next = x_prev + v_i * dt;

            if x_next >= D
                % Linear interpolation between (t - dt) and t
                dist_needed = D - x_prev;
                step_fraction = dist_needed / (v_i * dt);
                finish_times(i) = (t - dt) + step_fraction * dt;
                x(i) = D; % Clamp at race distance D
                finished(i) = true;
            else
                x(i) = x_next;
            end

            % Record profiles
            pos_hist(step, i) = x(i);
            speed_hist(step, i) = v(i);
            stamina_hist(step, i) = s(i);
        end
    end

    % Trim pre-allocated arrays to actual step count
    time_hist = time_hist(1:step);
    pos_hist = pos_hist(1:step, :);
    speed_hist = speed_hist(1:step, :);
    stamina_hist = stamina_hist(1:step, :);

    % Sort finish times to determine finishing order and margin of victory
    [sorted_times, finish_order] = sort(finish_times);
    margin_of_victory = sorted_times(2) - sorted_times(1);

    % Standings table
    place = (1:num_horses)';
    horse_names = {horses(finish_order).name}';
    times_sorted = sorted_times';
    standings = table(place, horse_names, times_sorted, ...
        'VariableNames', {'Place', 'Horse_Name', 'Finish_Time_s'});

    % Display standing
    result.standings = standings;
    result.finish_times = finish_times;
    result.finish_order = finish_order;
    result.winner = finish_order(1);
    result.winner_name = horses(finish_order(1)).name;
    result.margin_of_victory = margin_of_victory;
    result.time = time_hist;
    result.position = pos_hist;
    result.speed = speed_hist;
    result.stamina = stamina_hist;
end

function [incline_factor, incline_cost] = query_track_conditions(pos, scenario)
    % Interfaces with Member 2's track_conditions.m 
    if exist('track_conditions', 'file') == 2
        [incline_factor, incline_cost] = track_conditions(pos, scenario);
    else
        incline_factor = 1.0;
        incline_cost = 0.0;
    end
end