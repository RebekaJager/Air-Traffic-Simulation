%% Elementary Sector Builder
% Generate data file for elementary sectors

clear; clc; close all;

% Load border file of given state
[~, ~, ~, bordershp, ~] = areaCalc('HU', 0);

% Convert coordinates to decmal degrees
dms2deg = @(d, m, s) d + m/60 + s/3600;

% Sector coordinates
% Note: ACC BUDAPEST is used. Access sector coordinates from relevant
% AIP.
lat_pts_west = [
    dms2deg(48, 0, 24)
    dms2deg(47, 42, 27)
    dms2deg(47, 32, 44)
    dms2deg(46, 59, 52)
    dms2deg(46, 50, 46)
    46.6                    % fictitious point for intersecting shapes
    dms2deg(46, 29, 1)
    dms2deg(47, 20, 44)
    dms2deg(47, 44, 13)
    dms2deg(47, 44, 11.95)
    48.2                    % fictitious point for intersecting shapes
    ];

lon_pts_west = [
    dms2deg(17, 9, 39)
    dms2deg(17, 5, 0)
    dms2deg(16, 42, 14)
    dms2deg(16, 13, 29)
    dms2deg(16, 20, 19)
    16.1                    % fictitious point for intersecting shapes
    dms2deg(16, 33, 58)
    dms2deg(18, 43, 13)
    dms2deg(18, 19, 48)
    dms2deg(18, 19, 43.5)
    17.5
    ];

raw_shape_west = geopolyshape(lat_pts_west, lon_pts_west);
shape_west = intersect(raw_shape_west, bordershp);

lat_pts_south = [
    dms2deg(46, 29, 1)
    45.0                    % fictitious point
    dms2deg(45, 55, 15)
    45.0                    % fictitious point
    dms2deg(46, 9, 0)       
    dms2deg(46, 9, 0)       
    dms2deg(46, 9, 4)       
    dms2deg(47, 20, 44)     
    dms2deg(46, 29, 1)
    ];
lon_pts_south = [
    dms2deg(16, 33, 58)     
    17.0                    % fictitious point
    dms2deg(18, 53, 24)     
    20.0                    % fictitious point
    dms2deg(19, 51, 26)     
    dms2deg(19, 52, 12)     
    dms2deg(19, 52, 12)     
    dms2deg(18, 43, 13)     
    dms2deg(16, 33, 58)
    ];

raw_shape_south = geopolyshape(lat_pts_south, lon_pts_south);
shape_south = intersect(raw_shape_south, bordershp);

lat_pts_east = [
    dms2deg(47, 44, 13)
    dms2deg(47, 20, 44)     
    dms2deg(46, 9, 4)       
    dms2deg(46, 9, 0)       
    dms2deg(46, 9, 6)
    45.0                    % fictitious point
    dms2deg(46, 7, 2)
    46.0                    % fictitious point
    dms2deg(47, 0, 8)       
    dms2deg(47, 0, 53)      
    dms2deg(48, 10, 29)     
    dms2deg(48, 10, 28.64)
    49.0                    % fictitious point
    dms2deg(47, 44, 13)
    ];
lon_pts_east = [
    dms2deg(18, 19, 48)     
    dms2deg(18, 43, 13)     
    dms2deg(19, 52, 12)     
    dms2deg(19, 52, 12)     
    dms2deg(19, 52, 27)     
    21.0                    % fictitious point
    dms2deg(20, 16, 2)      
    23.5                    % fictitious point
    dms2deg(21, 41, 41)     
    dms2deg(21, 40, 37)     
    dms2deg(20, 3, 25)      
    dms2deg(20, 3, 23)      
    19.0                    % fictitious point
    dms2deg(18, 19, 48)
    ];

raw_shape_east = geopolyshape(lat_pts_east, lon_pts_east);
shape_east = intersect(raw_shape_east, bordershp);

lat_pts_north = [
    dms2deg(48, 10, 29)
    dms2deg(47, 0, 53)
    dms2deg(47, 0, 8)
    47.0                    % fictitious point
    dms2deg(47, 57, 33)
    48.5                    % fictitious point
    dms2deg(48, 24, 11.92)
    49.0                    % fictitious point
    dms2deg(48, 10, 29)
    ];
lon_pts_north = [
    dms2deg(20, 3, 25)      
    dms2deg(21, 40, 37)     
    dms2deg(21, 41, 41)     
    23.5                    % fictitious point
    dms2deg(22, 54, 22)     
    23.5                    % fictitious point
    dms2deg(22, 9, 19.33)   
    20.5                    % fictitious point
    dms2deg(20, 3, 25)
    ];

raw_shape_north = geopolyshape(lat_pts_north, lon_pts_north);
shape_north = intersect(raw_shape_north, bordershp);

% Add vertical limits

% Common vertical limits for all areas (0-9)
fl_limits = [95, 305; 305, 315; 315, 325; 325, 335; 335, 345; 
    345, 355; 355, 365; 365, 375; 375, 385; 385, 660];

ElementarySectors = struct('ID', {}, 'Name', {}, 'LowerFL', {}, 'UpperFL', {}, 'Shape', {});
idx = 1;

% West
for i = 1:10
    ElementarySectors(idx).ID = sprintf('LHCCW%d', i-1);
    ElementarySectors(idx).Name = sprintf('WEST %d', i-1);
    ElementarySectors(idx).LowerFL = fl_limits(i, 1);
    ElementarySectors(idx).UpperFL = fl_limits(i, 2);
    ElementarySectors(idx).Shape = shape_west; % 2D extensions are the same for all elementary sectors
    idx = idx + 1;
end
% South
for i = 1:10
    ElementarySectors(idx).ID = sprintf('LHCCS%d', i-1);
    ElementarySectors(idx).Name = sprintf('SOUTH %d', i-1);
    ElementarySectors(idx).LowerFL = fl_limits(i, 1);
    ElementarySectors(idx).UpperFL = fl_limits(i, 2);
    ElementarySectors(idx).Shape = shape_south;
    idx = idx + 1;
end
% East
for i = 1:10
    ElementarySectors(idx).ID = sprintf('LHCCE%d', i-1);
    ElementarySectors(idx).Name = sprintf('EAST %d', i-1);
    ElementarySectors(idx).LowerFL = fl_limits(i, 1);
    ElementarySectors(idx).UpperFL = fl_limits(i, 2);
    ElementarySectors(idx).Shape = shape_east;
    idx = idx + 1;
end
% North
for i = 1:10
    ElementarySectors(idx).ID = sprintf('LHCCN%d', i-1);
    ElementarySectors(idx).Name = sprintf('NORTH %d', i-1);
    ElementarySectors(idx).LowerFL = fl_limits(i, 1);
    ElementarySectors(idx).UpperFL = fl_limits(i, 2);
    ElementarySectors(idx).Shape = shape_north;
    idx = idx + 1;
end


%  visual check
gx = geoaxes;
geolimits(gx, [44.5, 49.5], [14.5, 24.0]); 
gx.Basemap = 'streets-light'; 
hold(gx, 'on');

% raw (uncut) shapes
geoplot(gx, raw_shape_west, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.5, 'FaceColor', 'none', 'DisplayName', 'Uncut Geometry');
geoplot(gx, raw_shape_south, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.5, 'FaceColor', 'none', 'HandleVisibility', 'off');
geoplot(gx, raw_shape_east, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.5, 'FaceColor', 'none', 'HandleVisibility', 'off');
geoplot(gx, raw_shape_north, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.5, 'FaceColor', 'none', 'HandleVisibility', 'off');

% national border
geoplot(gx, bordershp, 'EdgeColor', 'k', 'LineWidth', 2.5, 'FaceColor', 'none', 'DisplayName', 'FIR Border');

% cut sectors
geoplot(gx, shape_west, 'FaceColor', '#0072BD', 'FaceAlpha', 0.4, 'EdgeColor', '#0072BD', 'LineWidth', 1, 'DisplayName', 'WEST (Cut)');
geoplot(gx, shape_south, 'FaceColor', '#D95319', 'FaceAlpha', 0.4, 'EdgeColor', '#D95319', 'LineWidth', 1, 'DisplayName', 'SOUTH (Cut)');
geoplot(gx, shape_east, 'FaceColor', '#77AC30', 'FaceAlpha', 0.4, 'EdgeColor', '#77AC30', 'LineWidth', 1, 'DisplayName', 'EAST (Cut)');
geoplot(gx, shape_north, 'FaceColor', '#EDB120', 'FaceAlpha', 0.4, 'EdgeColor', '#EDB120', 'LineWidth', 1, 'DisplayName', 'NORTH (Cut)');

title(gx, 'Elementary Sector Geographical Verification');
legend(gx, 'Location', 'northeast');
hold(gx, 'off');

%% Save

save_path = fullfile(getenv('PROJECT_ROOT'), 'data', 'elementary_sectors.mat');
save(save_path, 'ElementarySectors');
fprintf('Successfully saved %d elementary sectors to: %s\n', length(ElementarySectors), save_path);
