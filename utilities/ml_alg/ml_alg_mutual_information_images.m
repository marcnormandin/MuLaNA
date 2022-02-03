function [mutualInformation] = ml_alg_mutual_information_images(Ia, Ib)
    % Ia and Ib must be discrete valued
    Ea = ml_alg_entropy_image(Ia);
    Eb = ml_alg_entropy_image(Ib);
    Eab = ml_alg_joint_entropy_images(Ia, Ib);
    
    mutualInformation = Ea + Eb - Eab;
end