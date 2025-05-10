function [C1] = generateRequests(D, varargin)

% GENERATEREQUESTS - Generate randomized pilot requests. The exact value of
%   requested change is randomized within a specified range. The changed
%   flight parameter and the sign of change is randomly selected.
% 
%   Sytax
%       [C1] = GENERATEREQUESTS(D) Use default parameters for request rate and
%        request ranges.
%       [C1] = GENERATEREQUESTS(D, ac) User defined request rate and default
%        request ranges.
%       [C1] = GENERATEREQUESTS(D, ac, heading_change, flightlevel_change,
%        speed_change) User defined request rate and request ranges.
% 
%   Input Arguments
%      * D as structure, structure of traffic data
%         ac as double, precentage of aircraft that make a request. Deafault value
%         is 5%. Input as the percent value.
%         heading_change as double, vector containing possible values for
%         requested change in heading. Deafult value is heading_change = [10, 20,
%         30, 40, 50, 60, 70, 80, 90].
%      * flighlevel_change as double, vector containing possible values for
%         requested change in flight level. Default value is flightlevel_change =
%         [10 20 30 40 50 60 70 80 90 100].
%      * speed_change as double, vector containing possible percentage values for
%         requested change in speed. Default value is speed_change = [5, 10, 20,
%         30, 40].
% 
%   Output Argument
%      * C1 as structure, structure of traffic data apended with pilot requests.

switch nargin
    case 1 % use default parameters for request rate and request range
        ac = 5/100;
        heading_change = [10, 20, 30, 40, 50, 60, 70, 80, 90]; % degrees
        flightlevel_change = [10 20 30 40 50 60 70 80 90 100]; % flight levels
        speed_change = [5, 10, 20, 30, 40]; %precentages
    case 2 % user defined request rate and default request range
        ac = varargin{1};
        heading_change = [10, 20, 30, 40, 50, 60, 70, 80, 90]; % degrees
        flightlevel_change = [10 20 30 40 50 60 70 80 90 100]; % flight levels
        speed_change = [5, 10, 20, 30, 40]; %precentages
    case 5 % user defined request rate and request range
        ac = varargin{1};
        heading_change = varargin{2}; % degrees
        flightlevel_change = varargin{3}; % flight levels
        speed_change = varargin{4}; %precentages
    otherwise
        error('Incorect number of input  arguments.')
end

C1 = D([D(:).inside] == 1); % A/C inside sector
n = round(ac*length(C1));  % number of A/C making request
req = randperm(length(D), n); % requesting aircraft
for i = 1 : length(req)
    j = rand();
    random_idx = randi(length(req)); % store index of req separately for deletion
    idx = req(random_idx); % select random A/C from all requests
    if j < 0.3333   % new heading
        C1(idx).heading_req = D(idx).heading + heading_change(randi(length(heading_change)));
    elseif j < 0.6666   % new flightlevel
        delta_fl = flightlevel_change(randi(length(flightlevel_change)));
        new_fl_plus = D(idx).flightlevel + delta_fl;
        new_fl_minus = D(idx).flightlevel - delta_fl;
        k = rand();
        if k <= 0.5
            new_fl_1 = new_fl_plus;
            new_fl_2 = new_fl_minus;
        else
            new_fl_1 = new_fl_minus;
            new_fl_2 = new_fl_plus;
        end
        if new_fl_1 >= 120 && new_fl_1 <= 400
            C1(idx).flightlevel_req = new_fl_1;
        else
            C1(idx).flightlevel_req = new_fl_2;
        end
    else    % new speed
        delta_vel = D(idx).velocity * speed_change(randi(length(speed_change)));
        if rand < 0.5
            C1(idx).velocity_req = D(idx).velocity + delta_vel;
        else
            C1(idx).velocity_req = D(idx).velocity - delta_vel;
        end
    end
    req(random_idx) = [];
end
