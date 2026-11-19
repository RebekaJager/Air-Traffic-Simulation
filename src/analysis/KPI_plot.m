%% KPI_plot.m - Visualization directly from MATLAB Workspace variables
% Requires the following variables in Workspace after running simulation.m:
%   AC_in_sector, sep_min_infringements, ATC_instructions
% Optional in Workspace:
%   time, dt_sec, CMs

required_vars = {'AC_in_sector', 'sep_min_infringements', 'ATC_instructions'};
for v = 1:numel(required_vars)
    if ~exist(required_vars{v}, 'var')
        error('Variable "%s" not found in the Workspace! Please run simulation.m first.', required_vars{v});
    end
end

Aircraft_in_sector = AC_in_sector(:)';
Separation_Minima_Infringements = sep_min_infringements(:)';
ATC_instructions_vec = ATC_instructions(:)';

nSteps = length(Aircraft_in_sector);
x = 1:nSteps;

% Build time axis labels from Workspace 'time' (or fallback to simulation start 13:53:15 UTC)
if exist('time', 'var') && ~isempty(time) && length(time) == nSteps
    Time = string(datestr(time, 'HH:MM:SS'));
else
    if exist('dt_sec', 'var') && ~isempty(dt_sec)
        step_sec = dt_sec;
    else
        step_sec = 10;
    end
    t0 = datetime('13:53:15', 'InputFormat', 'HH:mm:ss');
    times = t0 + seconds(0:step_sec:(nSteps - 1) * step_sec);
    Time = string(datestr(times, 'HH:MM:SS'));
end

%% 1. Main KPI Plot: Traffic Volume, Separation Infringements & ATC Instructions
figure('Name', 'Simulation KPIs', 'Color', 'w', 'Position', [100, 100, 1200, 550]);

yyaxis left
area(x, Aircraft_in_sector, 'FaceAlpha', 0.45, ...
    'DisplayName', 'Aircraft in sector (left axis)', 'EdgeColor', 'none');
ylabel('Aircraft in sector', 'FontWeight', 'bold');
ylim([0, max([Aircraft_in_sector, 1]) * 1.1]);

yyaxis right
hold on
area(x, ATC_instructions_vec, 'FaceAlpha', 0.45, ...
    'DisplayName', 'ATC instructions (right axis)', 'EdgeColor', 'none');
area(x, Separation_Minima_Infringements, 'FaceAlpha', 0.65, ...
    'DisplayName', 'Separation Minima Infringements (right axis)', ...
    'FaceColor', [0.9290, 0.6940, 0.1250], 'EdgeColor', 'none');
hold off

ylabel('ATC instructions & Separation Minima Infringements', 'FontWeight', 'bold');
ylim([0, max([ATC_instructions_vec, Separation_Minima_Infringements, 1]) * 1.15]);

tick_step = max(1, round(nSteps / 10));
tickIndices = 1:tick_step:nSteps;
xticks(tickIndices);
xticklabels(Time(tickIndices));
xtickangle(45);
xlabel('Time (UTC)', 'FontWeight', 'bold');
xlim([1, nSteps]);
title('Traffic Volume, ATC Instructions, and Separation Minima Infringements', 'FontSize', 13);
legend('Location', 'northwest');
grid on;
box off;

%% Print summary metrics to Command Window
fprintf('\n--- KPI Summary (%d steps) ---\n', nSteps);
fprintf('Average aircraft in airspace:         %.2f AC\n', mean(Aircraft_in_sector));
fprintf('Total ATC instructions issued:        %d (avg: %.2f / step)\n', sum(ATC_instructions_vec), mean(ATC_instructions_vec));
fprintf('Aircraft-steps in infringement:       %d (avg: %.2f AC / step, peak: %d AC)\n', ...
    sum(Separation_Minima_Infringements), mean(Separation_Minima_Infringements), max(Separation_Minima_Infringements));
fprintf('Share of infringement-free steps:     %.1f%%\n\n', 100 * mean(Separation_Minima_Infringements == 0));

%% 2. Optional Conflict-Type Breakdown (only if CMs was populated)
if exist('CMs', 'var') && isstruct(CMs) && isfield(CMs, 'conflicts') && ~isempty(CMs)
    nCM = numel(CMs);
    conflictTypes = [1, 2, 3];
    counts = zeros(nCM, numel(conflictTypes));

    for t_idx = 1:nCM
        M = CMs(t_idx).conflicts;
        if isempty(M)
            continue;
        end
        M(logical(eye(size(M)))) = 0;
        for k = 1:numel(conflictTypes)
            counts(t_idx, k) = sum(M(:) == conflictTypes(k)) / 2; % symmetric matrix -> pairs
        end
    end

    figure('Name', 'Conflict Evolution by Type', 'Color', 'w', 'Position', [150, 150, 1200, 500]);
    plot(1:nCM, counts, 'LineWidth', 1.8);
    legend({'1 - Same level, crossing', ...
            '2 - Level crossing (vertical motion)', ...
            '3 - Level crossing (pilot request)'}, ...
            'Location', 'northwest');
    xticks(tickIndices(tickIndices <= nCM));
    xticklabels(Time(tickIndices(tickIndices <= nCM)));
    xtickangle(45);
    xlabel('Time (UTC)', 'FontWeight', 'bold');
    xlim([1, nCM]);
    ylabel('Number of conflict pairs', 'FontWeight', 'bold');
    title('Conflict Evolution by Typology', 'FontSize', 13);
    grid on;
end
