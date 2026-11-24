function mc_results = run_monte_carlo(horses, scenario, N, seed, dt)

    if nargin < 5 || isempty(dt)
        dt = 0.5;
    end

    rng(seed);

    num_horses = length(horses);

    finish_times  = zeros(N, num_horses);
    finish_orders = zeros(N, num_horses);
    winners       = zeros(N, 1);


    sample_run = [];

    for trial = 1:N
        res = simulate_race(horses, scenario, dt);

        finish_times(trial, :)  = res.finish_times;
        finish_orders(trial, :) = res.finish_order;
        winners(trial)          = res.winner;

        if trial == 1
            sample_run.time     = res.time;
            sample_run.position = res.position;
            sample_run.speed    = res.speed;
            sample_run.stamina  = res.stamina;
        end
    end

    mc_results.scenario_name = scenario.name;
    mc_results.N             = N;
    mc_results.num_horses    = num_horses;
    mc_results.finish_times  = finish_times;
    mc_results.finish_orders = finish_orders;
    mc_results.winners       = winners;
    mc_results.sample_run    = sample_run;
end