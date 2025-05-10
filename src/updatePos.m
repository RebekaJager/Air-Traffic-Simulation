function [D] = updatePos(D, D_refreshed)
% UPDATEPOS - Update position data of aircraft outside of the sector.
% 
%   Syntax
%       [D] = UPDATEPOS(D, D2)
% 
%   Input Arguments
%      * D as structure, structure of traffic data, where positions flaged
%         as outside are to be updated
%      * D_refreshed as strucute, structure of traffic data containing the refreshed
%         traffic. Note that the inside field is needed. (See getInside
%         function.)
% 
%   Output Arguments
%      * D as structure, structure of traffic data, where positions flaged
%         as outside are to be updated from D2.

if isfield(D_refreshed, 'inside') == 0
    error('The inside field is needed in D_refreshed.')
end

D_inside = D([D(:).inside] == 1);

for i = length(D_refreshed) : -1 : 1
     idx = find(strcmp({D_inside(:).ICAO24}, D_refreshed(i).ICAO24));
     if isempty(idx)
        D_refreshed(i).update = 1;
     else
         D_refreshed(i).update = 0;
     end
end
D_refreshed = D_refreshed([D_refreshed(:).update] == 1);
D_refreshed = rmfield(D_refreshed, 'update');

Fields = intersect(fieldnames(D_refreshed), fieldnames(D_inside));


D_inside_connect = rmfield(D_inside, setdiff(fieldnames(D_inside), Fields));
D_refreshed_connect = rmfield(D_refreshed, setdiff(fieldnames(D_refreshed), Fields));

D = [D_inside_connect; D_refreshed_connect];

end