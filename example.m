clear
clc

%create an interesting randomized corkscrew surface:
R1 = 0.35; R2 = 1; N=200; NN=2.33;
theta0 = rand*2*pi;
theta = linspace(theta0,theta0+NN*2*pi,N);
x1 = ((R1+R2)/2-(R2-R1)/2*sin((theta(:)-theta0)/2/NN)).*cos(theta(:));
y1 = ((R1+R2)/2-(R2-R1)/2*sin((theta(:)-theta0)/2/NN)).*sin(theta(:));
x2 = ((R1+R2)/2+(R2-R1)/2*sin((theta(:)-theta0)/2/NN)).*cos(theta(:));
y2 = ((R1+R2)/2+(R2-R1)/2*sin((theta(:)-theta0)/2/NN)).*sin(theta(:));
z = linspace(0,2,N)';
% z = zeros(size(theta(:)));
for i=1:7
    z = z+(rand-.5)/10*sin(i*theta(:)/NN)+(rand-.5)/10*cos(i*theta(:)/NN);
end

figure(1)
set(1,'position',[100 100 560 420])
clf
h = surf([x1 x2],[y1 y2],[z z],[z z]);
xlabel('$x$')
ylabel('$y$')
zlabel('$z$')
title({'\LaTeX{} Figure Demo','All text objects will be processed via \LaTeX.','Symbol examples: \AR, $\ddagger$, $\clubsuit$, $\mho$'})

axis equal
box on
grid off
alpha(.8)
camlight %('headlight')
material shiny
shading interp
view(3)

latex_fig( 1, 'outfile','-pdf','-png','-jpg','-eps','-tiff', ...
           '-nocrop',...
           '-transparent',...
           '-rasterize', h, ...
           '-r150', ...
           '-latexpackages', {'\usepackage{amssymb}','\usepackage{ar}'}, ...
           '-crop', [.17 .05 .63 1.0] )


