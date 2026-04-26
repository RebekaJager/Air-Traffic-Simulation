function D = estimatePos(D, t)
% ESTIMATEPOS - Return the predicted future position of aircraft.
%
%   Syntax
%       D = ESTIMATEPOS(D, t)
%
%   Input Arguments
%      D   struct   traffic data
%      t   double   lookahead time [min]
%
%   Output Argument
%      D   struct   traffic data with added _mov fields

n = length(D);

for i = 1:n
    % Distance travelled [deg of arc] along Earth surface
    R_earth_km = geocradius(D(i).latitude, 'WGS84') / 1000;
    dist_km    = D(i).velocity * (t * 60) / 1000;  % v[m/s] * t[s] / 1000
    dist_deg   = km2deg(dist_km, R_earth_km);

    % Horizontal shift (works for all headings)
    hdg_rad = deg2rad(D(i).heading);
    D(i).longitude_mov = D(i).longitude + sin(hdg_rad) * dist_deg;
    D(i).latitude_mov  = D(i).latitude  + cos(hdg_rad) * dist_deg;

    % Vertical shift [ft], vertical_rate assumed [ft/min]
    D(i).altitude_mov    = D(i).altitude + D(i).vertical_rate * t;
    D(i).flightlevel_mov = floor(D(i).altitude_mov / 1000) * 10;
end
end
