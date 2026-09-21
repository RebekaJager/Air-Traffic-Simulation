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
            if D(i).flightlevel == D(j).flightlevel 
                CM(i, j) = 1;
            elseif abs(D(i).flightlevel - D(j).flightlevel) == 10
                idxs = [i j];
                [~, idx] = min([D(i).flightlevel D(j).flightlevel]);
                if D(idxs(idx)).vertical_rate > 0 || D(idxs(3 - idx)).vertical_rate < 0      
                    CM(i, j) = 2;
                end
            elseif isfield(D, 'flightlevel_req')
                % Safely extract requests, avoiding crashes on empty [] arrays
                req_i = D(i).flightlevel;
                if ~isempty(D(i).flightlevel_req) && D(i).flightlevel_req ~= 0
                    req_i = D(i).flightlevel_req;
                end
                
                req_j = D(j).flightlevel;
                if ~isempty(D(j).flightlevel_req) && D(j).flightlevel_req ~= 0
                    req_j = D(j).flightlevel_req;
                end
                
                % Check if either aircraft has an active request forcing a level cross
                if req_i ~= D(i).flightlevel || req_j ~= D(j).flightlevel
                    if ((D(i).flightlevel > D(j).flightlevel) && (req_i < D(i).flightlevel)) || ... 
                       ((D(i).flightlevel < D(j).flightlevel) && (req_i > D(j).flightlevel)) || ...
                       ((D(j).flightlevel > D(i).flightlevel) && (req_j < D(j).flightlevel)) || ...
                       ((D(j).flightlevel < D(i).flightlevel) && (req_j > D(i).flightlevel))
                        CM(i, j) = 3;
                    end
                end
            end
        end
    end
end

CM = triu(CM) + triu(CM).' - diag(diag(CM));
end
