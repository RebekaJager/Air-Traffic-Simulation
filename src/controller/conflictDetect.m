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


% Set default look-ahead time if not provided
look_ahead_time = 2; % default value in minutes
if ~isempty(varargin)
    look_ahead_time = varargin{1};
end

n = length(D); % number of aircraft
CM = zeros(n); % initialize conflict matrix

for i = 1 : n
    for j = 1 : n
        if i >= j, continue, end
        if D(i).flightlevel == D(j).flightlevel    % same level
            [t_min, d_min] = closestApproach(D(i).latitude, D(i).longitude, D(i).velocity, D(i).heading, ...
                                             D(j).latitude, D(j).longitude, D(j).velocity, D(j).heading);
            if d_min < 5 && t_min < look_ahead_time
                CM(i, j) = 1;
            end
        elseif abs(D(i).flightlevel - D(j).flightlevel) == 10
            idxs = [i j];
            [~, idx] = min([D(i).flightlevel D(j).flightlevel]);
            if D(idxs(idx)).vertical_rate > 0 || ...   % the lower aircraft is climbing
               D(idxs(3 - idx)).vertical_rate < 0      % the higher aircraft is descending
                [t_min, d_min] = closestApproach(D(1).latitude, D(i).longitude, D(i).velocity, D(i).heading, ...
                                                 D(2).latitude, D(j).longitude, D(j).velocity, D(j).heading);
                if d_min < 5 && t_min < look_ahead_time
                    CM(i, j) = 2;
                end
            end
        elseif isfield(D, "flightlevel_req")
            if D(i).flightlevel_req ~= 0
                if ((D(i).flightlevel > D(j).flightlevel) && (D(i).flightlevel_req < D(i).flightlevel)) || ... % aircraft i is higher and requested lower
                    ((D(i).flightlevel < D(j).flightlevel) && (D(i).flightlevel_req > D(j).flightlevel))       % aircraft i is lower and requested higher
                    [t_min, d_min] = closestApproach(D(1).latitude, D(i).longitude, D(i).velocity, D(i).heading, ...
                                                     D(2).latitude, D(j).longitude, D(j).velocity, D(j).heading);
                    if d_min < 5 && t_min < look_ahead_time
                        CM(i, j) = 3;
                    end
                end
            end
        end

    end

end

CM = triu(CM) + triu(CM).' - diag(diag(CM));
    function [t_min, d_min] = closestApproach(lat1, lon1, v1, hdg1, ...
            lat2, lon2, v2, hdg2)

        hdg1 = deg2rad(hdg1);
        hdg2 = deg2rad(hdg2);

        lat0 = lat1;
        lon0 = lon1;

        R = 6371000;

        % The simple planar approximation can be considered sufficiently 
        % accurate due to the short distances.
        dLat1 = deg2rad(lat1 - lat0);
        dLon1 = deg2rad(lon1 - lon0);
        dLat2 = deg2rad(lat2 - lat0);
        dLon2 = deg2rad(lon2 - lon0);

        p1 = [R * dLon1 * cos(deg2rad(lat0)), R * dLat1]; % [East, North]
        p2 = [R * dLon2 * cos(deg2rad(lat0)), R * dLat2];

        v1_vec = [v1 * sin(hdg1), v1 * cos(hdg1)];
        v2_vec = [v2 * sin(hdg2), v2 * cos(hdg2)];

        dp = p1 - p2;
        dv = v1_vec - v2_vec;

        t_min = -dot(dp, dv) / (dot(dv, dv) + eps);
        if t_min < 0
            t_min = 0; % in the past
        end

        % positions at closest approach
        r1 = p1 + v1_vec * t_min;
        r2 = p2 + v2_vec * t_min;

        d_min = norm(r1 - r2) / 1852;

        t_min = t_min / 60;

    end
end
