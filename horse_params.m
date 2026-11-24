function horses = horse_params(num_horses)

    if nargin < 1 || isempty(num_horses)
        num_horses = 6;
    end

    name_pool = {'Silence Suzuka', 'Mejiro McQueen', 'Gold Ship', 'Symboli Rudolf', ...
                 'Oguri Cap', 'Tokai Teio', 'Maruzensky', 'Special Week'};
    horses = struct([]);

    for i = 1:num_horses
        horses(i).id = i;
        if i <= length(name_pool)
            horses(i).name = name_pool{i};
        else
            horses(i).name = sprintf('Horse %d', i);
        end

        % Randomized base stats
        raw_speed   = 16.8 + (17.0 - 16.6) * rand();
        raw_stamina = 95.0 + (100.0 - 92.0) * rand();
        raw_drain   = 0.70 + (0.86 - 0.82) * rand();
        step_sigma  = 0.02 + (0.045 - 0.02) * rand();    

        % "good day / bad day" modifier (variance)
        day_modifier = max(0.96, min(1.04, 1.0 + 0.015 * randn()));
        effective_v_base = min(max(raw_speed * day_modifier, 15.5), 18.5);

        horses(i).base_speed = raw_speed;
        horses(i).v_base = effective_v_base;
        horses(i).max_stamina = raw_stamina;
        horses(i).k_drain = raw_drain;
        horses(i).sigma = step_sigma;
    end
end
