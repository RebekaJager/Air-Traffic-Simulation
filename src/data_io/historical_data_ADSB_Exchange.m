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

time = round((hour * 3600 + minutes * 60 + seconds)/5) * 5;
time_str = sprintf('%06d', time);

URL = strcat('https://samples.adsbexchange.com/readsb-hist/', year,...
    '/', month, '/', day, '/', time_str, 'Z.json.gz');
S = webread(URL);
datetime(S.now, 'ConvertFrom', 'posixtime')
