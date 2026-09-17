function [S] = historicalLoad(index, varargin)
% HISTORICALLOAD - Load given data point from ADS-B Exchange sample
%   histroical data.
%
%   Syntax
%       [S] = HISTORICALLOAD(index) Use default day 01. 04. 2025.
%       [S] = HISTORICALLOAD(index, year, month) Use user defined year and
%        month. Note that only the first day of each month is available in
%        the sample data.
%
%   Input Arguments
%      * index as double, index of data point in each day from 1 to 235955.
%      * year as double, year of sample data. Snapshots of all global
%         airborne traffic are archived every 5 seconds starting May 2020,
%         (prior data is available every 60 secs from starting in July 2016.
%
%   Output Arguments
%      * S as structure, structure of ADS-B data as returned by the API.
    
    if nargin == 1
        year = '2025'; month = '04';
    elseif nargin == 3
        year = varargin{1}; month = varargin{2};
    else
        error('Incorrect number of input arguments.')
    end
    
    if index > 235955 || index < 1
        error('Index out of bounds.')
    end
    day = '01'; 
    
    total_seconds = (index - 1) * 5;
    H = floor(total_seconds / 3600);
    M = floor(mod(total_seconds, 3600) / 60);
    S_sec = mod(total_seconds, 60);
    idx = sprintf('%02d%02d%02d', H, M, S_sec);
    % --------------------------------------------------------------
    
    URL = sprintf('https://samples.adsbexchange.com/readsb-hist/%s/%s/%s/%sZ.json.gz', year, month, day, idx);
    
    success = false;
    trys = 0;
    ntry = 50;
    options = weboptions('Timeout', 10); 
    
    while ~success && trys < ntry
        try
            trys = trys + 1;
            S = webread(URL, options);
            if ~isempty(S)
                success = true;
            end
        catch ME
            if trys >= ntry
                fprintf('API request unsuccessful after %d attempts.\n', ntry);
                rethrow(ME);
            end
            pause(0.5);
        end
    end
end
