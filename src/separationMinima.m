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

n= 0;
switch nargin
    case 1
        horizontal = 5;
        vertical = 10;
    case 3
        horizontal = varargin{2};
        vertical = varargin{3}/100;
    otherwise
        error('Incorrect number of input arguments.')
end


for i = 1 : length(D)
    for j = 1 : length(D)
        if i ~= j && D(i).flightlevel == D(j).flightlevel
            d = distance(D(i).latitude, D(i).longitude, D(j).latitude, D(j).longitude, wgs84Ellipsoid('nauticalmile'));
        % flag horizontal conflicts
            if d < horizontal 
                D(i).conflict = 1;
                D(j).conflict = 1;
            end
        % flag vertical conflicts
        elseif i ~= j && abs(D(i).flightlevel - D(j).flightlevel) < vertical
            D(i).conflict = 1;
            D(j).conflict = 1;
        end
    end
end
if isfield(D, 'conflict')
    n = sum([D(:).conflict]);
end
end