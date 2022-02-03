function [jointEntropy] = ml_alg_joint_entropy_images(Ia, Ib)
    % Ia and Ib must be discrete valued

    indrow = double(Ia(:)) + 1;
    indcol = double(Ib(:)) + 1; %// Should be the same size as indrow
    jointHistogram = accumarray([indrow indcol], 1);
    jointProb = jointHistogram / numel(indrow);
    indNoZero = jointHistogram ~= 0;
    jointProb1DNoZero = jointProb(indNoZero);
    jointEntropy = -sum(jointProb1DNoZero.*log2(jointProb1DNoZero));
end