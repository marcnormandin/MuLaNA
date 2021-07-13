above = abs(z) >= 3;
aboveIndices = find(above == 1);

figure
plot(z, 'k-')
hold on
plot(aboveIndices, z(aboveIndices), 'ro')
