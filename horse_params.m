function horses = horse_params()

    horses = struct(...
        'id',          {1, 2, 3, 4, 5, 6, 7}, ...
        'name',        {'Silence Suzuka', 'Mejiro McQueen', 'Gold Ship', 'Symboli Rudolf', 'Oguri Cap', 'Tokai Teio', 'Maruzensky'}, ...
        'v_base',      {17.8, 16.2, 17.1, 17.0, 17.5, 17.3, 18.0}, ... % m/s (16 to 18)
        'max_stamina', {86.0, 120.0, 112.0, 105.0, 98.0, 100.0, 80.0}, ... % units (80 to 120)
        'k_drain',     {1.15, 0.80, 0.90, 0.92, 0.98, 1.00, 1.22}, ... % units/sec
        'sigma',       {0.035, 0.022, 0.080, 0.020, 0.038, 0.042, 0.030} ... % fraction of speed (0.02 to 0.08)
    );
end
