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


switch nargin
    case 1
        year = '2025';
        month = '04';
    case 3
        year = varargin{2};
        month = varargin{3};
    otherwise
        error('Incorrect number of input arguments.')
end
if index > 235955
    error('Maximum index exceeded.')
end
day = '01'; % sample data is available for the 1st of each month

% Calculate possible data points
startTime = datetime('00:00:00','Format','HHmmss');
endTime = datetime('23:59:55','Format','HHmmss');
timeVec = startTime:seconds(5):endTime;
timeStr = datestr(timeVec, 'HHMMSS');
timeStrCell = cellstr(timeStr);


idx = timeStrCell{index};

URL = strcat('https://samples.adsbexchange.com/readsb-hist/', year,...
    '/', month, '/', day, '/', idx, 'Z.json.gz');

success = false;
trys = 0;
fprintf('API request \n')
ntry = 50;
while success == false
    try
        trys = trys + 1;
        fprintf('%d/%d try \n', trys, ntry)
        S = webread(URL);
        if isempty(S) == 0
            success = true;
        end
        if (trys >= ntry) && (success == false)
            fprintf('API request unsuccessful \n')
            break;
        end
    catch ME
        if trys >= ntry
            fprintf('API request unsuccessful \n')
            throw(ME)
            break;
        end
    end

    try
        datetime(S.now, 'ConvertFrom', 'posixtime')
    catch
    end

end