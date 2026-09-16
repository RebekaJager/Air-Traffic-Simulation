function D = estimatePos(D, t)
%
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
    if isempty(D)
        return;
    end

    lats = [D.latitude];
    lons = [D.longitude];
    vels = [D.velocity];
    hdgs = [D.heading];
    alts = [D.altitude];
    vrrs = [D.vertical_rate];
    
    R_earth_km = geocradius(lats, 'WGS84') / 1000;
    dist_km    = vels .* (t * 60) ./ 1000;
    dist_deg   = km2deg(dist_km, R_earth_km);
    
    hdg_rad = deg2rad(hdgs);
    lon_mov = lons + sin(hdg_rad) .* dist_deg;
    lat_mov = lats + cos(hdg_rad) .* dist_deg;
    
    alt_mov = alts + vrrs .* t;
    fl_mov  = floor(alt_mov ./ 1000) .* 10;
    
    lon_c = num2cell(lon_mov); [D.longitude_mov] = lon_c{:};
    lat_c = num2cell(lat_mov); [D.latitude_mov]  = lat_c{:};
    alt_c = num2cell(alt_mov); [D.altitude_mov]  = alt_c{:};
    fl_c  = num2cell(fl_mov);  [D.flightlevel_mov] = fl_c{:};
end
