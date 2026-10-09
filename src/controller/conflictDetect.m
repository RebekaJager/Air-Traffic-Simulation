function CM = conflictDetect(D, varargin)

% CONFLICTDETECT - Part of Control Agent. Produces a n x n Conlfict Matrix,
%   where n is the number of aicraft in D. CM is a symmetric matrix, where
%   elements represent the assigned conflict category between the aircraft
%   corresponding to the respective row and column indices in D. Conflict
%   category is based on the specified look ahead time:
%       0 - no conflict, or undefined
%       1 - same level, crossing conflict
%       2 - level crossing conflict, in vertical motion
%       3 - level crossing conflict, not in vertical motion (if request
%       fields exist)
%   for details see: https://skybrary.aero/articles/conflict-solving
%
%   Syntax
%       [CM] = CONFLICTDETECT(D)
%       [CM] = CONTROLLERACTIONS(D, look_ahead_time)
%
%   Input Arguments
%      * D as struct, structure of traffic data.
%      * look_ahead_time as double, look-ahead-time of the controller for
%        considering conflicts in minutes. If not specified 2 minutes is
%        the default value.
%
%   Output Arguments
%      * CM as double, conflict matrix (symmetric matrix).

look_ahead_time = 2; 
if ~isempty(varargin)
    look_ahead_time = varargin{1};
end

n = length(D); 
CM = zeros(n); 
if n < 2
    return;
end

% Pre-calculate spatial data to eliminate O(n^2) redundant math
R = 6371000;
lat_rad = deg2rad([D.latitude]);
lon_rad = deg2rad([D.longitude]);
hdg_rad = deg2rad([D.heading]);
v = [D.velocity]; 

lat0 = mean(lat_rad);
X = R .* lon_rad .* cos(lat0);
Y = R .* lat_rad;

Vx = v .* sin(hdg_rad);
Vy = v .* cos(hdg_rad);

for i = 1 : n
    for j = i+1 : n
        if isfield(D, 'is_owned') && ~D(i).is_owned && ~D(j).is_owned
            continue;
        end
        % Vector math inline for maximum speed
        dp = [X(i) - X(j), Y(i) - Y(j)];
        dv = [Vx(i) - Vx(j), Vy(i) - Vy(j)];
        
        dv2 = dot(dv, dv);
        if dv2 < 1e-8
            t_min = 0;
        else
            t_min = -dot(dp, dv) / dv2;
            if t_min < 0
                t_min = 0;
            end
        end
        
d_min = norm(dp + dv * t_min) / 1852;
        t_min_min = t_min / 60;
        
        if d_min < 5 && t_min_min < look_ahead_time
            % Projected altitude at CPA (after t_min_min minutes) 
            alt_i_cpa = D(i).altitude + D(i).vertical_rate * t_min_min;
            alt_j_cpa = D(j).altitude + D(j).vertical_rate * t_min_min;
            vert_sep_cpa = abs(alt_i_cpa - alt_j_cpa);
            
            % vertical direction
            if vert_sep_cpa < 1000
                % Type 1 (same level conflict)
                if abs(D(i).vertical_rate) < 200 && abs(D(j).vertical_rate) < 200
                    CM(i, j) = 1;
                else
                    % Type 2 (at least one aircraft is changing level)
                    CM(i, j) = 2;
                end
                
            elseif isfield(D, 'flightlevel_req')
                % TYPE 3 (validating pilot request)
                req_i = D(i).flightlevel;
                if ~isempty(D(i).flightlevel_req) && D(i).flightlevel_req ~= 0
                    req_i = D(i).flightlevel_req;
                end
                
                req_j = D(j).flightlevel;
                if ~isempty(D(j).flightlevel_req) && D(j).flightlevel_req ~= 0
                    req_j = D(j).flightlevel_req;
                end
                
                % conflict, if proposed altitudes are under 1000 ft
                % separation
                if req_i ~= D(i).flightlevel || req_j ~= D(j).flightlevel
                    req_alt_i = req_i * 100; % multiplication for converting barometric altitude
                    req_alt_j = req_j * 100;
                    if abs(req_alt_i - req_alt_j) < 1000
                        CM(i, j) = 3;
                    end
                end
            end
        end
    end
end

CM = triu(CM) + triu(CM).' - diag(diag(CM));
end
