function [C] = controllerActions(C1, varargin)

% CONTROLLERACTIONS - Demo controller algorithm. If a separation infridgement is detected
%   within the look ahead time, a resolution instruction is
%   given.
%
%   Syntax
%       [C] = CONTROLLERACTIONS(C1)
%       [C] = CONTROLLERACTIONS(C1, look_ahead_time)
%
%   Input Arguments
%      * C1 as struct, structure of traffic data to be controlled.
%      * look_ahead_time as double, look-ahead-time of the controller for
%        considering conflicts in minutes. If not specified 2 minutes is
%        the default value.
%
%   Output Arguments
%      * C as struct, structure of traffic data appended with controller
%        instructions.

switch nargin
    case 1
        look_ahead_time = 2;
    case 2
        look_ahead_time = varargin{2};
    otherwise
        error('Incorrect number of input arguments.')
end


C = C1;
for i = 1 : length(C) % accept all pilot requests
    if isfield(C, 'heading_req') && isempty(C(i).heading_req) == 0
        C(i).ATC_approval = 1;
        C(i).heading_atc = C(i).heading_req;
    end
    if isfield(C, 'flightlevel_req') && isempty(C(i).flightlevel_req) == 0
        C(i).ATC_approval = 1;
        C(i).flightlevel_atc = C(i).flightlevel_req;
    end
    if isfield(C, 'velocity_req') && isempty(C(i).velocity_req) == 0
        C(i).ATC_approval = 1;
        C(i).velocity_atc = C(i).velocity_req;
    end
end

for t = 0 : 10/60 : look_ahead_time
    P = estimatePos(C, t);
    for i = 1 : length(P)
        for j = 1 : length(P)
            if i ~= j && P(i).flightlevel == P(j).flightlevel
                d = distance(P(i).latitude_mov, P(i).longitude_mov, P(j).latitude_mov, P(j).longitude_mov, wgs84Ellipsoid('nauticalmile'));
                if d < 5 % flag horizontal conflicts
                    C(i).conflict = 1;
                    C(j).conflict = 1;
                end
                % solve vertical conflicts
            elseif i ~= j && abs(P(i).flightlevel - P(j).flightlevel) < 10
                if P(i).flightlevel > P(j).flightlevel
                    C(i).flightlevel_atc = C(i).flightlevel + 10;
                else
                    C(j).flightlevel_atc = C(j).flightlevel + 10;
                end
            end
        end
    end
    % solve horizontal conflicts
    for i = 1 : length(C)
        if isfield(C, 'conflict')
            if C(i).conflict == 1
                C(i).heading_atc = C(i).heading + 30;
            end
        end
    end

end
end