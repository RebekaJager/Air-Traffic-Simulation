function [C_out, WorkloadLog] = SectorManager(C_in, ActiveSectors, enable_errors, params)
% SECTORMANAGER - Distributes traffic among active sectors and applies ATC logic.
%   Acts as the executive layer below the SV Agent. It filters the global
%   traffic into localized sector traffic, calls the conflict detection and
%   resolution algorithms for each sector independently, and merges the
%   resulting ATC instructions back into the global traffic structure.
%
%   Syntax
%       [C_out] = SECTORMANAGER(C_in, ActiveSectors)
%       [C_out, WorkloadLog] = SECTORMANAGER(C_in, ActiveSectors, enable_errors)
%       [C_out, WorkloadLog] = SECTORMANAGER(C_in, ActiveSectors, enable_errors, params)
%
%   Input Arguments
%      * C_in as struct, structure of the global traffic data, typically
%         already appended with pilot requests.
%      * ActiveSectors as struct array, the operational sectors provided
%         by the SVAgent (containing MergedShape, LowerFL, UpperFL).
%      * enable_errors as boolean for enabling human error in controller
%         instructions
%      * params as struct, error model parameters (see DEFAULTERRORPARAMS).
%         Optional; defaults are used if omitted. Individual differences
%         (m_P, m_W) are tied to the sector (controller position) and are
%         reproducible from params.seed.
%
%   Output Arguments
%      * C_out as struct, structure of global traffic data appended with
%         the aggregated ATC instructions from all local sector controllers.

    if nargin < 3
        enable_errors = false; % Default: no error (for baseline run)
    end
    if nargin < 4 || isempty(params)
        params = defaultErrorParams();
    else
        params = defaultErrorParams(params);   % fill in missing fields
    end
    
    WorkloadLog = struct('SectorName', {}, 'Workload', {});
    C_out = C_in;
    
    if isempty(C_in) || isempty(ActiveSectors)
        return;
    end
    
    for k = 1:length(ActiveSectors) % iterate through active sectors
        sec = ActiveSectors(k);
        
        % vertical direction
        idx_vert_strict = [C_out.flightlevel] >= sec.LowerFL & [C_out.flightlevel] < sec.UpperFL;
        idx_vert_buffer = [C_out.flightlevel] >= (sec.LowerFL - 20) & [C_out.flightlevel] <= (sec.UpperFL + 20);
        
        % horizontal direction
        pts = geopointshape([C_out.latitude], [C_out.longitude]);
        in_strict = false(1, length(C_out));
        in_buffer_zone = false(1, length(C_out));
        
        if any(idx_vert_strict)
            in_strict(idx_vert_strict) = isinterior(sec.MergedShape, pts(idx_vert_strict));
        end
        if any(idx_vert_buffer)
            in_buffer_zone(idx_vert_buffer) = isinterior(sec.BufferedShape, pts(idx_vert_buffer)) & ~in_strict(idx_vert_buffer);
        end
        
        idx_owned = idx_vert_strict & in_strict;
        idx_buf   = idx_vert_buffer & in_buffer_zone;
        
        % Kiemeljük egyben az összes gépet, így nincs horzcat hiba
        idx_both = find(idx_owned | idx_buf);
        D_sec = C_out(idx_both);
        
        for i = 1:length(idx_both)
            D_sec(i).is_owned = idx_owned(idx_both(i));
        end
        
        % Csak akkor csinálunk bármit, ha a szektorban VAN saját (owned) gép
        if ~isempty(D_sec) && any([D_sec.is_owned])
            
            % calculate workload
            sector_name = sec.SectorName;
            [~, W_smooth] = calculateWorkload(D_sec, sector_name, params);
            
            % record for output
            WorkloadLog(end+1).SectorName = sector_name;
            WorkloadLog(end).Workload = W_smooth;
            
            % Apply already-assigned *_atc instructions from upstream sectors before detection
            D_sec_pred = D_sec;
            for idx_p = 1:length(D_sec_pred)
                if isfield(D_sec_pred, 'heading_atc') && ~isempty(D_sec_pred(idx_p).heading_atc)
                    D_sec_pred(idx_p).heading = mod(D_sec_pred(idx_p).heading_atc, 360);
                end
                if isfield(D_sec_pred, 'flightlevel_atc') && ~isempty(D_sec_pred(idx_p).flightlevel_atc)
                    D_sec_pred(idx_p).flightlevel = D_sec_pred(idx_p).flightlevel_atc;
                    D_sec_pred(idx_p).altitude = D_sec_pred(idx_p).flightlevel_atc * 100;
                end
                if isfield(D_sec_pred, 'velocity_atc') && ~isempty(D_sec_pred(idx_p).velocity_atc)
                    D_sec_pred(idx_p).velocity = D_sec_pred(idx_p).velocity_atc;
                end
                if isfield(D_sec_pred, 'vertical_rate_atc') && ~isempty(D_sec_pred(idx_p).vertical_rate_atc)
                    D_sec_pred(idx_p).vertical_rate = D_sec_pred(idx_p).vertical_rate_atc;
                end
            end

            % detect and solve conflicts in sector
            CM_sec = conflictDetect(D_sec_pred, 5);
            C_sec_solved = conflictSolve(CM_sec, D_sec);
            
            % apply error rate
            if enable_errors
                % individual traits of the controller working this sector
                traits = getControllerTraits(sector_name, params);
                % error probability per instruction, in [0,1]
                dyn_error = errorProbability(W_smooth, params, traits);
                
                % apply error ONLY to owned aircraft
                for i = 1:length(C_sec_solved)
                    if C_sec_solved(i).is_owned && rand() < dyn_error
                        
                        error_mult = (1 + params.M_error * (2 * rand() - 1));
                        
                        if isfield(C_sec_solved, 'heading_atc') && ~isempty(C_sec_solved(i).heading_atc)
                            C_sec_solved(i).heading_atc = C_sec_solved(i).heading_atc * error_mult;
                        end
                        if isfield(C_sec_solved, 'flightlevel_atc') && ~isempty(C_sec_solved(i).flightlevel_atc)
                            C_sec_solved(i).flightlevel_atc = C_sec_solved(i).flightlevel_atc * error_mult;
                        end
                        if isfield(C_sec_solved, 'velocity_atc') && ~isempty(C_sec_solved(i).velocity_atc)
                            C_sec_solved(i).velocity_atc = C_sec_solved(i).velocity_atc * error_mult;
                        end
                        if isfield(C_sec_solved, 'vertical_rate_atc') && ~isempty(C_sec_solved(i).vertical_rate_atc)
                            C_sec_solved(i).vertical_rate_atc = C_sec_solved(i).vertical_rate_atc * error_mult;
                        end
                    end
                end
            end
            
            % synchronize to global structure (BIZTONSÁGOS INDEXELÉS)
            calls_solved = {C_sec_solved([C_sec_solved.is_owned] == true).callsign};
            calls_main = {C_out.callsign};
            [Lia, Locb] = ismember(calls_solved, calls_main);
            
            idx_solved_filtered = find(Lia);     
            idx_main = Locb(Lia);       
            
            if ~isempty(idx_solved_filtered)
                atc_fields = {'heading_atc', 'flightlevel_atc', 'velocity_atc', 'vertical_rate_atc', 'ATC_approval'};
                for f = 1:length(atc_fields)
                    field = atc_fields{f};
                    if isfield(C_sec_solved, field)
                        for i = 1:length(idx_solved_filtered)
                            % C_sec_solved indexének megkeresése hívójel alapján
                            c_idx = find(strcmp({C_sec_solved.callsign}, calls_main{idx_main(i)}));
                            
                            % BIZTONSÁGI VÉDELEM: Ha véletlenül dupla hívójel van a rendszerben,
                            % csak az első találatot vesszük figyelembe, hogy ne omoljon össze.
                            if ~isempty(c_idx)
                                c_idx = c_idx(1); 
                                
                                % add resolution instruction
                                if ~isempty(C_sec_solved(c_idx).(field))
                                    C_out(idx_main(i)).(field) = C_sec_solved(c_idx).(field);
                                end
                            end
                        end
                    end
                end
            end
            
        end
    end
end


function traits = getControllerTraits(sector_name, params)
% GETCONTROLLERTRAITS - Individual multipliers of the controller at a sector.
%   m_P ~ Lognormal(0, sigma_P), m_W ~ Lognormal(0, sigma_W), median = 1.
%   The draw depends only on (params.seed, sector_name), so a controller
%   keeps the same traits for the whole run and across parameter sweeps
%   (common random numbers), and the global rand() stream is not consumed.
    persistent cache
    if isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    key = sprintf('%d|%g|%g|%s', params.seed, params.sigma_P, params.sigma_W, sector_name);
    if isKey(cache, key)
        traits = cache(key);
        return;
    end
    name_code = sum(double(sector_name) .* (1:numel(sector_name)));
    s = mod(params.seed * 1000003 + name_code, 2^32 - 1);
    stream = RandStream('mt19937ar', 'Seed', s);
    z = randn(stream, 1, 2);
    traits.m_P = exp(params.sigma_P * z(1));
    traits.m_W = exp(params.sigma_W * z(2));
    cache(key) = traits;
end
