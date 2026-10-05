function [active_config_id, ActiveSectors] = SVAgent(D, varargin)
% SVAGENT - Supervisor Agent determining the optimal sector configuration.
%   Analyzes the projected traffic density and selects the operational 
%   sector configuration that minimizes the number of required ATCOs while 
%   ensuring no sector exceeds its designated capacity.
%
%   Syntax
%       [id, Sectors] = SVAGENT(D)
%       [id, Sectors] = SVAGENT(D, current_config_id)
%       [id, Sectors] = SVAGENT(D, current_config_id, t_sector_decision)
%       [id, Sectors] = SVAGENT(D, current_config_id, t_sector_decision, t_buffer)
%
%   Input Arguments
%      * D as struct, structure of the current traffic data.
%      * current_config_id as double (optional), the ID of the currently 
%         active configuration. Default is 0 (initialization).
%      * t_sector_decision as double (optional), look-ahead time for sector
%         capacity prediction in minutes. Default is 20 minutes.
%      * t_buffer as double (optional), look-ahead time for calculating the 
%         sector border buffer zone in minutes. Default is 15 minutes. The 
%         physical sector geometry is expanded by a distance calculated from 
%         an average cruise speed and this buffer time.
%
%   Output Arguments
%      * active_config_id as double, the ID of the chosen configuration.
%      * ActiveSectors as struct array, the ready-to-use operational sectors
%         containing merged Polyshapes, expanded BufferedShapes, FL limits, 
%         and capacities.

    persistent Configs ElemSectors current_buffer_time

    % Input Parsing
    current_config_id = 0;
    t_sector_decision = 20; % minutes
    t_buffer = 15;          % minutes
    
    if nargin >= 2 && ~isempty(varargin{1})
        current_config_id = varargin{1};
    end
    if nargin >= 3 && ~isempty(varargin{2})
        t_sector_decision = varargin{2};
    end
    if nargin >= 4 && ~isempty(varargin{3})
        t_buffer = varargin{3};
    end
    
    % --- Persistent Data Loading & Pre-calculation ---
    if isempty(Configs)
        fprintf('SV Agent: Initializing persistent sector geometries...\n');
        projectRoot = getenv('PROJECT_ROOT');
        if isempty(projectRoot)
            projectRoot = pwd;
        end
        cfg = load(fullfile(projectRoot, 'data', 'sector_configurations.mat'));
        elm = load(fullfile(projectRoot, 'data', 'elementary_sectors.mat'));
        
        Configs = cfg.Configurations;
        ElemSectors = elm.ElementarySectors;
        
        % Pre-merge shapes and calculate FL limits for operational sectors
        for c = 1:length(Configs)
            for s = 1:length(Configs(c).OperationalSectors)
                elem_ids = Configs(c).OperationalSectors(s).ElementaryIDs;
                idx = ismember({ElemSectors.ID}, elem_ids);
                match_elem = ElemSectors(idx);
                
                warning('off', 'MATLAB:polyshape:repairedBySimplify');
                
                [lat1, lon1] = extractGeocoords(match_elem(1).Shape);
                merged_poly = polyshape(lon1, lat1);
                
                for e = 2:length(match_elem)
                    [lat_e, lon_e] = extractGeocoords(match_elem(e).Shape);
                    poly_e = polyshape(lon_e, lat_e);
                    
                    merged_poly = union(merged_poly, poly_e);
                end
                
                warning('on', 'MATLAB:polyshape:repairedBySimplify');
                
                Configs(c).OperationalSectors(s).MergedShape = geopolyshape(merged_poly.Vertices(:,2), merged_poly.Vertices(:,1));
                Configs(c).OperationalSectors(s).LowerFL = min([match_elem.LowerFL]);
                Configs(c).OperationalSectors(s).UpperFL = max([match_elem.UpperFL]);
            end
        end
    end
    
    % --- Dynamic Buffer Calculation ---
    if isempty(current_buffer_time) || current_buffer_time ~= t_buffer
        fprintf('SV Agent: Calculating sector buffers for t_buffer = %d min...\n', t_buffer);
        v_cruise = 450; % average cruise speed in knots
        buffer_nm = v_cruise * (t_buffer / 60); 
        buffer_deg = buffer_nm / 60; % rough conversion: 1 NM approx 1/60 degrees
        
        for c = 1:length(Configs)
            for s = 1:length(Configs(c).OperationalSectors)
                merged_shape = Configs(c).OperationalSectors(s).MergedShape;
                
                try
                    Configs(c).OperationalSectors(s).BufferedShape = buffer(merged_shape, buffer_deg);
                catch
                    warning('off', 'MATLAB:polyshape:repairedBySimplify');
                    [lat_coords, lon_coords] = extractGeocoords(merged_shape);
                    temp_poly = polyshape(lon_coords, lat_coords);
                    temp_buffered = polybuffer(temp_poly, buffer_deg);
                    Configs(c).OperationalSectors(s).BufferedShape = geopolyshape(temp_buffered.Vertices(:,2), temp_buffered.Vertices(:,1));
                    warning('on', 'MATLAB:polyshape:repairedBySimplify');
                end
            end
        end
        current_buffer_time = t_buffer;
    end
    
    % --- Traffic Projection ---
    if isempty(D)
        active_config_id = 1; 
        ActiveSectors = Configs(1).OperationalSectors;
        return;
    end
    D_proj = estimatePos(D, t_sector_decision);
    
    % --- Configuration Evaluation ---
    config_stats = struct('ConfigID', {}, 'MaxUtilization', {}, 'NumSectors', {}, 'IsValid', {});
    

    overload_tolerance = 1.15; 
    
    for c = 1:length(Configs)
        is_valid = true;
        max_util = 0;
        
        for s = 1:length(Configs(c).OperationalSectors)
            op_sec = Configs(c).OperationalSectors(s);
            
            idx_vert = [D_proj.flightlevel_mov] >= op_sec.LowerFL & [D_proj.flightlevel_mov] < op_sec.UpperFL;
            D_vert = D_proj(idx_vert);
            
            if isempty(D_vert)
                continue;
            end
            
            pts = geopointshape([D_vert.latitude_mov], [D_vert.longitude_mov]);
            in_lateral = isinterior(op_sec.MergedShape, pts);
            
            count = sum(in_lateral);
            
            util = count / op_sec.Capacity;
            if util > max_util
                max_util = util;
            end
            
            if count > (op_sec.Capacity * overload_tolerance)
                is_valid = false;
                break; 
            end
        end
        
        config_stats(c).ConfigID = Configs(c).ConfigID;
        config_stats(c).MaxUtilization = max_util;
        config_stats(c).NumSectors = Configs(c).NumSectors;
        config_stats(c).IsValid = is_valid;
    end
    
    % --- Decision Logic (Hysteresis) ---
    valid_idx = [config_stats.IsValid] == true;
    valid_configs = config_stats(valid_idx);
    
    [~, sort_idx] = sort([valid_configs.NumSectors]);
    valid_configs = valid_configs(sort_idx);
    
    if isempty(valid_configs)
        fprintf('SV WARNING: All configurations overloaded! Defaulting to Max Capacity.\n');
        active_config_id = Configs(end).ConfigID;
        ActiveSectors = Configs(end).OperationalSectors;
        return;
    end
    
    if current_config_id == 0
        active_config_id = valid_configs(1).ConfigID;
        ActiveSectors = Configs(active_config_id).OperationalSectors;
        return;
    end
    
    curr_idx = find([config_stats.ConfigID] == current_config_id);
    
    if config_stats(curr_idx).IsValid
        downgrade_candidate = 0;
        for i = 1:length(valid_configs)
            if valid_configs(i).NumSectors < config_stats(curr_idx).NumSectors
                if valid_configs(i).MaxUtilization < 0.95
                    downgrade_candidate = valid_configs(i).ConfigID;
                    break; 
                end
            end
        end
        
        if downgrade_candidate > 0
            active_config_id = downgrade_candidate;
        else
            active_config_id = current_config_id; 
        end
    else
        active_config_id = valid_configs(1).ConfigID;
    end
    
    ActiveSectors = Configs(active_config_id).OperationalSectors;
end

% --- HELPER FUNCTION ---
function [lat, lon] = extractGeocoords(gshape)
    try
        GT = table(gshape, 'VariableNames', {'Shape'});
        T = geotable2table(GT, ["Latitude", "Longitude"]);
        lat = T.Latitude{1};
        lon = T.Longitude{1};
    catch
        lat = gshape.InternalData.VertexCoordinate1;
        lon = gshape.InternalData.VertexCoordinate2;
    end
end
