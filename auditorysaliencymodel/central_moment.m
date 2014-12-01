function B = central_moment(A,N)
% B = central_moment(A,N)
%
% Returns B as the the Nth central moment of the function of which the
% column vector A represents sample heights. These sample heights must be
% equally spaced and normalised so SUM(A) = 1. 
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
% central_moment(A,2)
%
%ans =
%    1.9600    2.0000
%
% See also RAW_MOMENT, D_NORMALIZE
% 
% MC, SD	ALAVLSI, EmCAP 19/12/05
%
%..........................................................................

[r,c] = size(A);
x = repmat([1:r]',[1 c]);

% We need to subtract the mean (the first raw moment)
x = (x - repmat([1:r]*A, [r 1])).^N;

% return value
B = sum(x .* A);