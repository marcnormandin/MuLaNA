function [medianFrame] = ml_cai_behavcam_median_frame_compute(video)
    I1 = zeros(size(video.mov(1).cdata,1), size(video.mov(1).cdata,2));
    I2 = zeros(size(video.mov(1).cdata,1), size(video.mov(1).cdata,2));
    I3 = zeros(size(video.mov(1).cdata,1), size(video.mov(1).cdata,2));

    for n = 1:length(video.mov)
        I1(:,:,n) = double(video.mov(n).cdata(:,:,1));
        I2(:,:,n) = double(video.mov(n).cdata(:,:,2));
        I3(:,:,n) = double(video.mov(n).cdata(:,:,3));
    end

    %%
    M1 = median(I1, 3);
    M2 = median(I2, 3);
    M3 = median(I3, 3);

    %%
    Mframe = zeros(size(M1,1), size(M1,2), 3);
    Mframe(:,:,1) = M1;
    Mframe(:,:,2) = M2;
    Mframe(:,:,3) = M3;

    medianFrame = uint8(Mframe);

end % function

