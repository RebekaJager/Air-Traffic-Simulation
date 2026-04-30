%% Edit filenames or load manually
scriptDir = fileparts(mfilename('fullpath'));
dataPath = fullfile(scriptDir, '..', 'data', 'AC_in_sector_2.mat');
Aircarft_in_sector = load(fullfile('data', 'AC_in_sector.mat')).AC_in_sector;

dataPath = fullfile(scriptDir, '..', 'data', 'ATC_instructions_2.mat');
ATC_instructions = load(fullfile('data', 'ATC_instructions.mat')).ATC_instructions;

dataPath = fullfile(scriptDir, '..', 'data', 'sep_min_infringements_2.mat');
Separation_Minima_Infringments = load(fullfile('data', 'sep_min_infringements.mat')).sep_min_infringements;
%% Edit filenames or load manually
scriptDir = fileparts(mfilename('fullpath'));
dataPath = fullfile(scriptDir, '..', 'results', '20250825_AC_in_sector.mat');
Aircarft_in_sector = load(fullfile('results', '20250825_AC_in_sector.mat')).AC_in_sector;

dataPath = fullfile(scriptDir, '..', 'results', '20250825_ATC_instructions.mat');
ATC_instructions = load(fullfile('results', '20250825_ATC_instructions.mat')).ATC_instructions;

dataPath = fullfile(scriptDir, '..', 'results', '20250825_sep_min.mat');
Separation_Minima_Infringments = load(fullfile('results', '20250825_sep_min.mat')).sep_min_infringements;
%% time labels for from : to format
t1 = datetime('06:56:34','InputFormat','HH:mm:ss');
t2 = datetime('14:06:34','InputFormat','HH:mm:ss');
step = seconds(5);
times = t1:step:t2;
timeStrings = string(datestr(times,'HH:MM:SS'));
outText = strjoin(timeStrings, '\t');

Time = string(strsplit(outText, '\t'));
%% time labels for nr of points format
t0 = datetime('06:56:34','InputFormat','HH:mm:ss');
times = t0 + seconds(0:5:(7000-1)*5); % set nr of points here
timeStrings = string(datestr(times,'HH:MM:SS'));
Time = strjoin(timeStrings, sprintf('\t'));
Time = string(strsplit(Time, '\t'));
%%
Aircarft_in_sector = AC_in_sector;
Separation_Minima_Infringments = sep_min_infringements;
x = 1:length(Time); 

figure;
yyaxis left
area(x, Aircarft_in_sector, 'FaceAlpha', 0.5, 'DisplayName', 'Aircarft in sector (left axis)', 'EdgeColor','none');
ylabel('Aircraft in sector');
ylim([0, max(Aircarft_in_sector)*1.1])

yyaxis right
hold on
area(x, Separation_Minima_Infringments, 'FaceAlpha', 0.5, 'DisplayName', 'Separation Minima Infringments (right axis)', 'FaceColor', [0.9290, 0.6940, 0.1250], 'EdgeColor','none');
area(x, ATC_instructions, 'FaceAlpha', 0.5, 'DisplayName', 'ATC instructions (right axis)', 'EdgeColor','none');

ylabel('ATC instructions and Separation Minima Infringments');
ylim([0, max([ATC_instructions Separation_Minima_Infringments])*1.1])

customLabels = repmat("", size(Time));
customLabels(1:100:end) = Time(1:100:end);
customLabels = Time(1:200:end);  
tickIndices = 1:200:length(Time);

xticks(tickIndices);
xticklabels(customLabels);
xtickangle(45);
xlabel('Time');
xlim([1, length(Time)])
legend show;
legend('Location', 'northwest');
% set(gca, 'FontName', 'Palatino Linotype')
grid on;
box off;

%%

nSteps = numel(CMs);
conflictTypes = [1, 2, 3];
counts = zeros(nSteps, numel(conflictTypes));

for t = 1:nSteps
    M = CMs(t).conflicts; 
    M(logical(eye(size(M)))) = 0;
    
    for k = 1:numel(conflictTypes)
        counts(t,k) = sum(M(:) == conflictTypes(k));
    end
end

time = (0:nSteps-1) * 5;

figure;
plot(time, counts, 'LineWidth', 2);
legend({'1 - same level, crossing',...
        '2 - level crossing (vert motion)',...
        '3 - level crossing (not vert motion)'}, ...
        'Location','best');
customLabels = repmat("", size(Time));
customLabels(1:100:end) = Time(1:100:end);
customLabels = Time(1:200:end);  
tickIndices = 1:200:length(Time);

xticks(tickIndices);
xticklabels(customLabels);
xtickangle(45);
xlabel('Time');
xlim([1, length(Time)])
ylim([1,8.5])
ylabel('Number of conflicts');
%title('Conflict evolution over time');
legend('Location', 'northwest');
grid on;
