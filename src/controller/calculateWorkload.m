function [W_inst, W_smooth] = calculateWorkload(D_sec, sector_id, varargin)
% CALCULATEWORKLOAD - Calculates instantaneous and smoothed controller workload.
%   Based on 4 key indicators: Volume (N), Vertical movements (V), 
%   Conflicts (C), and Handovers (H).
%
%   Syntax
%       [W_inst, W_smooth] = CALCULATEWORKLOAD(D_sec, sector_id)
%       [W_inst, W_smooth] = CALCULATEWORKLOAD(D_sec, sector_id, omegas)
%       [W_inst, W_smooth] = CALCULATEWORKLOAD(D_sec, sector_id, omegas, lambda)
%
%   Input Arguments
%      * D_sec as struct, the traffic currently inside the specific sector.
%      * sector_id as string/char, unique identifier of the sector (e.g., 'LHCCW1').
%      * omegas as 1x4 double array (optional), weights for [N, V, C, H]. 
%         Default is [1, 2, 4, 2].
%      * lambda as double (optional), exponential smoothing factor. 
%         Default is 0.7.
%
%   Output Arguments
%      * W_inst as double, the instantaneous workload for the current step.
%      * W_smooth as double, the smoothed workload W(t).

    % --- Input Parsing & Defaults ---
    omegas = [1, 2, 4, 2];
    lambda = 0.7; % Default smoothing factor (adjustable)
    
    if nargin >= 3 && ~isempty(varargin{1})
        omegas = varargin{1};
    end
    if nargin >= 4 && ~isempty(varargin{2})
        lambda = varargin{2};
    end
    
    % --- Persistent Memory Initialization ---
    % Map stores the previous state (W_smooth and aircraft callsigns) for each sector
    persistent History
    if isempty(History)
        History = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    % Ensure sector_id is char for the Map key
    sector_id = char(sector_id);
    
    % Current calls (extracting callsigns for Handover calculation)
    if isempty(D_sec)
        N = 0;
        V = 0;
        C = 0;
        current_calls = {};
    else
        % 1. Volume (N)
        N = length(D_sec);
        
        % 2. Vertical Movements (V)
        % Using > 50 fpm threshold to filter out tiny level-offs/noise
        V = sum(abs([D_sec.vertical_rate]) > 50);
        
        % 3. Conflicts (C)
        % We reuse the conflictDetect function with a standard 5 min lookahead
        if N > 1
            CM = conflictDetect(D_sec, 5);
            % CM is symmetric, so we divide the total non-zero elements by 2
            C = sum(CM(:) > 0) / 2;
        else
            C = 0;
        end
        
        current_calls = {D_sec.callsign};
    end
    
    % 4. Handovers (H) & Smoothing Prep
    if isKey(History, sector_id)
        prev_data = History(sector_id);
        prev_calls = prev_data.calls;
        W_prev = prev_data.W_smooth;
        
        % H = Aircraft that ENTERED + Aircraft that LEFT
        % Entered = present in current, but not in previous
        entered = sum(~ismember(current_calls, prev_calls));
        % Left = present in previous, but not in current
        left = sum(~ismember(prev_calls, current_calls));
        
        H = entered + left;
    else
        % First iteration for this sector: no handovers, no previous W
        H = 0; 
        W_prev = NaN;
    end
    
    % --- Workload Calculation ---
    W_inst = omegas(1)*N + omegas(2)*V + omegas(3)*C + omegas(4)*H;
    
    if isnan(W_prev)
        W_smooth = W_inst; % First iteration: W_inst = W (no smoothing)
    else
        W_smooth = lambda * W_prev + (1 - lambda) * W_inst;
    end
    
    % --- Save current state for the next iteration ---
    History(sector_id) = struct('calls', {current_calls}, 'W_smooth', W_smooth);
end