function [video] = ml_cai_io_scopereadavi(filename)

%v1 = VideoReader(filename, 'VideoFormat', 'Grayscale', 'BitsPerPixel', 8);
%frames = zeros(v1.Height, v1.Width, 1);

% v = VideoReader(filename);
% 
% i = 1;
% while hasFrame(v)
%     frames(:,:,i) = uint8(readFrame(v));
%     i = i + 1;
% end
% i = i - 1;

o = VideoReader( filename );
vidWidth = o.Width;
vidHeight = o.Height;
mov = struct('cdata', zeros(vidHeight, vidWidth,1,'uint8'), 'colormap', []);

k = 0;
while hasFrame(o)
    k = k + 1;
    mov(k).cdata = readFrame(o);
end
if k == 0
    error('No frames were read from %s', filename);
end

video.numFrames = length(mov);
video.filename = filename;
video.width = vidWidth;
video.height = vidHeight;
video.mov = mov;

end
