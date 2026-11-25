function [D] = filterACC(D, Vol, fl_min, fl_max)
% FILTERACC - Keep only the traffic that belongs to the Budapest ACC.
%   An aircraft is kept if it is inside the vertical limits of the Budapest
%   CTA and NOT inside any TMA / MTMA / MCTR volume of the exclusion list.
%
%   Syntax
%       [D] = FILTERACC(D, Vol)
%       [D] = FILTERACC(D, Vol, fl_min, fl_max)
%
%   Input Arguments
%      * D as structure, structure of traffic data (fields latitude,
%         longitude, flightlevel).
%      * Vol as struct array, airspace volumes to be removed, as returned
%         by TMACALC (fields Shape, LowerFL, UpperFL).
%      * fl_min as double, lower limit of the CTA [FL]. Default: 95
%         (9500 FT ALT).
%      * fl_max as double, upper limit of the CTA [FL]. Default: 660
%
%   Output Arguments
%      * D as structure, traffic data of aircraft controlled by the ACC.
%
%   Notes
%      * Vertical limits follow the convention of the sector definitions:
%        lower limit inclusive, upper limit exclusive (e.g. an aircraft at
%        FL195 is above the Budapest TMA and counts as ACC traffic).
%      * Only the vertical and TMA filtering is done here. The lateral
%        limit (Hungary) is handled by GETINSIDE.

if nargin < 3 || isempty(fl_min), fl_min = 95;  end
if nargin < 4 || isempty(fl_max), fl_max = 660; end

if isempty(D)
    return;
end

fl  = [D.flightlevel];
lat = [D.latitude];
lon = [D.longitude];

% Budapest CTA vertical limits
keep = fl >= fl_min & fl < fl_max;

% Remove everything inside TMA / MTMA / MCTR volumes
for v = 1:numel(Vol)
    cand = keep & fl >= Vol(v).LowerFL & fl < Vol(v).UpperFL;
    if any(cand)
        in_vol = false(size(keep));
        tf = isinterior(Vol(v).Shape, lon(cand), lat(cand));
        in_vol(cand) = tf(:).';
        keep = keep & ~in_vol;
    end
end

D = D(keep);
end
