angles = allAngles;
rho = data{iTrial}.allDistances(activeIndices,:); % matrix of spikes x distances where #distances is #angles searched
theta = data{iTrial}.lookDegCan(activeIndices); % #spikes x 1 vector
x = data{iTrial}.posCan(activeIndices,:); % position #spikes x 2

distanceThreshold = 30;
rhot = rho;
rhot(rhot < distanceThreshold) = -1;

nrho = 100;
rho_edges = linspace(0,distanceThreshold,nrho);
theta_edges = 0:1:360;


numSpikes = size(rho,1);
M = [];
%i = 2;
for i = 1:numSpikes
    [Mi, re, te] = histcounts2(rho(i,:), angles, rho_edges, theta_edges);
    if isempty(M)
        M = Mi;
    else
        M = M + Mi;
    end
end

[RHO,THETA] = meshgrid(re(1:end-1), te(1:end-1));

figure
polaraxes
imagesc(te, re, M)
