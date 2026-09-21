%% Unpack preloaded .json file to struct
fname = 'ads_exch.json';
val = jsondecode(fileread(fname));

%% Load historical data for a given date and time
% Note: Snapshots of all global airborne traffic are archived every 5 
% seconds starting May 2020, (prior data is available every 60 secs from 
% starting in July 2016).

S = webread('https://samples.adsbexchange.com/readsb-hist/2025/04/01/000005Z.json.gz');
datetime(S.now, 'ConvertFrom', 'posixtime')

%% Load histroical data for a given time
year = '2025';
month = '04';
day = '01'; % sample data is available for the 1st of each month
hour = 0;
minutes = 0;
seconds = 0;

total_seconds = round((hour * 3600 + minutes * 60 + seconds) / 5) * 5;
H = floor(total_seconds / 3600);
M = floor(mod(total_seconds, 3600) / 60);
S_sec = mod(total_seconds, 60);

time_str = sprintf('%02d%02d%02d', H, M, S_sec);
URL = sprintf('https://samples.adsbexchange.com/readsb-hist/%s/%s/%s/%sZ.json.gz', year, month, day, time_str);
S = webread(URL);
datetime(S.now, 'ConvertFrom', 'posixtime')
