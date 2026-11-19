function D = assignExitTargets(D, bordershp)
% ASSIGNEXITTARGETS - Records a fixed exit waypoint just beyond the airspace
%   border when an aircraft enters controlled airspace, assuming straight-line
%   constant-velocity flight.
%
%   Syntax
%       D = ASSIGNEXITTARGETS(D, bordershp)

if isempty(D)
    return;
end

% Initialize tracking fields if not yet present on the traffic struct
if ~isfield(D, 'target_lat'),       [D.target_lat]       = deal(NaN);   end
if ~isfield(D, 'target_lon'),       [D.target_lon]       = deal(NaN);   end
if ~isfield(D, 'resume_timer_sec'), [D.resume_timer_sec] = deal(NaN);   end
if ~isfield(D, 'was_vectored'),     [D.was_vectored]     = deal(false); end

for k = 1:length(D)
    if D(k).inside == 1 && isnan(D(k).target_lat)
        v_ms = D(k).velocity;
        hdg  = D(k).heading;

        % Fallback if ground speed is missing or near-zero: 100 NM along heading
        if v_ms <= 10
            [lat_exit, lon_exit] = reckon(D(k).latitude, D(k).longitude, km2deg(185.2), hdg);
            D(k).target_lat = lat_exit;
            D(k).target_lon = lon_exit;
            continue;
        end

        % Project straight-line constant-velocity trajectory in 1-min steps (up to 60 min)
        t_steps = (1:60)';
        dist_km = v_ms .* (t_steps * 60) ./ 1000;
        [lat_ray, lon_ray] = reckon(D(k).latitude, D(k).longitude, km2deg(dist_km), hdg);
        in_hu = isinterior(bordershp, geopointshape(lat_ray, lon_ray));

        exit_idx = find(~in_hu, 1, 'first');
        if ~isempty(exit_idx)
            % Fix target coordinate 1 step (~1 min / ~7-8 NM) beyond the border exit
            target_idx = min(exit_idx + 1, length(lat_ray));
            D(k).target_lat = lat_ray(target_idx);
            D(k).target_lon = lon_ray(target_idx);
        else
            D(k).target_lat = lat_ray(end);
            D(k).target_lon = lon_ray(end);
        end
    end
end
end
