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

n = length(S);

% Preallocate vectors
lat = zeros(n, 1);
lon = zeros(n, 1);
alt = zeros(n, 1);  % [ft]
vel = zeros(n, 1);  % [m/s]
hdg = zeros(n, 1);  % [deg]
wd  = zeros(n, 1);
ws  = zeros(n, 1);
vrr = zeros(n, 1);  % [+-m/s]

cls      = cell(n, 1);
icao24   = cell(n, 1);
category = cell(n, 1);
typ      = cell(n, 1);

% Conversion constants
knots2ms = 0.5144444444;
% ftmin2ms = 0.00508; % unnecessary

% Extract data in a loop (Since S is a cell array of structs with variable fields, 
% a loop is often unavoidable, but we can make it as fast as possible)
for i = 1 : n
    % Get the current struct to avoid repeated cell indexing overhead
    curr_S = S{i}; 
    
    % Altitude
    if isfield(curr_S, 'alt_baro') && isnumeric(curr_S.alt_baro)
        alt(i) = curr_S.alt_baro;
    elseif isfield(curr_S, 'alt_geom') && isnumeric(curr_S.alt_geom)
        alt(i) = curr_S.alt_geom;
    else
        continue; % Skip if no altitude
    end
    
    % Latitude & Longitude
    if isfield(curr_S, 'lat')
        lat(i) = curr_S.lat;
        lon(i) = curr_S.lon; % Assume lon is there if lat is
    elseif isfield(curr_S, 'rr_lat')
        lat(i) = curr_S.rr_lat;
        lon(i) = curr_S.rr_lon;
    end
    
    % Hex (ICAO24)
    icao24{i} = curr_S.hex; % 'hex' is practically always present
    
    % Velocity
    if isfield(curr_S, 'gs')
        vel(i) = curr_S.gs * knots2ms;
    end
    
    % Heading
    if isfield(curr_S, 'track')
        hdg(i) = curr_S.track;
    elseif isfield(curr_S, 'true_heading')
        hdg(i) = curr_S.true_heading;
    end
    
    % Vertical rate
    if isfield(curr_S, 'baro_rate')
        vrr(i) = curr_S.baro_rate;
    elseif isfield(curr_S, 'geom_rate')
        vrr(i) = curr_S.geom_rate;
    end
    
    % Callsign
    if isfield(curr_S, 'flight')
        cls{i} = strtrim(curr_S.flight); % trim whitespace just in case
    else
        cls{i} = '';
    end
    
    % Wind
    if isfield(curr_S, 'wd')
        wd(i) = curr_S.wd;
    end
    if isfield(curr_S, 'ws')
        ws(i) = curr_S.ws;
    end
    
    % Category
    if isfield(curr_S, 'category')
        category{i} = curr_S.category;
    else
        category{i} = 'A0';
    end
    
    % Description (Type)
    if isfield(curr_S, 'desc')
        typ{i} = curr_S.desc;
    else
        typ{i} = 0;
    end
end

% Compute Flight Level
FL = round((alt / 100) / 10) * 10;

% Identify valid entries (where latitude was found and not 0)
% Instead of looping backwards, we use logical indexing which is significantly faster.
valid_idx = (lat ~= 0);

% Filter all arrays simultaneously
lat      = lat(valid_idx);
lon      = lon(valid_idx);
alt      = alt(valid_idx);
FL       = FL(valid_idx);
vrr      = vrr(valid_idx);
vel      = vel(valid_idx);
hdg      = hdg(valid_idx);
wd       = wd(valid_idx);
ws       = ws(valid_idx);
cls      = cls(valid_idx);
icao24   = icao24(valid_idx);
category = category(valid_idx);
typ      = typ(valid_idx);

% Create the final struct array in one vectorized step using num2cell
% This eliminates the need for the second for-loop entirely.
D = struct('latitude', num2cell(lat), ...
           'longitude', num2cell(lon), ...
           'altitude', num2cell(alt), ...
           'flightlevel', num2cell(FL), ...
           'vertical_rate', num2cell(vrr), ...
           'velocity', num2cell(vel), ...
           'heading', num2cell(hdg), ...
           'callsign', cls, ...
           'ICAO24', icao24, ...
           'windspeed', num2cell(ws), ...
           'winddirection', num2cell(wd), ...
           'category', category, ...
           'description', typ);
end
