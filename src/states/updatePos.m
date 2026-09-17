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
    
    if ~isfield(D_refreshed, 'inside')
        error('The inside field is needed in D_refreshed.');
    end
    
    D_inside = D([D(:).inside] == 1);
    
    icao_inside = {D_inside.ICAO24};
    icao_refreshed = {D_refreshed.ICAO24};
    
    to_update = ~ismember(icao_refreshed, icao_inside);
    D_refreshed = D_refreshed(to_update);
    
    Fields = intersect(fieldnames(D_refreshed), fieldnames(D_inside));
    
    D_inside_connect = rmfield(D_inside, setdiff(fieldnames(D_inside), Fields));
    D_refreshed_connect = rmfield(D_refreshed, setdiff(fieldnames(D_refreshed), Fields));
    
    D = [D_inside_connect; D_refreshed_connect];
end
