clc; close all;

ans_spec = upper(strtrim(input('Enter a race as a spectator? Y/N: ', 's')));
if ~strcmp(ans_spec, 'Y')
    disp('Exiting.');
    return;
end

num_horses = 6;
dt = 0.5;
seed_base = 100;
scenarios = scenario_config();

scen_order = {'Balanced', 'Muddy', 'Endurance'};
scen_step = 1;
idx = find(strcmpi({scenarios.name}, scen_order{scen_step}), 1);
if isempty(idx), idx = 1; end
scen = scenarios(idx);

horses = horse_params(num_horses);
mc = [];

while true
    fprintf('\nCurrent Horses & Track Conditions (%s):\n', scen.name);
    fprintf('Surface: %s | Distance: %.0f m\n', ...
        scen.surface, scen.distance);

    fprintf('\nRoster:\n');
    for i = 1:numel(horses)
        h = horses(i);
        fprintf('%d. %-16s | Speed: %.2f | Stamina: %.1f | Fatigue Rate: %.2f\n', ...
            h.id, h.name, h.v_base, h.max_stamina, h.k_drain);
    end

    fprintf('-----------------------------------\n');
    fprintf('1. Bet and proceed to the race\n');
    fprintf('2. Wait for next race\n');
    fprintf('3. Run Monte Carlo simulation\n');
    fprintf('4. Compute statistics\n');
    fprintf('5. Plot simulation results\n');
    fprintf('6. Run validation plan\n');
    fprintf('7. Exit\n');
    fprintf('-----------------------------------\n');

    choice = str2double(strtrim(input('Choose Option: ', 's')));

    if choice == 1
        pick = prompt_horse_pick(numel(horses));
        res = simulate_race(horses, scen, dt);
        fprintf('\nDISPLAY RACE RESULTS\n');
        for p = 1:numel(res.finish_order)
            horse_idx = res.finish_order(p);
            fprintf('%d. %-16s - %.2fs\n', p, horses(horse_idx).name, res.finish_times(horse_idx));
        end

        if res.winner == pick
            disp('Your chosen horse has won, congratulations!');
        else
            disp('Your chosen horse has lost, try again!');
        end
    elseif choice == 2
        scen_step = mod(scen_step, numel(scen_order)) + 1;
        idx = find(strcmpi({scenarios.name}, scen_order{scen_step}), 1);
        if isempty(idx), idx = scen_step; end
        scen = scenarios(idx);
        horses = horse_params(num_horses);
        mc = [];
    elseif choice == 3
        num_trials = prompt_trials();
        mc = run_monte_carlo(horses, scen, num_trials, seed_base + scen_step, dt);
        win_probs = arrayfun(@(id) mean(mc.winners == id), [horses.id]) * 100;
        avg_times = mean(mc.finish_times, 1);

        fprintf('\nMONTE CARLO RESULTS (%d Trials - %s)\n', mc.N, mc.scenario_name);
        for i = 1:numel(horses)
            fprintf('%d. %-16s | Win Prob: %6.2f%% | Avg Time: %.2fs\n', ...
                horses(i).id, horses(i).name, win_probs(i), avg_times(i));
        end
    elseif choice == 4
        if isempty(mc)
            num_trials = prompt_trials();
            mc = run_monte_carlo(horses, scen, num_trials, seed_base + scen_step, dt);
        end

        [~, fav_idx] = max([horses.v_base]);
        favorite_id = horses(fav_idx).id;
        stats = compute_stats(mc, favorite_id);

        fprintf('\nSTATISTICS SUMMARY (%s, N = %d)\n', stats.scenario_name, mc.N);
        fprintf('Favorite: %s (ID %d) | Upset Rate: %.2f%% | Avg Margin: %.2fs (±%.2fs)\n', ...
            horses(fav_idx).name, favorite_id, stats.upset_rate * 100, stats.mean_margin, stats.std_margin);

        for i = 1:numel(horses)
            fprintf('%d. %-16s | Win: %6.2f%% [%.2f%%, %.2f%%] | Mean: %.2fs (±%.2fs) | Fair Odds: %.2f\n', ...
                horses(i).id, horses(i).name, ...
                stats.win_probs(i) * 100, stats.ci_lower(i) * 100, stats.ci_upper(i) * 100, ...
                stats.mean_time(i), stats.std_time(i), stats.fair_odds(i));
        end
    elseif choice == 5
        num_trials = prompt_trials();
        [~, fav_idx] = max([horses.v_base]);
        favorite_id = horses(fav_idx).id;

        ordered_scens = scenarios;
        for k = 1:numel(scen_order)
            s_idx = find(strcmpi({scenarios.name}, scen_order{k}), 1);
            if ~isempty(s_idx)
                ordered_scens(k) = scenarios(s_idx);
            end
        end

        mc_by_scen = cell(1, numel(ordered_scens));
        stats_by_scen = cell(1, numel(ordered_scens));
        for s = 1:numel(ordered_scens)
            mc_by_scen{s} = run_monte_carlo(horses, ordered_scens(s), num_trials, seed_base + s, dt);
            stats_by_scen{s} = compute_stats(mc_by_scen{s}, favorite_id);
        end

        plot_results(horses, ordered_scens, mc_by_scen, stats_by_scen);
    elseif choice == 6
        validate_plan();[cite: 8]
    elseif choice == 7
        break;
    else
        disp('Invalid option. Please enter 1, 2, 3, 4, 5, 6, or 7.');
    end
end

function pick = prompt_horse_pick(num_horses)
    while true
        val = str2double(strtrim(input(sprintf('Pick a horse (1-%d): ', num_horses), 's')));
        if ~isnan(val) && isfinite(val) && val >= 1 && val <= num_horses && floor(val) == val
            pick = val;
            return;
        end
        fprintf('Please enter a valid horse number from 1 to %d.\n', num_horses);
    end
end

function n = prompt_trials()
    while true
        val = str2double(strtrim(input('Enter number of trials: ', 's')));
        if ~isnan(val) && isfinite(val) && val >= 1 && floor(val) == val
            n = val;
            return;
        end
        disp('Please enter a positive integer.');
    end
end