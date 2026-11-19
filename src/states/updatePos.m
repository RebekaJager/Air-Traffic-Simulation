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

icao_inside    = {D_inside.ICAO24};
icao_refreshed = {D_refreshed.ICAO24};

to_update   = ~ismember(icao_refreshed, icao_inside);
D_refreshed = D_refreshed(to_update);

if isempty(D_inside)
    D = D_refreshed;
    return;
end
if isempty(D_refreshed)
    D = D_inside;
    return;
end

% Preserve extra tracking fields present in D_inside
missing_in_ref = setdiff(fieldnames(D_inside), fieldnames(D_refreshed));
for f = 1:length(missing_in_ref)
    fn = missing_in_ref{f};
    if islogical(D_inside(1).(fn))
        [D_refreshed.(fn)] = deal(false);
    elseif isnumeric(D_inside(1).(fn))
        [D_refreshed.(fn)] = deal(NaN);
    else
        [D_refreshed.(fn)] = deal([]);
    end
end

missing_in_ins = setdiff(fieldnames(D_refreshed), fieldnames(D_inside));
for f = 1:length(missing_in_ins)
    fn = missing_in_ins{f};
    [D_inside.(fn)] = deal([]);
end

D = [D_inside; D_refreshed];
end
