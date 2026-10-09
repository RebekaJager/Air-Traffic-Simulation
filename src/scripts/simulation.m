clearvars;
clc;
sep_min_infringements = [];
ATC_instructions = [];
AC_in_sector = [];
time = [];
CMs = struct();
t = 20;
[lat, lon, d, bordershp, areashp] = areaCalc('HU', t);

%% Set simulation resolution
% multiplier = 1; -> 5 seconds (default)
% multiplier = 2; -> 10 seconds
% multiplier = 3; -> 15 seconds
multiplier = 2; 

dt_sec = 5 * multiplier; 
dt_min = dt_sec / 60;

%% Prepare data
% Get arcived data point
S = historicalLoad(5000);
% Process data to traffic simulation's own format
D = stateProcess(S.aircraft);
% Filter for area
D = getInside(D, areashp);
D = D([D(:).inside] == 1);
% Filter for above FL030
D = D([D(:).flightlevel] > 30);
%% Traffic Simulation
D = getInside(D, bordershp);
% Filter for aircraft inside the area
D2 = D([D(:).inside] == 1);
%%
current_config_id = 0;
History_Config = [];
History_Workload = {};

% A forciklus most a multiplier szerint ugrik!
for i = 10000 : multiplier : 14000 % max: 235955
    i
    %% Control
    C1 = generateRequests(D2);
    % SV Agent for sector configuration allocation
    [current_config_id, ActiveSectors] = SVAgent(D2, current_config_id, 3, 3);
    % Sector Manager assigns and calls controller agents
    [C, W_log] = SectorManager(C1, ActiveSectors, false);
    History_Config(end+1) = current_config_id;
    History_Workload{end+1} = W_log;
    ATC_instructions(end+1) = ATC_instructions_number(C);
    length(C)
    AC_in_sector(end+1) = length(C);
    
    D = controlStates(D, C);
    D_inside = D([D(:).inside] == 1);
    
    D_inside = estimatePos(D_inside, dt_min);
    D_inside = shiftPos(D_inside);
    
    D_outside = D([D(:).inside] == 0);
    D_outside = estimatePos(D_outside, dt_min);
    
    D = [D_inside; D_outside]; % inside traffic is updated w/ algorithm, outside traffic is kept
    n = separationMinima(D([D(:).inside] == 1));
    sep_min_infringements(end+1) = n;
    
    %% Update positions outside the area
    S = historicalLoad(i);
    try
        time(end+1) = datetime(S.now, 'ConvertFrom', 'posixtime');
    catch
    end
    D_all_updated = stateProcess(S.aircraft);
    % Filter for area
    D_all_updated = getInside(D_all_updated, areashp);
    D_all_updated = D_all_updated([D_all_updated(:).inside] == 1);
    D_all_updated = getInside(D_all_updated, bordershp);
    
    D = updatePos(D, D_all_updated); 
    D = getInside(D, bordershp);
    % Filter for above FL030
    D = D([D(:).flightlevel] > 30);
    D2 = D([D(:).inside] == 1);
    D = estimatePos(D, 1);
   % v = stateMapping_simple(D, 0);
    hold off
end
