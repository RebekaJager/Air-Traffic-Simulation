%% init.m
% Run this once before using any scripts or functions in the project.

% init.m lives in src/, so project root is one level up
srcRoot = fileparts(which('init.m'));
projectRoot = fileparts(srcRoot);  % step up to traffic simulation/

% Add all subfolders recursively to the MATLAB path
addpath(genpath(srcRoot));     % adds all src/ subfolders
addpath(genpath(fullfile(projectRoot, 'data')));    % adds data/
addpath(genpath(fullfile(projectRoot, 'own')));     % adds own/
addpath(genpath(fullfile(projectRoot, 'results'))); % adds results/

% Store correct project root
setenv('PROJECT_ROOT', projectRoot);

fprintf('Project root: %s\n', projectRoot);
fprintf('All subfolders added to path.\n');
