function [n] = separationMinima(D, varargin)

% SEPARATIONMINIMA  - Get the number of separation minima infringements in 
%   the traffic structure. Separation minima is assumed according to RVSM 
%   airspace rules as specified in ICAO Annex 11, as 5 nm horizontally and 
%   1000 ft vertically unless otherwised specified by th user.
% 
%   Syntax
%       [n] = SEPARATIONMINIMA(D) Use deafult values for separation minima.
%       [n] = SEPARATIONMINIMA(D, horizontal, vertical) User definied 
%        values for separation minima.
% 
%   Input Arguments
%      * D as structure, structure of traffic data.
%      * horizontal as double, horizontal separation in nautical miles.
%      * vertical as double, vertical separation in feet.
% 
%   Output Arguments
%      * n as double, the number of aircraft experiencing separation minima
%         infringements. E.g. a two aircraft conflict has the value of 2.

n = 0;
switch nargin
    case 1
        horizontal = 5;
        vertical = 10; % 10 FL = 1000 ft
    case 3
        horizontal = varargin{2};
        vertical = varargin{3}/100;
    otherwise
        error('Incorrect number of input arguments.')
end

num_ac = length(D);
if num_ac < 2
    return;
end

% Pre-calculate arrays for fast vector operations
lat_rad = deg2rad([D.latitude]);
lon_rad = deg2rad([D.longitude]);
fl = [D.flightlevel];

% Fast equirectangular projection
R = 6371000;
lat0 = mean(lat_rad);
X = R .* lon_rad .* cos(lat0);
Y = R .* lat_rad;

conflict_flags = false(1, num_ac);

% Avoid double-counting with j = i+1
for i = 1 : num_ac
    for j = i+1 : num_ac
        % A conflict requires BOTH vertical AND horizontal separation loss simultaneously
        if abs(fl(i) - fl(j)) < vertical
            d_meters = sqrt((X(i) - X(j))^2 + (Y(i) - Y(j))^2);
            d_nm = d_meters / 1852;
            
            if d_nm < horizontal
                conflict_flags(i) = true;
                conflict_flags(j) = true;
            end
        end
    end
end

% Number of aircraft in conflict
n = sum(conflict_flags);
end
