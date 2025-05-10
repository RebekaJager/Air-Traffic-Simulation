function [lat, lon, d, bordershp, areashp] = areaCalc(ISO_A2_country_code, t)

% AREACALC - Get the Shape file of the border of a state given by
%   ISO A2 code, the geographical middle point of the state and the distance 
%   for ADS-B request based on estimation timeframe. 
%   Use for ADS-B Exchange v2 requests.
% 
%   Syntax
%       [lat, lon, d, bordershp] = AREACALC('ISO_A2_country_code', t)
%
%   Input Arguments
%      * ISAO_A2_country_code as string, selecting state
%      * t as double, specifying estimation timeframe [min]
%
%   Output Arguments
%      * lat as double, latitude of middle point
%      * lon as double, longitude of middle point
%      * d as double, distance for ADS-B API request, based on estimation
%        timeframe [NM]
%      * bordershp as geopolyshape, shape file of the sector border for 
%         plotting and filering aircraft position data
%      * areashp as geopolyshare, shape file of larger surrinding area
%         (based on the center point and distance calculated) fo filtering
%         aircraft position data.


% Load database
scriptDir = fileparts(mfilename('fullpath'));
dataPath = fullfile(scriptDir, '..', 'data', 'countries.geojson');

C = readgeotable(dataPath);

% Check input
isocode = ISO_A2_country_code;
while sum(C.ISO_A2 == isocode) ~= 1
    error('Not ISO A2 country code');
end
% Show country name
disp(C.ADMIN(C.ISO_A2 == isocode))
% Overwite database
C = C(C.ISO_A2 == isocode, :);
% Output shape file
bordershp = C.Shape;

% Get latitude and longitude data
C2 = geotable2table(C, ["Lat", "Lon"]);

lamax = max(C2.('Lat'){1,1});
lamin = min(C2.('Lat'){1,1});
lomax = max(C2.('Lon'){1,1});
lomin = min(C2.('Lon'){1,1});

lat = (lamax + lamin) / 2;
lon = (lomax + lomin) / 2;

% Offset distance for outside area (assuming the speed of 1100 km/h to
% avoid handling too much data and discarding arriving aircraft)
d = 1100*(t/60) / 1.852;

% Calculate shape file of area
num_points = 360; % resolution for circumference
az = linspace(0, 360, num_points);
[lat_circle, lon_circe] = reckon(lat, lon, km2deg(d * 1.852), az);
areashp = geopolyshape(lat_circle, lon_circe);
end