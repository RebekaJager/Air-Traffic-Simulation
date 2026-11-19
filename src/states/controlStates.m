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


    pilot_error_rate = 0.5;
    wrongness = 20;
    dt_sec = 10;

    if nargin == 2
        % defaults
    elseif nargin == 3
        dt_sec = varargin{1};
    elseif nargin == 4
        pilot_error_rate = varargin{1};
        wrongness = varargin{2};
    elseif nargin == 5
        pilot_error_rate = varargin{1};
        wrongness = varargin{2};
        dt_sec = varargin{3};
    else
        error('Incorrect number of input arguments.')
    end

    implementing_idx_fl  = isfield(C, 'flightlevel_atc') && ~all(cellfun(@isempty, {C(:).flightlevel_atc}));
    implementing_idx_hd  = isfield(C, 'heading_atc') && ~all(cellfun(@isempty, {C(:).heading_atc}));
    implementing_idx_vel = isfield(C, 'velocity_atc') && ~all(cellfun(@isempty, {C(:).velocity_atc}));
    implementing_idx_vs  = isfield(C, 'vertical_rate_atc') && ~all(cellfun(@isempty, {C(:).vertical_rate_atc}));

    implementing_idx = zeros(1, length(C));
    for k = 1:length(C)
        if (implementing_idx_hd && ~isempty(C(k).heading_atc)) || ...
           (implementing_idx_fl && ~isempty(C(k).flightlevel_atc)) || ...
           (implementing_idx_vel && ~isempty(C(k).velocity_atc)) || ...
           (implementing_idx_vs && ~isempty(C(k).vertical_rate_atc))
            implementing_idx(k) = 1;
        end
    end

    idx_to_change = find(implementing_idx == 1);
    human_error_nr = round(length(idx_to_change) * (pilot_error_rate / 100));
    idx_to_change_w_error = idx_to_change(randperm(length(idx_to_change), human_error_nr));

    for k = 1 : length(idx_to_change)
        idx = idx_to_change(k);
        has_error = ismember(idx, idx_to_change_w_error);
        error_mult = (1 + (wrongness / 100) * (2 * rand - 1));

        if isfield(C, 'heading_atc') && ~isempty(C(idx).heading_atc)
            C(idx).heading = mod(C(idx).heading_atc * (1 + (has_error * (error_mult - 1))), 360);
        end
        if isfield(C, 'flightlevel_atc') && ~isempty(C(idx).flightlevel_atc)
            C(idx).flightlevel = C(idx).flightlevel_atc * (1 + (has_error * (error_mult - 1)));
        end
        if isfield(C, 'velocity_atc') && ~isempty(C(idx).velocity_atc)
            C(idx).velocity = C(idx).velocity_atc * (1 + (has_error * (error_mult - 1)));
        end
        if isfield(C, 'vertical_rate_atc') && ~isempty(C(idx).vertical_rate_atc)
            C(idx).vertical_rate = C(idx).vertical_rate_atc * (1 + (has_error * (error_mult - 1)));
        end
    end

    calls_D = {D.callsign};
    calls_C = {C.callsign};
    [Lia, Locb] = ismember(calls_D, calls_C);

    idx_D = find(Lia);
    idx_C = Locb(Lia);

    if ~isempty(idx_D)
        hdg_update = {C(idx_C).heading};
        fl_update  = {C(idx_C).flightlevel};
        vel_update = {C(idx_C).velocity};
        vrr_update = {C(idx_C).vertical_rate};

        [D(idx_D).heading]       = hdg_update{:};
        [D(idx_D).flightlevel]   = fl_update{:};
        [D(idx_D).velocity]      = vel_update{:};
        [D(idx_D).vertical_rate] = vrr_update{:};

        fl_array = [C(idx_C).flightlevel];
        alt_update = num2cell(fl_array * 100);
        [D(idx_D).altitude] = alt_update{:};

        % Update simulation-time post-vectoring countdown timers
        if isfield(D, 'resume_timer_sec')
            for m = 1:length(idx_D)
                d_i = idx_D(m);
                c_i = idx_C(m);

                if ~isnan(D(d_i).resume_timer_sec) && D(d_i).resume_timer_sec > 0
                    D(d_i).resume_timer_sec = max(0, D(d_i).resume_timer_sec - dt_sec);
                end

                is_resume   = isfield(C, 'is_resume_req') && ~isempty(C(c_i).is_resume_req) && C(c_i).is_resume_req;
                is_approved = isfield(C, 'ATC_approval') && ~isempty(C(c_i).ATC_approval) && (C(c_i).ATC_approval == 1);
                has_hdg_atc = isfield(C, 'heading_atc') && ~isempty(C(c_i).heading_atc);

                if is_resume
                    if is_approved
                        D(d_i).resume_timer_sec = NaN;
                        if isfield(D, 'was_vectored'), D(d_i).was_vectored = false; end
                    else
                        % Conflict prevented immediate return: retry after 60 simulation seconds
                        D(d_i).resume_timer_sec = 60;
                    end
                elseif has_hdg_atc && ~is_approved
                    % ATC issued a conflict-resolution vector: start/reset 5-min (300 s) simulation timer
                    D(d_i).resume_timer_sec = 300;
                    if isfield(D, 'was_vectored'), D(d_i).was_vectored = true; end
                end
            end
        end
    end
end
