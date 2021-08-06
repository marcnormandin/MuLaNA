function [uz,cz] = ml_alg_cumdist(z)
    uz = sort(unique(z));
    cz = zeros(1,length(uz));
    for i = 1:length(uz)
        cz(i) = sum( z <= uz(i) );
    end
    cz = cz ./ length(z);
end
