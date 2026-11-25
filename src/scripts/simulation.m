      clearvars -except sim_ctrl sa_*;   % keep the settings of sensitivity_analysis.m
if ~exist('sim_ctrl', 'var'), clc; end   % no clc when started by sensitivity_analysis.m (keeps its progress log)

%% Simulation control (set by sensitivity_analysis.m; defaults for standalone runs)
if ~exist('sim_ctrl', 'var'), sim_ctrl = struct(); end
if ~isfield(sim_ctrl, 'enable_errors'), sim_ctrl.enable_errors = false; end  % false = error-free baseline run
if isfield(sim_ctrl, 'rng_seed'), rng(sim_ctrl.rng_seed); end                % reproducible error draws
clear calculateWorkload SVAgent;   % reset persistent states of the previous run
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

%% Model parameters (all defaults and overrides come from defaultErrorParams)
params = defaultErrorParams();
params.dt_sec = dt_sec;   % keep tau_mem consistent with the time step

%% Traffic cache
% The traffic input (ADS-B snapshots, filtered to the area) does not depend on
% any model parameter, so it is downloaded and processed ONCE and stored in
% data/cache. All later runs (and all parallel workers) read it from there.
i_start = 10000;
i_end   = 14000;     % max: 235955
cache_root = getenv('PROJECT_ROOT');
if isempty(cache_root), cache_root = pwd; end
cache_dir  = fullfile(cache_root, 'data', 'cache');
cache_file = fullfile(cache_dir, sprintf('traffic_HU_t%d_m%d_i%d-%d.mat', t, multiplier, i_start, i_end));
use_cache  = isfile(cache_file);
if use_cache
    TrafficCache = load(cache_file, 'D0', 'D_all', 'now_posix');
else
    TrafficCache.D_all     = cell(numel(i_start:multiplier:i_end), 1);
    TrafficCache.now_posix = nan(numel(i_start:multiplier:i_end), 1);
end

%% Prepare data
if use_cache
    D = TrafficCache.D0;
else
    % Get arcived data point
    S = historicalLoad(5000);
    % Process data to traffic simulation's own format
    D = stateProcess(S.aircraft);
    % Filter for area
    D = getInside(D, areashp);
    D = D([D(:).inside] == 1);
    % Filter for controlled airspace vertical limits (FL095 - FL660)
    D = D([D(:).flightlevel] >= 95 & [D(:).flightlevel] < 660);
    %% Traffic Simulation
    D = getInside(D, bordershp);
    TrafficCache.D0 = D;
end
% Filter for aircraft inside the area
D = assignExitTargets(D, bordershp);
D2 = D([D(:).inside] == 1);
%%
current_config_id = 0;
History_Config = [];
History_Workload = {};
n_steps = numel(i_start : multiplier : i_end);
now_posix_log = nan(1, n_steps);
%t_now_posix = NaN;  History_Fallback = [];  History_MaxSec = [];

for i = i_start : multiplier : i_end
    i
    k_step = (i - i_start) / multiplier + 1;
    %% Control
    C1 = generateRequests(D2);
    % SV Agent for sector configuration allocation (20-min look-ahead horizon on D2)
    [current_config_id, ActiveSectors] = SVAgent(D2, current_config_id, 20, 3);

    % Sector Manager assigns and calls controller agents
    [C, W_log] = SectorManager(C1, ActiveSectors, sim_ctrl.enable_errors, params);
    History_Config(end+1) = current_config_id;
    History_Workload{end+1} = W_log;
    ATC_instructions(end+1) = ATC_instructions_number(C);
    AC_in_sector(end+1) = length(C);
    D = controlStates(D, C, 0, 0, dt_sec);
    D_inside = D([D(:).inside] == 1);
    
    D_inside = estimatePos(D_inside, dt_min);
    D_inside = shiftPos(D_inside);
    
    D_outside = D([D(:).inside] == 0);
    D_outside = estimatePos(D_outside, dt_min);
    
    D = [D_inside; D_outside]; % inside traffic is updated w/ algorithm, outside traffic is kept
    n = separationMinima(D([D(:).inside] == 1));
    sep_min_infringements(end+1) = n;
    
    %% Update positions outside the area
    if use_cache
        D_all_updated = TrafficCache.D_all{k_step};
        now_posix     = TrafficCache.now_posix(k_step);
    else
        S = historicalLoad(i);
        now_posix = NaN;
        if isfield(S, 'now'), now_posix = S.now; end
        D_all_updated = stateProcess(S.aircraft);
        % Filter for area
        D_all_updated = getInside(D_all_updated, areashp);
        D_all_updated = D_all_updated([D_all_updated(:).inside] == 1);
        D_all_updated = getInside(D_all_updated, bordershp);
        TrafficCache.D_all{k_step}     = D_all_updated;
        TrafficCache.now_posix(k_step) = now_posix;
    end
    now_posix_log(k_step) = now_posix;
    %t_now_posix = now_posix;
    
    D = updatePos(D, D_all_updated); 
    D = getInside(D, bordershp);
    % Filter for controlled airspace vertical limits (FL095 - FL660)
    D = D([D(:).flightlevel] >= 95 & [D(:).flightlevel] < 660);
    D = assignExitTargets(D, bordershp);
    D2 = D([D(:).inside] == 1);
    % v = stateMapping_simple(D, 0);
end

valid_posix = now_posix_log(~isnan(now_posix_log));
if ~isempty(valid_posix)
    time = datetime(valid_posix, 'ConvertFrom', 'posixtime');
end

%% Store the traffic cache after the first complete run
if ~use_cache
    D0 = TrafficCache.D0; D_all = TrafficCache.D_all; now_posix = TrafficCache.now_posix; %#ok<NASGU>
    if ~isfolder(cache_dir), mkdir(cache_dir); end
    tmp_file = [tempname(cache_dir) '.mat'];            % write to a temp name first,
    save(tmp_file, 'D0', 'D_all', 'now_posix');          % standard v7 format is 50x faster for cell structs
    movefile(tmp_file, cache_file);                      % file is never read by another run
    clear D0 D_all now_posix tmp_file;
end
