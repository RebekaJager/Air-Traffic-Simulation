function [D] = estimatePos(D, t)

% ESTIIMATEPOS - Return the predicted future position of aircraft.
%
%   Sytax
%       [D] = ESTIMATEPOS(D, t)
%
%   Input Arguments
%      * D as structure, structure of traffic data
%      * t as double, estimation timeframe [min]
%
%   Output Argument
%      * D as structure, structure of traffic data, with the added fields for
%        estimated position and flight parameters data

n = length(D);
d = zeros(1, n);
% Calculate distance travelled in t
for j = 1 : n
    d(j) = km2deg(((t / 60) * D(j).velocity * 3.6), geocradius(D(j).latitude, 'WGS84') / 1000) * 360;
end

% Horizontal shift - shift WGS84 coordinates with d
x_mov = zeros(n, 1);
y_mov = zeros(n, 1);
for i = 1 : n
    dist = d(i);
    R = deg2rad(D(i).heading);
    if (D(i).heading >= 0) && (D(i).heading <= 90)
        x_mov(i) = (sin(R) * dist) / 360;
        y_mov(i) = (cos(R) * dist) / 360;
    elseif (D(i).heading > 90) && (D(i).heading <= 180)
        x_mov(i) = (cos(R - deg2rad(90)) * dist) / 360;
        y_mov(i) = - (sin(R - deg2rad(90)) * dist) / 360;
    elseif (D(i).heading > 180) && (D(i).heading <= 270)
        x_mov(i) = - (sin(R - deg2rad(180)) * dist) / 360;
        y_mov(i) = - (cos(R - deg2rad(180)) * dist) / 360;
    else
        x_mov(i) = - (cos(R - deg2rad(270)) * dist) / 360;
        y_mov(i) = (sin(R - deg2rad(270)) * dist) / 360;
    end
end
for i = 1 : n
    D(i).latitude_mov = D(i).latitude + y_mov(i);
    D(i).longitude_mov = D(i).longitude + x_mov(i);
end

% Verical shift - change atitude based on verical rate
for i = 1 : n
    if D(i).vertical_rate < 0
        D(i).flightlevel_mov = D(i).flightlevel - 20;
    elseif D(i).vertical_rate > 0
        D(i).flightlevel_mov = D(i).flightlevel + 20;
    else
        D(i).flightlevel_mov = D(i).flightlevel;
    end
end
end