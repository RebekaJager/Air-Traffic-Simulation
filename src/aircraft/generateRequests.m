function [C1] = generateRequests(D, varargin)

% GENERATEREQUESTS - Generate randomized pilot requests. The exact value of
%   requested change is randomized within a specified range. The changed
%   flight parameter and the sign of change is randomly selected.
% 
%   Syntax
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

% Input fallback just in case 'ac' is passed as 5 instead of 0.05
if ac > 1
    ac = ac / 100;
end

C1 = D([D(:).inside] == 1); % A/C inside sector
n_ac = length(C1);

if n_ac == 0
    return; % Early exit if no aircraft in sector
end

n = round(ac * n_ac);  % number of A/C making request
% BUG FIX: use length(C1) instead of length(D) to prevent out-of-bounds indexing
req = randperm(n_ac, n); % requesting aircraft indices

for i = 1 : n
    idx = req(i); % Sequential read from the already shuffled index array
    req_type = rand();
    
    if req_type < 0.3333   % new heading
        delta_hdg = heading_change(randi(length(heading_change)));
        % BUG FIX: randomly assign turning direction (+ or -)
        if rand() < 0.5
            delta_hdg = -delta_hdg;
        end
        % BUG FIX: Keep heading between 0-360 degrees
        C1(idx).heading_req = mod(C1(idx).heading + delta_hdg, 360);
        
    elseif req_type < 0.6666   % new flightlevel
        delta_fl = flightlevel_change(randi(length(flightlevel_change)));
        new_fl_plus = C1(idx).flightlevel + delta_fl;
        new_fl_minus = C1(idx).flightlevel - delta_fl;
        
        valid_plus = (new_fl_plus >= 120 && new_fl_plus <= 400);
        valid_minus = (new_fl_minus >= 120 && new_fl_minus <= 400);
        
        % BUG FIX: Safe flight level validation preventing out-of-bounds FL assignments
        if valid_plus && valid_minus
            if rand() <= 0.5
                C1(idx).flightlevel_req = new_fl_plus;
            else
                C1(idx).flightlevel_req = new_fl_minus;
            end
        elseif valid_plus
            C1(idx).flightlevel_req = new_fl_plus;
        elseif valid_minus
            C1(idx).flightlevel_req = new_fl_minus;
        end
        % If neither is valid, no valid request can be made, keep it unchanged.
        
    else    % new speed
        % BUG FIX: Divide percentage by 100
        delta_vel_percent = speed_change(randi(length(speed_change))) / 100;
        delta_vel = C1(idx).velocity * delta_vel_percent;
        
        if rand() < 0.5
            C1(idx).velocity_req = C1(idx).velocity + delta_vel;
        else
            % Safeguard to prevent negative speeds
            C1(idx).velocity_req = max(0, C1(idx).velocity - delta_vel);
        end
    end
end
end
