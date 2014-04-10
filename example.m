clear
clc

% Examples and test cases for the latex_fig program

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                  3d surface plot with transparency                  %%%
%%%       This is a good case to use some rasterized plot objects       %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
clf

% Set the default interpreter to 'none' to avoid warnings
%  from matlab's TeX interpreter
set(1,'DefaultTextInterpreter','none');
set(1,'position',[100 100 560 420]); %ensure consistent sizing
h = surf([x1 x2],[y1 y2],[z z],[z z]);
xlabel('$x$')
ylabel('$y$')
zlabel('$z$')
title({'\LaTeX{} Figure Demo','All text objects will be processed via \LaTeX.', ...
       'Symbol examples: \AR, $\ddagger$, $\clubsuit$, $\mho$'})

axis equal
box on
grid off
alpha(.8)
camlight %('headlight')
material shiny
shading interp
view(3)

latex_fig( 1, 'outfile1','-pdf','-png','-jpg','-eps', ...
           '-transparent',...
           '-rasterize', h, ...
           '-r150', ...
           '-latexpackages', {'\usepackage{amssymb}','\usepackage{ar}'}, ...
           '-crop', [.17 .05 .63 1.0] )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%             A simple 2D line plot, no rasterized objecs             %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x = linspace(0,2*pi);

figure(2)
clf
set(2,'DefaultTextInterpreter','none');
set(2,'position',[100 100 560 420]);
hold on
plot(x,sin(x),'k-','linewidth',2)
plot(x,sin(x).*cos(x),'k--','linewidth',2)
plot(x,sin(3*x),'k:','linewidth',2)
legend('$\sin(x)$','$\sin(x)\cos(x)$','$\sin(3x)$')
xlabel('$\theta$')
title('Some trigonometric functions')

latex_fig( 2, 'outfile2','-pdf','-png','-jpg','-eps', ...
           '-transparent','-r300','-q80','-autocrop')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%          A 2D filled contour plot with rasterized contours          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x = linspace(0,2*pi,200);
y = linspace(0,pi,200);
[x y] = meshgrid(x,y);
z = sin(2*x).*sin(2*y);

figure(3)
clf
set(3,'DefaultTextInterpreter','none');
set(3,'position',[100 100 560 320]);
[~,h]=contourf(x/pi,y/pi,z,50,'linestyle','none');
axis equal
axis tight
xlabel('$x/\pi$')
ylabel('$y/\pi$')
colorbar
text(.5,.5,{'There sure is','a lot going','on in this plot!'})

latex_fig( 3, 'outfile3','-pdf','-png','-jpg','-eps', ...
           '-transparent','-r300','-q80','-autocrop','-rasterize',h)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%        A more complex plot with multiple axes, colorbar, etc        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

figure(4)
clf

set(4,'DefaultTextInterpreter','none');
set(4,'position',[100 100 560 420],'color','w');

theta = linspace(0,pi/2,1000);
r0 = 1;
plot((1+.05*cos(15*theta)).*cos(theta),(1+.05*cos(15*theta)).*sin(theta),'linewidth',2)
legend('Squiggly curve')
axis([0 1.07 0 1.07])
set(gca,'xtick',[],'ytick',[],'color',[.8 .8 1],'box','off')

axes('position',[.05 .05 .5 .5])
h = surf([x1 x2],[y1 y2],[z z],[z z]);
text(-.7,-1,1.5,{'There sure is','a lot going','on in this plot!'})
xlabel('$x$')
ylabel('$y$')
zlabel('$z$')
title({'\LaTeX{} Figure Demo','All text objects will be processed via \LaTeX.', ...
       'Symbol examples: \AR, $\ddagger$, $\clubsuit$, $\mho$'})

axis equal
box on
grid off
alpha(.8)
camlight %('headlight')
material shiny
shading interp
colorbar
view(3)


latex_fig( 4, 'outfile4','-pdf','-png','-jpg','-eps', ...
           '-rasterize', h, ...
           '-r150', ...
           '-latexpackages', {'\usepackage{amssymb}','\usepackage{ar}'} )
