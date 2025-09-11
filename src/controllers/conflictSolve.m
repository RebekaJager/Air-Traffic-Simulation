function C = conflictSolve(CM, C)


if size(CM, 1) ~= size(C, 1)
    error('Dimension mismatch: traffic data is %s, conflict matrix is %s.', ...
       mat2str(size(C)), mat2str(size(CM)))
end
n = length(C);
for i = 1 : n
    for j = 1 : n
    if isfield(C, 'heading_req') && isempty(C(i).heading_req) == 0
        C1 = C;
        C1(i).heading = C1(i).heading_req;
            CM1 = conflictDetect(C1, 10);
            if (sum(CM1(i, :)) == sum(CM(i, :)) - 1)
                % no new conlfict created
                C(i).ATC_approval = 1;
                C(i).heading_atc = C(i).heading_req;
            end
    end
    if isfield(C, 'flightlevel_req') && isempty(C(i).flightlevel_req) == 0
        C1 = C;
        C1(i).flightlevel = C1(i).flightlevel_req;
            CM1 = conflictDetect(C1, 10);
            if (sum(CM1(i, :)) == sum(CM(i, :)) - 1)
                % no new conlfict created
                C(i).ATC_approval = 1;
                C(i).flightlevel_atc = C(i).flightlevel_req;
            end
    end
    if isfield(C, 'velocity_req') && isempty(C(i).velocity_req) == 0
        C1 = C;
        C1(i).velocity = C1(i).velocity_req;
            CM1 = conflictDetect(C1, 10);
            if (sum(CM1(i, :)) == sum(CM(i, :)) - 1)
                % no new conlfict created
                C(i).ATC_approval = 1;
                C(i).velocity_atc = C(i).velocity_req;
            end
    end
    if isfield(C, 'vertical_rate_req') && isempty(C(i).velocity_req) == 0
        C1 = C;
        C1(i).vertical_rate = C1(i).vertical_rate_req;
            CM1 = conflictDetect(C1, 10);
            if (sum(CM1(i, :)) == (sum(CM(i, :))) - 1)
                % no new conlfict created
                C(i).ATC_approval = 1;
                C(i).vertical_rate_atc = C(i).vertical_rate_req;
            end
    end
        if CM(i, j) == 1 % crossing conflict
            % check is descending lower aircraft creates new conflict
            C1 = C;
            idxs = [i j];
            [~, idx] = min([C1(i).flightlevel C1(j).flightlevel]);
            C1(idxs(idx)).flightlevel = C1(idxs(idx)).flightlevel - 20;
            CM1 = conflictDetect(C1, 5);
            if (sum(CM1(i, :)) == sum(CM(i, :))) && (sum(CM1(j, :)) == sum(CM(j, :)))
                % no new conlfict created
                C1(idxs(idx)).flightlevel_atc = C1(idxs(idx)).flightlevel - 20;
                continue
            end
            % check is climbing higher aircraft creates new conflict
            C1 = C;
            C1(idxs(3 - idx)).flightlevel = C1(idxs(idx)).flightlevel + 20;
            CM1 = conflictDetect(C1, 5);
            if (sum(CM1(i, :)) == sum(CM(i, :))) && (sum(CM1(j, :)) == sum(CM(j, :)))
                % no new conlfict created
                C1(idxs(idx)).flightlevel_atc = C1(idxs(idx)).flightlevel + 20;
                continue
            end
            % vectoring
            [delta_deg, s] = min_heading_change_toward_faster(...
                                            [C(i).latitude C(i).longitude], ...
                                            [C(j).latitude C(j).longitude], ...
                                             C(i).velocity, C(j).velocity, ...
                                             C(i).heading, C(j).heading, ...
                                             5/1.852);
            if ~isnan(delta_deg)
                C(idxs(s.slow_id)).heading_atc = C(idxs(s.slow_id)).heading + s.turn_direction_sign * delta_deg;
            end
        elseif CM(i) == 2
                dec = choose_min_vs_change(...
                    C(i).latitude, C(i).longitude, ...
                    C(i).velocity, C(i).heading, ...
                    C(i).altitude, C(i).vertical_rate, ...
                    C(j).latitude, C(j).longitude, ...
                    C(j).velocity, C(j).heading, ...
                    C(j).altitude, C(j).vertical_rate);
                    idxs = [i, j];
                if dec.which_aircraft == 1
                    C(idxs(dec.which_aircraft)).vertical_rate_atc = dec.new_vs1_fpm;
                elseif dec.which_aircraft ==2
                    C(idxs(dec.which_aircraft)).vertical_rate_atc = dec.new_vs2_fpm;
                end
        %elseif CM(i) == 3
            
        end
    end
end


%%
function [delta_deg, details] = min_heading_change_toward_faster(p1_latlon, p2_latlon, v1, v2, hdg1_deg, hdg2_deg, Dmin_m)

if v1 <= v2
    slow = struct('latlon',p1_latlon,'v',v1,'hdg_deg',hdg1_deg,'id',1);
    fast = struct('latlon',p2_latlon,'v',v2,'hdg_deg',hdg2_deg,'id',2);
else
    slow = struct('latlon',p2_latlon,'v',v2,'hdg_deg',hdg2_deg,'id',2);
    fast = struct('latlon',p1_latlon,'v',v1,'hdg_deg',hdg1_deg,'id',1);
end

lat0 = mean([slow.latlon(1), fast.latlon(1)]) * pi/180;
[m_per_deg_lat, m_per_deg_lon] = meters_per_degree(lat0);
p_slow = latlon_to_xy(slow.latlon, lat0, m_per_deg_lat, m_per_deg_lon);
p_fast = latlon_to_xy(fast.latlon, lat0, m_per_deg_lat, m_per_deg_lon);

hdg_s = deg2rad(slow.hdg_deg);
hdg_f = deg2rad(fast.hdg_deg);
u_s0  = [sin(hdg_s), cos(hdg_s)];
u_f   = [sin(hdg_f), cos(hdg_f)];

r0    = p_fast - p_slow;
v_f   = fast.v * u_f;

bearing_sf = atan2(r0(1), r0(2));
angdiff = wrapToPi(bearing_sf - hdg_s);
turn_dir = sign(angdiff);
if turn_dir == 0
    turn_dir = 1;
end

    function [d_cpa, t_cpa] = miss_distance_for_delta(delta)
        hdg_s_new = hdg_s + turn_dir*delta;
        u_s = [sin(hdg_s_new), cos(hdg_s_new)];
        v_s = slow.v * u_s;
        v_rel = v_f - v_s;
        v2norm = dot(v_rel, v_rel);
        if v2norm < 1e-12
            t_cpa = 0;
            d_cpa = norm(r0);
            return
        end
        t_cpa = - dot(r0, v_rel) / v2norm;
        if t_cpa < 0
            t_cpa = 0;
        end
        d_cpa = norm(r0 + v_rel*t_cpa);
    end

[d0, t0] = miss_distance_for_delta(0);
if d0 >= Dmin_m
    delta_deg = 0;
    details = pack_details(delta_deg, slow, fast, r0, v_f, d0, t0, turn_dir, lat0, Dmin_m);
    return
end

delta_lo = 0;
delta_hi = deg2rad(180);
[dhi, ~] = miss_distance_for_delta(delta_hi);
if dhi < Dmin_m
    delta_deg = NaN;
    details = pack_details(delta_deg, slow, fast, r0, v_f, d0, t0, turn_dir, lat0, Dmin_m);
    return
end
for k = 1:60
    mid = 0.5*(delta_lo + delta_hi);
    [dm, ~] = miss_distance_for_delta(mid);
    if dm >= Dmin_m
        delta_hi = mid;
    else
        delta_lo = mid;
    end
end
delta_rad = delta_hi;
delta_deg = rad2deg(delta_rad);

details = pack_details(delta_deg, slow, fast, r0, v_f, d0, t0, turn_dir, lat0, Dmin_m);

end

function xy = latlon_to_xy(latlon, lat0, m_per_deg_lat, m_per_deg_lon)
    lat = latlon(1)*pi/180;
    lon = latlon(2)*pi/180;
    xy = [ lon*m_per_deg_lon, lat*m_per_deg_lat ];
end

function [m_per_deg_lat, m_per_deg_lon] = meters_per_degree(lat0)
    m_per_deg_lat = 111320;
    m_per_deg_lon = 111320 * cos(lat0);
end

function a = wrapToPi(a)
    a = mod(a + pi, 2*pi) - pi;
end

function s = pack_details(delta_deg, slow, fast, r0, v_f, d0, t0, turn_dir, lat0, Dmin_m)
    s = struct();
    s.delta_deg = delta_deg;
    s.slow_id = slow.id;
    s.fast_id = fast.id;
    s.turn_direction_sign = turn_dir;
    s.initial_miss_distance_m = d0;
    s.initial_t_cpa_s = t0;
    s.lat0_rad = lat0;
    s.Dmin_m = Dmin_m;
    s.note = 'delta_deg NaN -> a "gyorsabb felé" forgatási korlát mellett nem biztosítható a Dmin.';
end


%% 
function result = allowed_vertical_speed(lat1,lon1,s1,hdg1,alt1,vs1_fpm, ...
                                         lat2,lon2,s2,hdg2,alt2,vs2_fpm)
% allowed_vertical_speed  Kiszámolja a CA időt, horizontális távolságot,
% és a megengedett függőleges sebesség-intervallumot (fpm), ha az 1-es
% gép függőleges sebességét szabályozzuk.
%
% Mértékegységek:
%  lat, lon: deg
%  s: m/s
%  hdg: deg (heading, clockwise from true north)
%  alt: ft
%  vs_fpm: ft/min
%
% Visszatérési struct (result):
%  .tCA_s       - time of closest approach in seconds (future, >=0)
%  .dH_CA_m     - horizontal distance at CA in meters
%  .horizontal_OK - true ha dH_CA >= 5 NM
%  .allowed_vs1_fpm_range - [low, high] interval that is FORBIDDEN; allowed values are outside this interval
%  .note        - explanatory string

% constants
R = 6371000;           % Earth radius [m]
NM5_m = 5*1852;        % 5 nautical miles in meters
min_to_s = 60;

% local tangent plane origin (take mean lat/lon for best approx)
lat0 = deg2rad((lat1+lat2)/2);
lon0 = deg2rad((lon1+lon2)/2);

% convert lat/lon to local meters (approx)
lat1r = deg2rad(lat1); lon1r = deg2rad(lon1);
lat2r = deg2rad(lat2); lon2r = deg2rad(lon2);
x1 = R * (lon1r - lon0) * cos(lat0);
y1 = R * (lat1r - lat0);
x2 = R * (lon2r - lon0) * cos(lat0);
y2 = R * (lat2r - lat0);

r0 = [x2 - x1; y2 - y1];   % vector from ac1 to ac2

% headings: hdg deg clockwise from north. Define east=x, north=y.
hdg1r = deg2rad(hdg1);
hdg2r = deg2rad(hdg2);

v1 = [ s1 * sin(hdg1r); s1 * cos(hdg1r) ]; % (vx east, vy north)
v2 = [ s2 * sin(hdg2r); s2 * cos(hdg2r) ];

v_rel = v2 - v1;  % relative velocity (ac2 wrt ac1)
vrel2 = dot(v_rel,v_rel);

if vrel2 < 1e-8
    tCA = 0; % almost same ground track/vel => use now
else
    tCA = - dot(r0, v_rel) / vrel2;
    if tCA < 0
        tCA = 0; % closest in future, not past
    end
end

pos_rel_at_t = r0 + v_rel * tCA;
dH = norm(pos_rel_at_t);

result.tCA_s = tCA;
result.dH_CA_m = dH;
result.horizontal_OK = (dH >= NM5_m);

% Vertical separation constraint if horizontal not ok
dz0 = alt1 - alt2; % ft
A = tCA / min_to_s; % multiplier for fpm -> ft (vs difference * A gives ft)

if result.horizontal_OK
    result.allowed_vs1_fpm_range = [-Inf, Inf]; % any vs1 ok (horizontally satisfied)
    result.note = sprintf('Horizontal separation at CA is %.1f m >= 5 NM (%.0f m). No vertical constraint.', dH, NM5_m);
    return;
end

% if A == 0 then vertical motion during CA is negligible: must already have |dz0|>=1000
if abs(A) < 1e-9
    if abs(dz0) >= 1000
        result.allowed_vs1_fpm_range = [-Inf, Inf];
        result.note = sprintf('Closest approach happens now (tCA=0). Current vertical separation = %.1f ft >= 1000 ft.', dz0);
    else
        result.allowed_vs1_fpm_range = [Inf, -Inf]; % empty set -> impossible
        result.note = sprintf('Closest approach now and vertical separation (%.1f ft) < 1000 ft. Cannot fix by vertical speed (no time).', dz0);
    end
    return;
end

% Solve | dz0 + A*(vs1 - vs2) | >= 1000  for vs1
% This gives allowed vs1 outside an interval:
low_bound = ((-1000 - dz0)/A) + vs2_fpm;
high_bound = (( 1000 - dz0)/A) + vs2_fpm;

% Order them: lower < upper?
if low_bound <= high_bound
    forbidden_low = low_bound;
    forbidden_high = high_bound;
else
    forbidden_low = high_bound;
    forbidden_high = low_bound;
end

result.allowed_vs1_fpm_range = [forbidden_low, forbidden_high]; 
result.note = sprintf(['At CA (t=%.1f s) horizontal sep = %.1f m < 5 NM. ',...
                       'To keep |dz|>=1000 ft the 1st aircraft''s vertical speed (fpm) must be OUTSIDE [%.1f, %.1f] fpm (values inside that interval would violate vertical separation at CA).'], ...
                       tCA, dH, forbidden_low, forbidden_high);

end

%%

function decision = choose_min_vs_change( ...
    lat1,lon1,s1,hdg1,alt1,vs1_fpm, ...
    lat2,lon2,s2,hdg2,alt2,vs2_fpm)

% 1) Kiszámítjuk a tiltott sávot, ha CSAK az 1-es gép vs-e változhat
r12 = allowed_vertical_speed(lat1,lon1,s1,hdg1,alt1,vs1_fpm, ...
                             lat2,lon2,s2,hdg2,alt2,vs2_fpm);

% 2) Kiszámítjuk a tiltott sávot, ha CSAK a 2-es gép vs-e változhat
%    (swap: a függvény első bemenete mindig annak a gépnek a tiltott sávját adja vissza)
r21 = allowed_vertical_speed(lat2,lon2,s2,hdg2,alt2,vs2_fpm, ...
                             lat1,lon1,s1,hdg1,alt1,vs1_fpm);

% Ha horizontálisan már OK a CA-nál, nincs teendő
if r12.horizontal_OK || r21.horizontal_OK
    decision.which_aircraft = 0;  % 0 = none
    decision.delta_fpm = 0;
    decision.new_vs1_fpm = vs1_fpm;
    decision.new_vs2_fpm = vs2_fpm;
    %decision.reason = sprintf('Horizontal sep at CA is >= 5 NM (%.1f m). No change needed.', r12.dH_CA_m);
    decision.tCA_s = r12.tCA_s;
    decision.dH_CA_m = r12.dH_CA_m;
    return;
end

% Segédfüggvény: minimális ugrás a tiltott sávból kifelé (határra)
    function [delta, new_vs] = minimal_jump(current_vs, band)
        L = band(1); U = band(2);
        if isfinite(L) && isfinite(U) && L <= U
            if current_vs > L && current_vs < U
                % bent vagyunk -> a legközelebbi határra ugrunk (határ megengedett)
                dL = L - current_vs;
                dU = U - current_vs;
                if abs(dL) <= abs(dU)
                    delta = dL; new_vs = L;
                else
                    delta = dU; new_vs = U;
                end
            else
                % már kívül van -> nincs szükség változtatásra
                delta = 0; new_vs = current_vs;
            end
        elseif isinf(L) && isinf(U) && L < U
            % (-Inf, Inf): nincs tiltás -> nincs szükség változtatásra
            delta = 0; new_vs = current_vs;
        elseif isinf(L) && isinf(U) && L > U
            % üres halmaz (lehetetlen helyzet, pl. tCA=0 és |dz0|<1000)
            delta = NaN; new_vs = NaN;
        else
            % Fél-végtelen sávok (ritkák itt), kezeljük általánosan
            if isfinite(L) && current_vs < L
                delta = 0; new_vs = current_vs;
            elseif isfinite(U) && current_vs > U
                delta = 0; new_vs = current_vs;
            else
                % benne vagyunk egy fél-végtelen tiltott részben -> ugorjunk a határra
                if isfinite(L) && ~isfinite(U)
                    delta = L - current_vs; new_vs = L;
                elseif isfinite(U) && ~isfinite(L)
                    delta = U - current_vs; new_vs = U;
                else
                    delta = 0; new_vs = current_vs;
                end
            end
        end
    end

% 3) Opció A: csak vs1-t változtatjuk (vs2 fix)
[delta1, vs1_new] = minimal_jump(vs1_fpm, r12.allowed_vs1_fpm_range);

% 4) Opció B: csak vs2-t változtatjuk (vs1 fix)
[delta2, vs2_new] = minimal_jump(vs2_fpm, r21.allowed_vs1_fpm_range); % r21 elsője = AC2 tiltott sávja

% 5) Döntés & eredmények
decision.tCA_s   = r12.tCA_s;
decision.dH_CA_m = r12.dH_CA_m;
decision.notes.r12 = r12.note;
decision.notes.r21 = r21.note;

% Lehetetlen helyzet detektálása
if (isnan(delta1) && isnan(delta2))
    decision.which_aircraft = -1; % impossible now
    decision.delta_fpm = NaN;
    decision.new_vs1_fpm = NaN;
    decision.new_vs2_fpm = NaN;
    decision.reason = 'Closest approach is essentially now and |Δz0|<1000 ft -> no time to build vertical separation by VS change.';
    return;
end

% Ha mindkettő 0, nincs teendő (már kívül vannak a tiltott sávból)
if (delta1==0) && (delta2==0)
    decision.which_aircraft = 0;
    decision.delta_fpm = 0;
    decision.new_vs1_fpm = vs1_fpm;
    decision.new_vs2_fpm = vs2_fpm;
    decision.reason = 'Both vertical speeds already yield >=1000 ft at CA.';
    return;
end

% Válasszuk a kisebb abszolút változtatást (holtverseny: az 1-est preferáljuk)
if (isnan(delta2)) || (~isnan(delta1) && abs(delta1) <= abs(delta2))
    decision.which_aircraft = 1;
    decision.delta_fpm = delta1;
    decision.new_vs1_fpm = vs1_new;
    decision.new_vs2_fpm = vs2_fpm;
    decision.reason = 'Minimal absolute change achieved by adjusting AC1 vertical speed.';
else
    decision.which_aircraft = 2;
    decision.delta_fpm = delta2;
    decision.new_vs1_fpm = vs1_fpm;
    decision.new_vs2_fpm = vs2_new;
    decision.reason = 'Minimal absolute change achieved by adjusting AC2 vertical speed.';
end
end



end
