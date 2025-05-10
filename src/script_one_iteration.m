%% First request  ADSBexchange v2
% ADSBexchange v2 documentation:
% https://www.adsbexchange.com/version-2-api-wip/ 

t = 20;
[lat, lon, d, bordershp, ~] = areaCalc('HU', t);

% API request
S = API_request(1, lat, lon, 250);

%% Process data to traffic simulation's own format
D = stateProcess(S.aircraft);
%D = stateProcess_OSN(S.states);

% Filter for above FL030
D = D([D(:).flightlevel] > 30);

%% Traffic Simulation
D = estimatePos(D, t);
D = shiftPos(D);
D = getInside(D, bordershp);
D = estimatePos(D, 5);
% Filter for aircraft inside the area
D2 = D([D(:).inside] == 1);

%% Visualize
v = stateMapping_simple(D2, 1);

%% Control
C1 = generateRequests(D2); % kérés típus mező kérdése
C = controllerActions(C1); % A simple controller algorithm LEÍRÁST BEFEJEZNI, ALTERNATÍV HASZNÁLATI MÓDOK
D = controlStates(D, C);
D = estimatePos(D, 0.5); % Account for time during ATC instruction exchange and perfrmance
D = shiftPos(D);

%% Update positions outside the area
S = API_request(1, lat, lon, 250);
D2 = stateProcess(S.aircraft);
D = getInside(D, bordershp);
D = updatePos(D, D2); % EHHEZ HELPET
D = getInside(D, bordershp);
%%
n = separationMinima(D([D(:).inside] == 1));
