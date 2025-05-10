%% OpenSky Network compatible funcions
%% First request OpenSky Network REST API
t = 20;
[lamax, lamin, lomax, lomin, bordershp] = areaCalc_OSN('HU', t);   

% API request
username = 'rjager';
password = '9x5G5tFFp77hecv';

S1 = API_request_OSN(1, lamax, lamin, lomax, lomin, username, password);

% OpenSky REST API documentation:
% https://openskynetwork.github.io/opensky-api/rest.html

%% Process data to traffic simulation's own format

D = stateProcess_OSN(S.states);