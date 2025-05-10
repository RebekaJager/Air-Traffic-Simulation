function [D] = controlStates(D, C, varargin)

% CONTROLSTATES - Return structure of controlled traffic.
%
%   Syntax
%       [D] = CONTROLSTATES(D, C) Use default parameters for pilot error rate
%        (0.5%) and wrongness (20%).
%       [D] = CONTROLSTATES(D, C, pilot_error_rate, wrongness) User defined pilot
%        error rate and wrongness.
%
%   Input Arguments
%      * D as structure, structure of traffic data.
%      * C as structure, structure of traffic data appended with controller intention
%      * pilot_error_rate as double, the error rate of pilots in implementing ATC
%         actions as a percentage.
%      * wrongness as double, percentage showing how wrongly are pilot error
%         implementations deviate from correct implementation. Eg. 20% deviation
%         results in heading of 120 degrees instead of 100 degrees. Increase or
%         decrease is assigned randomly. If multiple parameters are requested by
%         ATC than all of them are mistaken.
%
%   Output Argument
%      * D as structure, structure of traffic data, changed according to ATC
%         instruction and moved accoring to step time.

if nargin == 2
    pilot_error_rate = 0.5;
    wrongness = 20;
elseif nargin == 4
    pilot_error_rate = varargin{3};
    wrongness = varargin{4};
else
    error('Incorrect number of input arguments.')
end
% mark those aircraft that have an ATC instruction
if isfield(C, 'flightlevel_atc')
    implementing_idx_fl = ~cellfun(@isempty, {C(:).flightlevel_atc});
else
    implementing_idx_fl = zeros(1, length(C));
end
if isfield(C, 'heading_atc')
    implementing_idx_hd = ~cellfun(@isempty, {C(:).heading_atc});
else
    implementing_idx_hd = zeros(1, length(C));
end
if isfield(C, 'velocity_atc')
    implementing_idx_vel = ~cellfun(@isempty, {C(:).velocity_atc});
else
    implementing_idx_vel = zeros(1, length(C));
end
implementing_idx = implementing_idx_hd | implementing_idx_fl | implementing_idx_vel;
implementing_nr = sum(implementing_idx);
human_error_nr = round(implementing_nr*(pilot_error_rate / 100));

idx_to_change = find(implementing_idx == 1);
idx_to_change_w_error = idx_to_change(randperm(length(idx_to_change), human_error_nr));

for i = 1 : length(idx_to_change)
    if isfield(C, 'heading_atc') && isempty(C(i).heading_atc) == 0
        if ismember(idx_to_change(i), idx_to_change_w_error)
            C(i).heading = C(i).heading_atc * (1 + (wrongness / 100) * (2 * rand - 1));
        else
            C(i).heading = C(i).heading_atc;
        end
    end
    if isfield(C, 'flightlevel_atc') && isempty(C(i).flightlevel_atc) == 0
        if ismember(idx_to_change(i), idx_to_change_w_error)
            C(i).flightlevel = C(i).flightlevel_atc * (1 + (wrongness / 100) * (2 * rand - 1));
        else
            C(i).flightlevel = C(i).flightlevel_atc;
        end
    end
    if isfield(C, 'velocity_atc') && isempty(C(i).velocity_atc) == 0
        if ismember(idx_to_change(i), idx_to_change_w_error)
            C(i).velocity = C(i).velocity_atc * (1 + (wrongness / 100) * (2 * rand - 1));
        else
            C(i).velocity = C(i).velocity_atc;
        end
    end
end

% update positions in D from C
for i = 1 : length(D)
    for j = 1 : length(C)
        if strcmp(D(i).callsign, C(j).callsign)
            D(i).heading = C(j).heading;
            D(i).flightlevel = C(j).flightlevel;
            break;
        end
    end
end
end