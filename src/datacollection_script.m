LOG = cell(1, 1440);

t = 20;
[lat, lon, d, bordershp] = areaCalc('HU', t);

i = 1;
while i < 300
    tic
    while toc < 30
    end
    while (exist("S") == false) || (isempty("S") == true)
        try
            S = API_request(1, lat, lon, 250);
        catch
        end
    end
    disp(datestr(S.now/86400 + datenum(1970,1,1)))
    LOG{i} = S;
    clearvars S
    i = i + 1;
end
save("ADSB_data.mat", "LOG")