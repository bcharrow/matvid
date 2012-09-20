clear all; 
close all;
clc;
fh = figure();
dot = plot(0, 1, 'r.');
xlim([-1, 4 * pi + 10]);
ylim([-5 5]);
ax = gca;
hold('on', ax);
set(ax, 'fontsize', 20);
xlabel('X (m)');
ylabel('Y (m)');
title('Particle Movie', 'fontsize', 30);

%% Create frames
fg = FrameGrabber.CreateDir(fh, 'MyParticleMovie');
fg.overwrite = true;
fg.transparency = false; % Set to true to demonstrate transparency
fg.rm() % Clear JPGs and PDFs that exist in the folder
xs = linspace(0, 4 * pi, 100);
ys = sin(xs);

if fg.transparency
    box_x = [-1 1 1 -1];
    box_y = [-1 -1 1 1];
    box_s = 1.0;
    box = patch(box_x, box_y, 'c', 'EdgeColor', 'white');
    alpha(box, '0.4');
end

for k = 1:length(xs)
    set(dot, 'XData', xs(k), 'YData', ys(k), 'MarkerSize', 10 * (xs(k) + 1));    
    if fg.transparency
        set(box, 'XData', box_s * box_x + xs(k), 'YData', box_s * box_y + ys(k));
        
    end
    drawnow();
    fg.grab()
end
%% Build movie
fc = FrameConverter('MyParticleMovie');
fc.convert('-resize 1024x1024\!'); % Default picture size is 512x512
fc.link();
fc.ffmpeg('-r 10');
