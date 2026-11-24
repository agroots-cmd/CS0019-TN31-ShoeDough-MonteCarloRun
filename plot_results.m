function plot_simulation_results(horses, scenarios, mc_by_scen, stats_by_scen)
    if nargin < 2 || isempty(scenarios)
        scenarios = scenario_config();
    end
    if nargin < 1 || isempty(horses)
        horses = horse_params(6);
    end

    num_scen = numel(scenarios);
    num_horses = numel(horses);
    names = {horses.name};

    if nargin < 3 || isempty(mc_by_scen)
        mc_by_scen = cell(1, num_scen);
        for s = 1:num_scen
            mc_by_scen{s} = run_monte_carlo(horses, scenarios(s), 200, 100 + s, 0.5);
        end
    end

    if nargin < 4 || isempty(stats_by_scen)
        stats_by_scen = cell(1, num_scen);
        [~, fav_idx] = max([horses.v_base]);
        fav_id = horses(fav_idx).id;
        for s = 1:num_scen
            stats_by_scen{s} = compute_stats(mc_by_scen{s}, fav_id);
        end
    end

    % Line graph, should show dynamic speed and stamina profiles over race distance
    mc1 = mc_by_scen{1};
    sc1 = scenarios(1);
    if isfield(mc1, 'sample_run') && ~isempty(mc1.sample_run) && ...
            isfield(mc1.sample_run, 'speed') && isfield(mc1.sample_run, 'stamina')
        sr = mc1.sample_run;
    else
        res = simulate_race(horses, sc1, 0.5);
        sr = res;
    end

    figure('Name', 'Speed and Stamina Profiles Over Distance', 'NumberTitle', 'off');
    subplot(2, 1, 1);
    hold on; grid on;
    for i = 1:num_horses
        if isfield(sr, 'position')
            x_vec = get_row_or_col(sr.position, i, num_horses);
            v_vec = get_row_or_col(sr.speed, i, num_horses);
            n_pts = min(numel(x_vec), numel(v_vec));
            plot(x_vec(1:n_pts), v_vec(1:n_pts), 'LineWidth', 1.4, 'DisplayName', names{i});
        else
            v_vec = get_row_or_col(sr.speed, i, num_horses);
            d_vec = linspace(0, sc1.distance, numel(v_vec));
            plot(d_vec, v_vec, 'LineWidth', 1.4, 'DisplayName', names{i});
        end
    end
    xlabel('Distance (m)');
    ylabel('Speed (m/s)');
    title(sprintf('Dynamic Speed Profile - %s (%.0f m)', sc1.name, sc1.distance));
    legend('Location', 'best');
    hold off;

    subplot(2, 1, 2);
    hold on; grid on;
    for i = 1:num_horses
        if isfield(sr, 'position')
            x_vec = get_row_or_col(sr.position, i, num_horses);
            st_vec = get_row_or_col(sr.stamina, i, num_horses);
            n_pts = min(numel(x_vec), numel(st_vec));
            plot(x_vec(1:n_pts), st_vec(1:n_pts), 'LineWidth', 1.4, 'DisplayName', names{i});
        else
            st_vec = get_row_or_col(sr.stamina, i, num_horses);
            d_vec = linspace(0, sc1.distance, numel(st_vec));
            plot(d_vec, st_vec, 'LineWidth', 1.4, 'DisplayName', names{i});
        end
    end
    xlabel('Distance (m)');
    ylabel('Stamina');
    title(sprintf('Dynamic Stamina Profile - %s (%.0f m)', sc1.name, sc1.distance));
    legend('Location', 'best');
    hold off;

    % Bar chart, should show win probability per horse across scenarios with 95% CI error bars
    win_mat = zeros(num_horses, num_scen);
    err_low = zeros(num_horses, num_scen);
    err_high = zeros(num_horses, num_scen);
    scen_labels = cell(1, num_scen);

    for s = 1:num_scen
        st = stats_by_scen{s};
        scen_labels{s} = scenarios(s).name;
        win_mat(:, s) = st.win_probs(:) * 100;
        err_low(:, s) = max(0, (st.win_probs(:) - st.ci_lower(:)) * 100);
        err_high(:, s) = max(0, (st.ci_upper(:) - st.win_probs(:)) * 100);
    end

    figure('Name', 'Win Probability Across Scenarios', 'NumberTitle', 'off');
    b = bar(1:num_horses, win_mat, 'grouped');
    hold on; grid on;
    for s = 1:num_scen
        if isprop(b(s), 'XEndPoints')
            x_pos = b(s).XEndPoints;
        else
            x_pos = (1:num_horses) + b(s).XOffset;
        end
        errorbar(x_pos, win_mat(:, s), err_low(:, s), err_high(:, s), ...
            'k.', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
    set(gca, 'XTick', 1:num_horses, 'XTickLabel', names, 'XTickLabelRotation', 20);
    ylabel('Win Probability (%)');
    title('Win Probability Across Scenarios (95% CI Error Bars)');
    legend(scen_labels, 'Location', 'best');
    ylim([0, min(100, max(win_mat(:) + err_high(:)) + 8)]);
    hold off;

    % Histogram, will show finish time distributions for the top 3 contenders
    mean_t = stats_by_scen{1}.mean_time(:);
    [~, rank_idx] = sort(mean_t, 'ascend');
    top_k = rank_idx(1:min(3, num_horses));
    top_labels = {'1st Contender', '2nd Contender', '3rd Contender'};

    figure('Name', 'Top 3 Contenders Finish Time Distribution', 'NumberTitle', 'off');
    hold on; grid on;
    for k = 1:numel(top_k)
        h_idx = top_k(k);
        histogram(mc1.finish_times(:, h_idx), 20, 'DisplayName', ...
            sprintf('%s: %s', top_labels{k}, names{h_idx}));
    end
    xlabel('Completion Time (s)');
    ylabel('Frequency');
    title(sprintf('Finish Time Distribution (Top 3) - %s', sc1.name));
    legend('Location', 'best');
    hold off;

    % Scenario comparison table
    fprintf('\n=== SCENARIO COMPARISON TABLE ===\n');
    for s = 1:num_scen
        st = stats_by_scen{s};
        mc = mc_by_scen{s};
        fprintf('\nScenario: %s (N = %d) | Upset Rate: %.2f%% | Avg Margin: %.2fs (±%.2fs)\n', ...
            scenarios(s).name, mc.N, st.upset_rate * 100, st.mean_margin, st.std_margin);
        T = table( ...
            (1:num_horses)', ...
            string(names'), ...
            st.win_probs(:) * 100, ...
            st.mean_time(:), ...
            st.std_time(:), ...
            st.ci_lower(:) * 100, ...
            st.ci_upper(:) * 100, ...
            st.expected_value(:), ...
            'VariableNames', {'ID', 'Horse', 'WinProb_Pct', 'MeanTime_s', 'StdTime_s', 'CI95_Low_Pct', 'CI95_High_Pct', 'EV'});
        disp(T);
    end
end

function vec = get_row_or_col(mat, idx, num_horses)
    if size(mat, 1) == num_horses
        vec = mat(idx, :);
    else
        vec = mat(:, idx).';
    end
end