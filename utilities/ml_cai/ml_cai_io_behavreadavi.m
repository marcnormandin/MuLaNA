function [ video ] = ml_cai_io_behavreadavi( behavFilename )
o = VideoReader( behavFilename );
vidWidth = o.Width;
vidHeight = o.Height;
mov = struct('cdata', zeros(vidHeight, vidWidth,3,'uint8'), 'colormap', []);

k = 0;
while hasFrame(o)
    k = k + 1;
    mov(k).cdata = readFrame(o);
end
if k == 0
    error('No frames were read from %s', behavFilename);
end

video.frameRate = o.FrameRate;
video.numFrames = length(mov);
video.filename = behavFilename;
video.width = vidWidth;
video.height = vidHeight;
video.mov = mov;

end % function
