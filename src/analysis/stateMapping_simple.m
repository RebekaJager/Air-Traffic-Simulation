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
if n == 0
    visual = [];
    return;
end

% Position data
visual = geoscatter([D(:).latitude], [D(:).longitude], "+");
hold on;

% Option to show data from upper levels
if isfield(D, 'conflict_flag')
    szinek = {"g", "r", "c"};
    for i = 1 : 3
        conf = [D(:).conflict_flag] == i;
        if any(conf)
            geoscatter([D(conf).latitude], [D(conf).longitude], 'o', szinek{i});
        end
    end
end

% Draw vector based on estimation time frame (Vectorized for extreme speedup)
if isfield(D, 'latitude_mov')
    lat_lines = [[D.latitude]; [D.latitude_mov]; NaN(1, n)];
    lon_lines = [[D.longitude]; [D.longitude_mov]; NaN(1, n)];
    geoplot(lat_lines(:), lon_lines(:), "--b", "LineWidth", 0.5);
end

% Show label (Vectorized text plotting)
if label == 1
    dx = 0.1;
    dy = 0.1;
    str_labels = arrayfun(@(x) sprintf('%s\n%d', x.callsign, x.flightlevel), D, 'UniformOutput', false);
    text([D.latitude] + dx, [D.longitude] + dy, str_labels, 'FontSize', 9);
end

hold off;
drawnow;
end
