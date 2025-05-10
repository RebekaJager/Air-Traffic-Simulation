function [S] = API_request(ntry, lat, lon, d)

% API_REQUEST - Load real time air traffic data from ADSBexchange.com.
%
%   Syntax
%       [S] = API_REQUEST(ntry, lat, lon, d) API request as an
%        unauthenticated user. Limitations apply (see OpenSky Network REST API
%        documentation).
%
%   Input Arguments
%      * ntry as double, number of attempts to make an API request. If an API 
%         request fails, this is the number of times it will be retried. If the 
%         last request failed, the API error message is displayed.
%      * lat as double, latitude of area centerpoint
%      * lon as double, longitude of area centerpoint
%      * d as double, distance from the center point of area (in NM) 
%         (100 NM maximum)
%
%   Output Arguments
%      * S as structure, structure of ADS-B data as returned by the API.

% Assemble URL
URL = strcat('https://opendata.adsb.fi/api/v2/lat/', num2str(lat), '/lon/', num2str(lon), '/dist/', num2str(d));
% Set variables for while loop
success = false;
trys = 0;
fprintf('API request \n')

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
end
if success == true
    fprintf('API request successful \n')
end
end