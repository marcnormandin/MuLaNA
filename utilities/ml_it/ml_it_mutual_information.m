function [I] = ml_it_mutual_information(x,y, binMethod)
    entropyX = ml_it_entropy(x, binMethod);
    entropyY = ml_it_entropy(y, binMethod);
    entropyXY = ml_it_entropy_joint(x,y, binMethod);
    I = entropyX + entropyY - entropyXY;
end