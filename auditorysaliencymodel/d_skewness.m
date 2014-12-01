function B = d_skewness(A)
% B = d_skewness(A)
%
% Returns B as the the skewness of the function of which the column vector
% A represents sample heights. These sample heights must be equally spaced
% and normalised so SUM(A) = 1. 
%
% If A is a matrix then B is a row vector of values for each column in the
% matrix.
%
% Example:
% A =
%    0.1000    0.2000
%    0.1000    0.2000
%    0.2000    0.2000
%    0.1000    0.2000
%    0.5000    0.2000
%
% d_skewness(A)
%
%ans =
%   -0.8355   -1.3000
%
% See also CENTRAL_MOMENT, RAW_MOMENT
% 
% MC, SD	ALAVLSI, EmCAP 19/12/05
%
%..........................................................................

% --- basic calculation
    B = central_moment(A,3)./(central_moment(A,2).^(3/2));