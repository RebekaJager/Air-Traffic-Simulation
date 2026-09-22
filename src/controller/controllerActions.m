function [C] = controllerActions(C1, varargin)
% CONTROLLERACTIONS - Demo controller algorithm. If a separation infringement is detected
%   within the look ahead time, a resolution instruction is given.
%   Note: This is a crude baseline algorithm. For advanced resolution, use
%   conflictDetect and conflictSolve.
%
%   Syntax
%       [C] = CONTROLLERACTIONS(C1)
%       [C] = CONTROLLERACTIONS(C1, look_ahead_time)
%
%   Input Arguments
%      * C1 as struct, structure of traffic data to be controlled.
%      * look_ahead_time as double, look-ahead-time of the controller for
%        considering conflicts in minutes. If not specified 2 minutes is
%        the default value.
%
%   Output Arguments
%      * C as struct, structure of traffic data appended with controller
%        instructions.

switch nargin
    case 1
        look_ahead_time = 2;
    case 2
        look_ahead_time = varargin{2};
    otherwise
        error('Incorrect number of input arguments.')
end

C = C1;

% 1. Accept pilot requests and RESET conflict states
% BUG FIX: Reset the conflict flag to 0 at the start of every call to prevent 
% infinite heading increments in subsequent simulation loops.
for i = 1 : length(C) 
    C(i).conflict = 0; % Reset conflict status
    
    if isfield(C, 'heading_req') && ~isempty(C(i).heading_req)
        C(i).ATC_approval = 1;
        C(i).heading_atc = C(i).heading_req;
    end
    if isfield(C, 'flightlevel_req') && ~isempty(C(i).flightlevel_req)
        C(i).ATC_approval = 1;
        C(i).flightlevel_atc = C(i).flightlevel_req;
    end
    if isfield(C, 'velocity_req') && ~isempty(C(i).velocity_req)
        C(i).ATC_approval = 1;
        C(i).velocity_atc = C(i).velocity_req;
    end
    if isfield(C, 'vertical_rate_req') && ~isempty(C(i).vertical_rate_req)
        C(i).ATC_approval = 1;
        C(i).vertical_rate_atc = C(i).vertical_rate_req;
    end
end

% 2. Detect and solve conflicts
for t = 0 : 10/60 : look_ahead_time
    P = estimatePos(C, t);
    n = length(P);
    
    % Fast equirectangular distance prep
    R = 6371000;
    if n > 0
        lat_rad = deg2rad([P.latitude_mov]);
        lon_rad = deg2rad([P.longitude_mov]);
        lat0 = mean(lat_rad);
        X = R .* lon_rad .* cos(lat0);
        Y = R .* lat_rad;
    end
    
    for i = 1 : n
        for j = i+1 : n
            if P(i).flightlevel == P(j).flightlevel
                % Fast distance check replacing wgs84Ellipsoid
                d_meters = sqrt((X(i) - X(j))^2 + (Y(i) - Y(j))^2);
                d = d_meters / 1852;
                
                if d < 5 
                    C(i).conflict = 1;
                    C(j).conflict = 1;
                end
            elseif abs(P(i).flightlevel - P(j).flightlevel) < 10
                if P(i).flightlevel > P(j).flightlevel
                    C(i).flightlevel_atc = C(i).flightlevel + 10;
                else
                    C(j).flightlevel_atc = C(j).flightlevel + 10;
                end
            end
        end
    end
    
    % Apply heading changes based on conflict flags generated in this loop
    for i = 1 : n
        if C(i).conflict == 1
            % We no longer need isfield(C, 'conflict') because we initialized it above
            C(i).heading_atc = mod(C(i).heading + 30, 360); % Added mod to keep heading valid
        end
    end
end
end
