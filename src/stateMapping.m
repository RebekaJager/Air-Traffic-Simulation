function visual = stateMapping(D, label, bordershp)
% STATEMAPPING - Show a visualization of aircraft positions.
%
%   Syntax
%       visual = STATEMAPPING(D, label, bordershp)
%
%   Input Arguments
%      * D as structure, structure containing the traffic data
%      * label as boolean, indicates whether labels are displayed 
%        (label = 1) or not (label = 0)
%      * bordershp as geopolyshape, shape file of the area to be displayed
%
%   Output Arguments
%      * visual as figure, mapped visualization of the traffic data


n = length(D);
% Position data
gx = geoaxes;
clf(gx)
visual = geoscatter(gx, [D(:).latitude], [D(:).longitude], "+");
geolimits(gx, [45.4536073725453, 48.82967575704588], [15.930495130162031, 22.82990894515879]);
gx.Basemap = 'none';
hold (gx, 'on');
geoplot(gx, bordershp, 'FaceColor', 'none');
linkdata on
%drawnow
hold on

% Option to show data from upper levels
if isfield(D, 'conflict_flag')
    szinek = {"g", "r", "c"};
    for i = 1 : 3
        conf = find([D(:).conflict_flag] == i);
        geoscatter(gx, [D(conf).latitude], [D(conf).longitude], 'o', szinek{i});
        hold on
    end
end
% Draw vector based on estimation time frame
if isfield(D, 'latitude_mov')
    for i = 1 : n
        geoplot(gx, [D(i).latitude D(i).latitude_mov], [D(i).longitude D(i).longitude_mov], "--b","LineWidth",0.5);
        hold on
    end
    hold off
    shg
end
drawnow
% Show label
if label == 1
    dx = 0.1;
    dy = 0.1;
    % text([D(:).latitude]+dx, [D(:).longitude]+dy, {D(:).flightlevel}, 'FontSize', 9)
    for i = 1 : n
        text(gx, D(i).latitude+dx, D(i).longitude+dy, sprintf('%s\n%d', D(i).callsign, D(i).flightlevel),'FontSize', 9)
    end
    % dx = dx * 1.6;
    % text([D(:).latitude]+dx, [D(:).longitude]+dy, {D(:).callsign}, 'FontSize', 9)
    shg
end
end