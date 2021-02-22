function p = ml_util_bivariatepdf(s1, s2, m1, m2, rho, xx1, xx2)
    p = zeros(size(xx1));
    for i = 1:size(xx1,1)
        for j = 1:size(xx2,2)
            x1 = xx1(i,j);
            x2 = xx2(i,j);
            z = (x1-m1).^2 ./ s1^2 - 2*rho*(x1-m1).*(x2-m2)./ (s1*s2) + (x2-m2).^2 ./s2^2;
            n = 2*pi*s1*s2*sqrt(1-rho^2);
            p(i,j) = 1 ./ n * exp( - z ./ (2*(1-rho^2)) );
        end
    end
end