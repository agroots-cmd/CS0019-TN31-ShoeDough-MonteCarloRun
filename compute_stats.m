function stats = compute_stats(mc_results, favorite_id, posted_odds)

    N          = mc_results.N;
    num_horses = mc_results.num_horses;
    times      = mc_results.finish_times;
    winners    = mc_results.winners;

    if nargin < 2 || isempty(favorite_id)
        favorite_id = 1;
    end

    % WIN PROBABILITY STATISTICS
    win_counts = zeros(1, num_horses);
    for i = 1:num_horses
        win_counts(i) = sum(winners == i);
    end
    win_prob = win_counts / N;

    % STANDARD ERROR CALCULATION
    standard_errors = sqrt(win_prob .* (1 - win_prob) / N);

    % CONFIDENCE INTERVALS (postive and negative 95%)
    ci_lower = win_prob - 1.96 * standard_errors;
    ci_upper = win_prob + 1.96 * standard_errors;

    % MEAN AND STANDARD DEVIATION OF FINISH TIMES
    mean_times = mean(times, 1);
    std_times  = std(times, 0, 1);
    cv_times   = std_times ./ mean_times;

    %UPSET RATE
    favorite_wins = sum(winners ~= favorite_id) / N;

    %MARGIN OF VICTORY
    sorted_times = sort(times, 2);
    margin_of_victory = sorted_times(:, 2) - sorted_times(:, 1);
    mean_margin = mean(margin_of_victory);
    std_margin = std(margin_of_victory);

    %BETTING STATISTICS
    fair_odds = inf(1, num_horses);
    valid = win_prob > 0;
    fair_odds(valid) = 1 ./ win_prob(valid);

    % NARGIN - number of arguments in the function call
    % If posted_odds is not provided, use fair_odds
    if nargin < 3 || isempty(posted_odds)
        posted_odds = fair_odds;
    end
    expected_value = (win_prob .* (posted_odds - 1));

    stats.scenario_name  = mc_results.scenario_name;
    stats.win_counts     = win_counts;
    stats.win_probs      = win_prob;
    stats.se             = standard_errors;
    stats.ci_lower       = ci_lower;
    stats.ci_upper       = ci_upper;
    stats.mean_time      = mean_times;
    stats.std_time       = std_times;
    stats.cv_time        = cv_times;
    stats.upset_rate     = favorite_wins;
    stats.margins        = margin_of_victory;
    stats.mean_margin    = mean_margin;
    stats.std_margin     = std_margin;
    stats.fair_odds      = fair_odds;
    stats.expected_value = expected_value;
end