function track = getEventTrack(ts,events)
n = length(ts);
track = zeros(n,1);
sb = wavread('bell.wav');
nb = length(sb)-1;
for i = 1:length(events)
    [yy,kk] = min(abs(ts-events(i)));
    r = kk:(kk+nb);
    r(find(r>n)) = [];
    track(r) = sb(1:length(r));
end
