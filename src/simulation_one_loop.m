for i = 8189 : 235955
    %% Visualize
    %v = stateMapping_simple(D2, 1);

    %% Control
    C1 = generateRequests(D2);
    C = controllerActions(C1);
    ATC_instructions(end+1) = ATC_instructions_number(C);
    AC_in_sector(end+1) = length(C);
    D = controlStates(D, C);
    D = estimatePos(D, 5/60); % 5 seconds in minutes, induced by the resution of histroical data
    D = shiftPos(D);
    D = getInside(D, bordershp);
    sep_min_infringements(end+1) = separationMinima(D([D(:).inside] == 1));

    %% Update positions outside the area
    S = historicalLoad(i);
    D_all_updated = stateProcess(S.aircraft);
    % Filter for area
    D_all_updated = getInside(D_all_updated, areashp);
    D_all_updated = D_all_updated([D_all_updated(:).inside] == 1);
    D = updatePos(D, D_all_updated); 
    D = getInside(D, bordershp);
    % Filter for above FL030
    D = D([D(:).flightlevel] > 30);
    D2 = D([D(:).inside] == 1);
    

end