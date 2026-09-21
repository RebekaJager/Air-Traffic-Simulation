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
if n == 0
    visual = []; 
    return; 
end

gx = geoaxes;
clf(gx)
visual = geoscatter(gx, [D(:).latitude], [D(:).longitude], "+");
geolimits(gx, [45.4536073725453, 48.82967575704588], [15.930495130162031, 22.82990894515879]);
gx.Basemap = 'none';
hold(gx, 'on');
geoplot(gx, bordershp, 'FaceColor', 'none');

% Option to show data from upper levels
if isfield(D, 'conflict_flag')
    szinek = {"g", "r", "c"};
    for i = 1 : 3
        conf = [D(:).conflict_flag] == i;
        if any(conf)
            geoscatter(gx, [D(conf).latitude], [D(conf).longitude], 'o', szinek{i});
        end
    end
end

% Draw vector based on estimation time frame (Vectorized for extreme speedup)
if isfield(D, 'latitude_mov')
    lat_lines = [[D.latitude]; [D.latitude_mov]; NaN(1, n)];
    lon_lines = [[D.longitude]; [D.longitude_mov]; NaN(1, n)];
    geoplot(gx, lat_lines(:), lon_lines(:), "--b", "LineWidth", 0.5);
end

% Show label (Vectorized text plotting)
if label == 1
    dx = 0.1;
    dy = 0.1;
    str_labels = arrayfun(@(x) sprintf('%s\n%d', x.callsign, x.flightlevel), D, 'UniformOutput', false);
    text(gx, [D.latitude] + dx, [D.longitude] + dy, str_labels, 'FontSize', 9);
end

hold(gx, 'off');
drawnow;
end
