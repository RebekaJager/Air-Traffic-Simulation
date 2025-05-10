function [D] = shiftPos(D)

% SHIFTPOS - Replace the current positions with the estimated positions.
%
%   Syntax
%       D = SHIFTPOS(D, t)
%
%   Input Arguments
%      * D as structure, structure containing the traffic data
%      * t as double, estimation timeframe [min]
%
%   Output Argument
%      * D as structure, structure of traffic data with the added fields 
%        for estimated position and flight parameters data



n = length(D);
for i = 1 : n
    D(i).latitude = D(i).latitude_mov;
    D(i).longitude = D(i).longitude_mov;
    D(i).flightlevel = D(i).flightlevel_mov;
end
end