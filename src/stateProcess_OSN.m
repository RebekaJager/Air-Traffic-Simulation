function [D] = stateProcess_OSN(S)
% STATEPROCESS - Process data from OpenSky Network to the traffic
%   simulation's own format.
%
%   Syntax
%       D = STATEPROCESS(S)
%
%   Input Argument
%      * S as structure, structure of ADS-B data as returned by the 
%        OpenSky Network API
%
%   Output Argument
%      * D as structure, structure of traffic data formatted for use 
%        in the traffic simulation


% For data from OpenSky REST API
% Define vectors for data
n = length(S);
lat = zeros(n, 1);
lon = zeros(n, 1);
alt = zeros(n, 1);  % [m]
vel = zeros(n, 1);  % [m/s]
hdg = zeros(n, 1);  % [deg]

FL = zeros(n, 1);
FLs = 10 : 5 : 510;
vrr = zeros(n, 1); % [+-m/s]
cls = cell(n, 1);
icao24 = zeros(n, 1);
category = zeros(n, 1);
for i = 1 : n
    if S{i, 1}{9} == 0      % Position report is not from surface report
        if ~isempty(S(i)) && (~isempty(S{i,1}{7}))
            cls(i) = cellstr(S{i,1}{2});
            icao24(i) = hex2dec(cellstr(S{i,1}{1}));
            lat(i) = S{i,1}{7};
            lon(i) = S{i,1}{6};
            category(i) = S{i, 1}{17};
        end
        if isempty(S{i,1}{8})
            alt(i) = 0;
        else
            alt(i) = S{i,1}{8};
        end
        if isempty(S{i,1}{10})
            vel(i) = 0;
        else
            vel(i) = S{i,1}{10};
        end
        if isempty(S{i,1}{11})
            hdg(i) = 0;
        else
            hdg(i) = S{i,1}{11};
        end
        if isempty(S{i,1}{12})
            vrr(i) = 0;
        else
            vrr(i) = S{i,1}{12};
        end
        
        FL(i) = ((alt(i)*3.2808399)/100);
    end
end

% Convert altitude to flightlevel
FL = round(FL/5)*5;

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
    end
end

% Define structure to store data
D = struct('latitude', [], 'longitude', [], 'flightlevel', [], 'vertical_rate', [], 'velocity', [], 'heading', [], 'callsign', cls, 'ICAO24', [], 'category', []);
for i = 1 : length(lat)
    D(i).latitude = lat(i);
    D(i).longitude = lon(i);
    %D(i).altitude = alt(i);
    D(i).flightlevel = FL(i);
    D(i).vertical_rate = vrr(i);
    D(i).velocity = vel(i);
    D(i).heading = hdg(i);
    D(i).ICAO24 = icao24(i);
    D(i).category = category(i);
end

end
