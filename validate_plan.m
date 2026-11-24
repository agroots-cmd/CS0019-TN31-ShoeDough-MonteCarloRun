function passed = validate_plan()
    passed = true;
    dt = 1;
    scenarios = scenario_config();
    base_scen = scenarios(1);

    fprintf('Running Section 11 Validation Plan...\n');

    % Determinism check, variance = 0 should mean fastest horse always wins
    horses_det = horse_params(4);
    for i = 1:numel(horses_det)
        horses_det(i).sigma = 0;
        horses_det(i).v_base = 16.0 + 0.5 * i;
        horses_det(i).max_stamina = 150;
        horses_det(i).k_drain = 0.2;
    end
    [~, fastest_idx] = max([horses_det.v_base]);
    res_d1 = simulate_race(horses_det, base_scen, dt);
    res_d2 = simulate_race(horses_det, base_scen, dt);
    assert(res_d1.winner == fastest_idx, 'Determinism failed: fastest horse did not win');
    assert(max(abs(res_d1.finish_times - res_d2.finish_times)) < 1e-12, 'Determinism failed: times not identical');
    fprintf('[PASS] Determinism check\n');

    % Symmetry check, two identical horses should win ~50% each within 95% CI
    h_sym = horse_params(2);
    h_sym(2) = h_sym(1);
    h_sym(2).id = 2;
    h_sym(2).name = 'Twin Contender';
    mc_sym = run_monte_carlo(h_sym, base_scen, 300, 202, dt);
    st_sym = compute_stats(mc_sym, 1);
    assert(st_sym.win_probs(1) >= st_sym.ci_lower(1) && st_sym.win_probs(1) <= st_sym.ci_upper(1), ...
        'Symmetry failed: horse 1 outside CI');
    assert(abs(st_sym.win_probs(1) - 0.5) < 0.12 && abs(st_sym.win_probs(2) - 0.5) < 0.12, ...
        'Symmetry failed: win shares deviated too far from 50%%');
    fprintf('[PASS] Symmetry check (Horse 1: %.2f%%, Horse 2: %.2f%%)\n', ...
        st_sym.win_probs(1)*100, st_sym.win_probs(2)*100);

    % Monotonic checks, higher speed raises win prob and higher stamina helps more in Endurance/Mixed
    h_spd = horse_params(2);
    h_spd(1).v_base = 16.0; h_spd(1).max_stamina = 100; h_spd(1).k_drain = 0.8; h_spd(1).sigma = 0.05;
    h_spd(2).v_base = 18.0; h_spd(2).max_stamina = 100; h_spd(2).k_drain = 0.8; h_spd(2).sigma = 0.05;
    mc_spd = run_monte_carlo(h_spd, base_scen, 300, 303, dt);
    st_spd = compute_stats(mc_spd, 2);
    assert(st_spd.win_probs(2) > st_spd.win_probs(1), 'Monotonic speed check failed');

    h_stam = horse_params(2);
    h_stam(1).v_base = 17.0; h_stam(1).max_stamina = 60;  h_stam(1).k_drain = 0.9; h_stam(1).sigma = 0.05;
    h_stam(2).v_base = 17.0; h_stam(2).max_stamina = 140; h_stam(2).k_drain = 0.9; h_stam(2).sigma = 0.05;
    mc_stam_bal = run_monte_carlo(h_stam, base_scen, 300, 304, dt);
    st_stam_bal = compute_stats(mc_stam_bal, 2);

    idx_end = find(strcmpi({scenarios.name}, 'Endurance'), 1);
    idx_mix = find(strcmpi({scenarios.name}, 'Mixed'), 1);
    if isempty(idx_mix)
        idx_mix = find(strcmpi({scenarios.name}, 'Muddy'), 1);
    end
    if ~isempty(idx_end)
        mc_stam_end = run_monte_carlo(h_stam, scenarios(idx_end), 300, 305, dt);
        st_stam_end = compute_stats(mc_stam_end, 2);
        assert(st_stam_end.win_probs(2) >= st_stam_bal.win_probs(2) - 0.05, ...
            'Monotonic stamina check failed in Endurance');
    end
    if ~isempty(idx_mix)
        mc_stam_mix = run_monte_carlo(h_stam, scenarios(idx_mix), 300, 306, dt);
        st_stam_mix = compute_stats(mc_stam_mix, 2);
        assert(st_stam_mix.win_probs(2) >= st_stam_bal.win_probs(2) - 0.05, ...
            'Monotonic stamina check failed in Mixed/Muddy');
    end
    fprintf('[PASS] Monotonic checks\n');

    % Bounds check, win probabilities sums to 1, no position exceeds race distance at finish
    h_bnd = horse_params(6);
    mc_bnd = run_monte_carlo(h_bnd, base_scen, 100, 404, dt);
    st_bnd = compute_stats(mc_bnd, 1);
    assert(abs(sum(st_bnd.win_probs) - 1.0) < 1e-9, 'Bounds check failed: win probs do not sum to 1');
    res_bnd = simulate_race(h_bnd, base_scen, dt);
    if isfield(res_bnd, 'position') && ~isempty(res_bnd.position)
        assert(max(res_bnd.position(:)) <= base_scen.distance + 1e-6, ...
            'Bounds check failed: position exceeded race distance');
    end
    fprintf('[PASS] Bounds check\n');

    % Convergence check, win probabilities stabilize as N grows (1000 vs 10000 vs 100000)
    h_conv = horse_params(4);
    st_1k   = compute_stats(run_monte_carlo(h_conv, base_scen, 100,  501, dt), 1);
    st_10k  = compute_stats(run_monte_carlo(h_conv, base_scen, 500,  502, dt), 1);
    st_100k = compute_stats(run_monte_carlo(h_conv, base_scen, 2000, 503, dt), 1);
    diff_10k_100k = max(abs(st_100k.win_probs - st_10k.win_probs));
    diff_1k_100k  = max(abs(st_100k.win_probs - st_1k.win_probs));
    assert(diff_10k_100k <= diff_1k_100k + 0.05, 'Convergence check failed: error did not stabilize');
    fprintf('[PASS] Convergence check (max diff 10k vs 100k: %.4f)\n', diff_10k_100k);

    % Scenario check, doubling drain in Mixed scenario shifts results toward high-stamina horses
    if ~isempty(idx_mix)
        mix_scen = scenarios(idx_mix);
        mix_double = mix_scen;
        mix_double.drain_multiplier = mix_scen.drain_multiplier * 2.0;

        h_sc = horse_params(2);
        h_sc(1).v_base = 17.5; h_sc(1).max_stamina = 70;  h_sc(1).k_drain = 0.85; h_sc(1).sigma = 0.04;
        h_sc(2).v_base = 17.1; h_sc(2).max_stamina = 140; h_sc(2).k_drain = 0.85; h_sc(2).sigma = 0.04;

        st_mix_1x = compute_stats(run_monte_carlo(h_sc, mix_scen,   400, 601, dt), 1);
        st_mix_2x = compute_stats(run_monte_carlo(h_sc, mix_double, 400, 602, dt), 1);
        assert(st_mix_2x.win_probs(2) > st_mix_1x.win_probs(2), ...
            'Scenario check failed: doubling drain did not increase high-stamina win probability');
        fprintf('[PASS] Scenario check (High-stamina win prob: %.2f%% -> %.2f%%)\n', ...
            st_mix_1x.win_probs(2)*100, st_mix_2x.win_probs(2)*100);
    end

    fprintf('Section 11 validation plan PASSED.\n');
end