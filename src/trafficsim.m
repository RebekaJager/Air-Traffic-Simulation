function [D, v] = trafficsim(varargin)
% TRAFFICSIM - Air traffic estimation based on ADS-B data.
%
%   Syntax
%       [D, v] = TRAFFICSIM()
%           Launch demo mode with predefined parameters.
%
%       [D, v] = TRAFFICSIM(ISO_A2_country_code, t)
%           Get traffic estimation for the selected country code and 
%           timeframe [min] as an unauthenticated OpenSky user.
%
%       [D, v] = TRAFFICSIM(___, OpenSkyAuth)
%           Provide OpenSky authentication as a structure with fields 
%           'Username' and 'Password' for authenticated access.
%
%       [D, v] = TRAFFICSIM(___, 'log')
%           Save API responses during execution.
%
%       [D, v] = TRAFFICSIM(___, OpenSkyAuth, 'log')
%           Save API responses using authenticated OpenSky access.
%
%   Input Arguments
%      * ISO_A2_country_code as string, selecting state (optional)
%      * t as double, estimation timeframe [min] (optional)
%      * OpenSkyAuth as structure (optional), with fields:
%           - Username: OpenSky username as string
%           - Password: OpenSky password as string
%      * 'log' as boolean (optional), enable logging of API responses
%
%   Output Arguments
%      * D as structure, structure of traffic data
%      * v as figure, visualization of the estimated traffic

log = 0;
if nargin == 0
    ISO_A2_country_code = 'HU';
    t = 20;
elseif nargin == 1
    error('Not enough input arguments.')
elseif nargin == 2
    ISO_A2_country_code = varargin{1};
    t = varargin{2};
elseif nargin == 3
    ISO_A2_country_code = varargin{1};
    t = varargin{2};
    if varargin{3} == 'log'
        log = 1;
    else
        OpenSkyAuth = varargin{3};
    end
elseif nargin == 4
    ISO_A2_country_code = varargin{1};
    t = varargin{2};
    OpenSkyAuth = varargin{3};
    log = 1;
else
    error('Too many input arguments.')
end

[lamax, lamin, lomax, lomin, bordershp] = areaCalc(ISO_A2_country_code, t);

S = API_request(1, username, password, lamax, lamin, lomax, lomin);

D = stateProcess(S.states);
D = estimatePos(D, t);
D = shiftPos(D);
D = filterBorder(D, 0, bordershp);
D = estimatePos(D, 5);

v = stateMapping(D, 1);
end