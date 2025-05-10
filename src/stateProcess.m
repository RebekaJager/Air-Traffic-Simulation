function [D] = stateProcess(S)

% STATEPROCESS - Process data from ADS-B Exchange v2 format to the traffic
%  simulation's own format
%   Syntax
%       [D] = STATEPROCESS(S)
%
%   Input Argument
%      * S as structure, structure of ADS-B data as returned by the API
%         (ADS-B Exchange).
%
%   Output Argument
%      * D as structure, structure of traffic data as required by the traffic
%         simulation.



% Define vectors for data
n = length(S);
lat = zeros(n, 1);
lon = zeros(n, 1);
alt = zeros(n, 1);  % [ft]
vel = zeros(n, 1);  % [m/s]
hdg = zeros(n, 1);  % [deg]
wd = zeros(n, 1);
ws = zeros(n, 1);

FL = zeros(n, 1);
vrr = zeros(n, 1); % [+-m/s]
cls = cell(n, 1);
icao24 = cell(n, 1);
category = cell(n, 1);
typ = cell(n, 1);
for i = 1 : n
    if isfield(S{i, 1}, 'alt_baro') && isnumeric(S{i, 1}.alt_baro)
        alt(i) = S{i, 1}.alt_baro;
    % If there is no barometric altitude data, use geometric altitude
    % for approximation
    elseif isfield(S{i, 1}, 'alt_geom') && isnumeric(S{i, 1}.alt_geom)
        alt(i) = S{i, 1}.alt_geom;
    else
        continue;
    end
    if isfield(S{i, 1}, 'lat') % rr_lat, rr_lon: If no ADS-B or MLAT position available, a rough estimated position for the aircraft based on the receiver’s estimated coordinates.
        lat(i) = S{i, 1}.lat;
    elseif isfield(S{i, 1}, 'rr_lat')
        lat(i) = S{i, 1}.rr_lat;
    end
    if isfield(S{i, 1}, 'lon')
        lon(i) = S{i, 1}.lon;
    elseif isfield(S{i, 1}, 'rr_lon')
        lon(i) = S{i, 1}.rr_lon;
    end
    icao24(i) = cellstr(S{i, 1}.hex);
    if isfield(S{i, 1}, 'gs')
        vel(i) = S{i, 1}.gs * 0.5144444444; % knots to m/s
    end
    if isfield(S{i, 1}, 'track')
        hdg(i) = S{i, 1}.track;
    elseif isfield(S{i, 1}, 'true_heading')
        hdg(i) = S{i, 1}.true_heading;
    end
    if isfield(S{i, 1}, 'baro_rate') % ezzel még foglalkozni
        vrr(i) = S{i, 1}.baro_rate;
    elseif isfield(S{i, 1}, 'geom_rate')
        vrr(i) = S{i, 1}.geom_rate;
    else
        vrr(i) = 0;
    end
    if isfield(S{i, 1}, 'flight')
        cls(i) = cellstr(S{i, 1}.flight);
    end
    if isfield(S{i, 1}, 'wd')
        wd(i) = S{i, 1}.wd;
    end
    if isfield(S{i, 1}, 'ws')
        ws(i) = S{i, 1}.ws;
    end
    if isfield(S{i, 1}, 'category')
        category(i) = cellstr(S{i, 1}.category);
    else
        category(i) = cellstr('A0');
    end
    if isfield(S{i, 1}, 'desc')
        typ(i) = cellstr(S{i, 1}.desc);
    else
        typ(i) = num2cell(0);
    end
end
FL = floor(alt / 100);
FL = floor(FL / 10) * 10;
for i = n : -1 : 1      % Remove data for error correction
    if lat(i) == 0
        cls(i) = [];
        icao24(i) = [];
        lat(i) = [];
        lon(i) = [];
        vel(i) = [];
        hdg(i) = [];
        FL(i)  = [];
        category(i) = [];
        typ(i) = [];
        ws(i) = [];
        wd(i) = [];
    end
end

% Define structure to store data
D = struct('latitude', [], 'longitude', [],'altitude', [], 'flightlevel', [], 'vertical_rate', [], 'velocity', [], 'heading', [], 'callsign', cls, 'ICAO24', icao24,'windspeed', [], 'winddirection', [], 'category', category, 'description', typ);
for i = 1 : length(lat)
    D(i).latitude = lat(i);
    D(i).longitude = lon(i);
    D(i).altitude = alt(i);
    D(i).flightlevel = FL(i);
    D(i).vertical_rate = vrr(i);
    D(i).velocity = vel(i);
    D(i).heading = hdg(i);
    D(i).windspeed = ws(i);
    D(i).winddirection = wd(i);
end

end
