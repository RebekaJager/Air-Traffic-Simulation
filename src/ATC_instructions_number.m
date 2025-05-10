function [ATC_instructions] = ATC_instructions_number(C)
% ATC_INSTRUCTIONS_NUMBER - Get the number of separation ATC instructions
%   given in a controlled traffic structure.
%
%   Syntax
%       [ATC_instructions] = ATC_INSTRUCTIONS_NUMBER(C)
%
%   Input Arguments
%      * C as structure, structure of controlled traffic data.
%
%   Output Arguments
%      * ATC_instructions as double, the number of aircraft recieving ATC
%         instructions. Serves as a KPI.


if isfield(C, 'velocity_atc')
    ATC_inst1 = length([C(:).velocity_atc]);
else
    ATC_inst1 = 0;
end
if isfield(C, 'heading_atc')
    ATC_inst2 = length([C(:).heading_atc]);
else
    ATC_inst2 = 0;
end
if isfield(C, 'flightlevel_atc')
    ATC_inst3 = length([C(:).flightlevel_atc]);
else
    ATC_inst3 = 0;
end

ATC_instructions = ATC_inst1 + ATC_inst2 + ATC_inst3;
end