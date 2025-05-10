function [D] = getInside(D, bordershp)

% GETINSIDE - Mark aircraft inside (inside = 1) and outside (inside = 0) of
%   given border.
%
%   Syntax
%       [D] = GETINSIDE(D, bordershp)
% 
%   Input Arguments
%       * D as structure, structure of traffic data
%       * bordershp as geopolyshape, shape file of area, with the added field for
%          marking aircraft inside the area
% 
%   Output Arguments
%       * D as structure, structure of traffic data

n = length(D);

A_C = geopointshape([D(:).latitude], [D(:).longitude]);
MO = isinterior(bordershp, A_C);
for i = n : -1 : 1
    if MO(i) == 0
        D(i).inside = 0;
    else
        D(i).inside = 1;
    end
end

end