% --- MUNKATERHELÉS ÉS SZEKTOR KONFIGURÁCIÓ VIZUALIZÁCIÓ ---
% Feltételezi, hogy a "History_Workload" változó létezik a Workspace-ben!

if ~exist('History_Workload', 'var')
    error('A History_Workload változó nem található! Futtasd le előbb a szimulációt.');
end

N = length(History_Workload);
time_steps = 1:N;

% 1. Adatok kinyerése és az összes valaha létezett szektor azonosítása
all_sectors = {};
num_sectors = zeros(1, N);

for i = 1:N
    if ~isempty(History_Workload{i})
        num_sectors(i) = length(History_Workload{i});
        sector_names = {History_Workload{i}.SectorName};
        all_sectors = [all_sectors, sector_names];
    end
end

unique_sectors = unique(all_sectors);
num_unique = length(unique_sectors);

% 2. Munkaterhelés mátrix feltöltése (NaN-nal, ahol a szektor épp zárva van)
W_matrix = NaN(num_unique, N);

for i = 1:N
    if ~isempty(History_Workload{i})
        for k = 1:length(History_Workload{i})
            s_name = History_Workload{i}(k).SectorName;
            w_val = History_Workload{i}(k).Workload;
            
            % Kikeressük, melyik sor tartozik ehhez a szektorhoz
            row_idx = strcmp(unique_sectors, s_name);
            W_matrix(row_idx, i) = w_val;
        end
    end
end

% --- 3. ELSŐ ÁBRA: Idővonal (Munkaterhelés és Szektorszám) ---
figure('Name', 'ATC Workload and Sector Configurations', 'Color', 'w', 'Position', [100, 100, 1200, 600]);

% JOBB TENGELY: Nyitott szektorok száma (Halvány háttér)
yyaxis right
t_step = zeros(1, 2*N);
y_step = zeros(1, 2*N);
t_step(1:2:end) = time_steps - 0.5; 
t_step(2:2:end) = time_steps + 0.5; 
y_step(1:2:end) = num_sectors;
y_step(2:2:end) = num_sectors;

h_area = area(t_step, y_step, 'FaceAlpha', 0.1, 'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'none');
set(get(get(h_area,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');

ylabel('Active Sectors (Count)', 'Color', [0.5 0.5 0.5], 'FontSize', 11, 'FontWeight', 'bold');
ax = gca;
ax.YColor = [0.5 0.5 0.5];
ylim([0, max(num_sectors) + 2]);
yticks(0:1:(max(num_sectors) + 1)); 

% BAL TENGELY: Munkaterhelés (Színes egyéni vonalak)
yyaxis left
hold on;

% Színpaletta módosítása (garantáltan egyedi színek, ismétlődés nélkül)
colors = hsv(num_unique); 
rng(42); % Fix seed a keveréshez, hogy minden futtatásnál ugyanez legyen a szektor-szín párosítás
colors = colors(randperm(num_unique), :); 

lines_handles = [];
for i = 1:num_unique
    % Explicit megadjuk a '-' stílust és a 'Marker', 'none' paramétert
    h = plot(time_steps, W_matrix(i, :), '-', 'LineWidth', 2, 'Color', colors(i,:), ...
        'Marker', 'none', 'DisplayName', unique_sectors{i});
    lines_handles = [lines_handles, h];
end

ylabel('Agent Workload (Smoothed)', 'Color', 'k', 'FontSize', 11, 'FontWeight', 'bold');
ax = gca;
ax.YColor = 'k';

max_W = max(W_matrix, [], 'all');
if ~isnan(max_W) && max_W > 0
    ylim([0, max_W * 1.2]); 
end

xlabel('Simulation Time (Iterations)', 'FontSize', 11, 'FontWeight', 'bold');
title('Individual Agent Workload and Dynamic Airspace Sectorization', 'FontSize', 14);
grid on;
xlim([1, N]);
legend(lines_handles, 'Location', 'northwest', 'NumColumns', 2, 'FontSize', 9);
hold off;

% --- 4. MÁSODIK ÁBRA: Hisztogram a statisztikai W_crit meghatározásához ---

% Összegyűjtjük az összes valós munkaterhelés értéket (kihagyva az üres szektorok NaN értékeit)
all_W = W_matrix(~isnan(W_matrix));

figure('Name', 'Workload Statistical Distribution', 'Color', 'w', 'Position', [150, 150, 800, 500]);
histogram(all_W, 'BinWidth', 1, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'w');
hold on;

% Statisztikai küszöbök (Percentilisek) kiszámítása
p90 = prctile(all_W, 90);
p95 = prctile(all_W, 95);

% Függőleges vonalak behúzása a kritikus értékekhez
xline(p90, '--', sprintf('90th Percentile (W_{crit} = %.1f)', p90), ...
    'Color', [0.8 0.2 0.2], 'LineWidth', 2, 'FontSize', 10, 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'top');
    
xline(p95, '-.', sprintf('95th Percentile (W_{crit} = %.1f)', p95), ...
    'Color', [0.6 0.0 0.0], 'LineWidth', 2, 'FontSize', 10, 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'middle');

title('Agent Workload Distribution (Statistical W_{crit} Estimation)', 'FontSize', 14);
xlabel('Agent Workload (Smoothed)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Frequency (Data Points)', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
hold off;