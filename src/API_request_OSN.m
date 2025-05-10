function [S] = API_request_OSN(ntry, lamax, lamin, lomax, lomin, varargin)
% API_REQUEST_OSN - Load real-time air traffic data from OpenSky Network.
%   Supports both unauthenticated and authenticated requests to the
%   OpenSky Network REST API (see: https://opensky-network.org).
%
%   Syntax
%       S = API_REQUEST_OSN(ntry, lamax, lamin, lomax, lomin)
%       S = API_REQUEST_OSN(ntry, lamax, lamin, lomax, lomin, username, password)
%
%   Input Arguments
%      * ntry as double, number of attempts to make an API request.
%         If an API request fails, this specifies how many times it will
%         be retried. If all attempts fail, the error message is displayed.
%      * lamax as double, maximum latitude of the query area
%      * lamin as double, minimum latitude of the query area
%      * lomax as double, maximum longitude of the query area
%      * lomin as double, minimum longitude of the query area
%      * username as string (optional), OpenSky Network username
%      * password as string (optional), OpenSky Network password
%
%   Output Arguments
%      * S as structure, structure containing the ADS-B traffic data 
%         returned by the OpenSky Network API.




narginchk(5, 7)
% Create request header
if nargin > 5
    username = varargin{1};
    password = varargin{2};
    options = weboptions('HeaderFields',{'Authorization',['Basic ' matlab.net.base64encode([username ':' password])]}, 'Timeout', 20);
    options.Username = username;
    options.Password = password;
else
    options = weboptions('Timeout', 20);
end

% Assemble URL
URL = strcat('https://opensky-network.org/api/states/all?lamin=', num2str(lamin), '&lomin=', num2str(lomin), '&lamax=', num2str(lamax), '&lomax=', num2str(lomax));
% Set variables for while loop
success = false;
trys = 0;
fprintf('API request \n')

while success == false
    try
        trys = trys + 1;
        fprintf('%d/%d try \n', trys, ntry)
        S = webread(URL, options);
        if isempty(S.states) == 0
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