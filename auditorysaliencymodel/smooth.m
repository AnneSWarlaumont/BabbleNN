function y = smooth(x,w)
% y = smooth(x,w)
% Moving average of x
% Inputs
%	x	input vector
%	w	movinf average window
% Outputs
%	y	smoothed version of x

n=length(x);
y=zeros(n,1);
for i=1:n
   r=max([1 i-w]):min([n i+w]);
   y(i)=mean(x(r));
end
