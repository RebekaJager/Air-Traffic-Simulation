function [lamax, lamin, lomax, lomin, bordershp] = areaCalc_OSN(ISO_A2_country_code, t)
% AREACALC_OSN - Get the Shape file of the border of a state given by
%   ISO A2 code, the latitude and longitude limits based on the distance 
%   for ADS-B request based on estimation timeframe.
%   Use for OpenSky Network requests.
%
%   Syntax
%       [lamax, lamin, lomax, lomin, bordershp] = AREACALC_OSN(ISO_A2_country_code, t)
%
%   Input Arguments
%      * ISO_A2_country_code as string, selecting state
%      * t as double, specifying estimation timeframe [min]
%
%   Output Arguments
%      * lamax as double, latitude maximum of the area
%      * lamin as double, latitude minimum of the area
%      * lomax as double, longitude maximum of the area
%      * lomin as double, longitude minimum of the area
%      * bordershp as geopolyshape, shape file for plotting and filtering 
%         aircraft position data


% Load database
addpath('/MATLAB Drive/tesztkornyezet/fileok');
addpath('C:\Users\user\Documents\MATLAB Drive\tesztkornyezet\fileok')
C = readgeotable('countries.geojson');

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

% Get latitude ang longitude data
C2 = geotable2table(C, ["Lat", "Lon"]);
lamax = max(C2.('Lat'){1,1});
lamin = min(C2.('Lat'){1,1});

% Offset distance outside area
d = km2deg(1100*(t/60));

% Area bounds for API request
lamax = lamax + d;
lamin = lamin - d;
lomax = max(C2.('Lon'){1,1}) + d;
lomin = min(C2.('Lon'){1,1}) - d;

end