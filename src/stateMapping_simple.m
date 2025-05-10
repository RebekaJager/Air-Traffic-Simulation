function visual = stateMapping_simple(D, label)
% STATEMAPPING_SIMPLE - Visual representation of traffic data using the
%   default geobasemap. If estimated position is part of the structure, the
%   speed vector will be shown.
%
%   Syntax
%       visual = STATEMAPPING_SIMPLE(D, label)
%
%   Input Arguments
%      * D as structure, structure containing the traffic data
%      * label as boolean, indicates whether labels are displayed 
%        (label = 1) or not (label = 0)
%
%   Output Arguments
%      * visual as figure, mapped visualization of the traffic data


n = length(D);
% Position data
visual = geoscatter([D(:).latitude], [D(:).longitude], "+");
linkdata on
drawnow
hold on

% Option to show data from upper levels
if isfield(D, 'conflict_flag')
    szinek = {"g", "r", "c"};
    for i = 1 : 3
        conf = find([D(:).conflict_flag] == i);
        geoscatter([D(conf).latitude], [D(conf).longitude], 'o', szinek{i});
        hold on
    end
end

% Draw vector based on estimation time frame
if isfield(D, 'latitude_mov')
    for i = 1 : n
        geoplot([D(i).latitude D(i).latitude_mov], [D(i).longitude D(i).longitude_mov], "--b","LineWidth",0.5);
        hold on
    end
    hold off
    shg
end

% Show label
if label == 1
    dx = 0.1;
    dy = 0.1;
    % text([D(:).latitude]+dx, [D(:).longitude]+dy, {D(:).flightlevel}, 'FontSize', 9)
    for i = 1 : n
        text(D(i).latitude+dx, D(i).longitude+dy, sprintf('%s\n%d', D(i).callsign, D(i).flightlevel),'FontSize', 9)
    end
    % dx = dx * 1.6;
    % text([D(:).latitude]+dx, [D(:).longitude]+dy, {D(:).callsign}, 'FontSize', 9)
    shg
end
end