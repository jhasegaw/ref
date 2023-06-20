%
% m-file that generates Figure 5.6 of the PhD thesis:
% 	title = "A Study on the Speech Acoustic-to-Articulatory
%                Mapping Using Morphological Constraints", 
%	author = "Hani Yehia",
%	school = "Nagoya University",
%	year = "Nagoya, 1997",
%       note = "http://www.hip.atr.co.jp/~yehia/Publications/thesis.ps.gz" 
%
v = version;
v = str2num(v(1));
load pca;
load areas;
N = 10;
M = 4;
Q = size(Y1,1);
Un = U1(:,1:N);
Ym = Y1(:,1:M);

area = aux_area(P(4)+8:P(4)+8+Q,:);
area=[(2*area(1,:)+area(2,:))/3;...
    (area(1:Q-2,:)+2*area(2:Q-1,:)+area(3:Q,:))/4;...
    (area(Q-1,:)+2*area(Q,:))/3];
L = area_length(P(4)+8:P(4)+8+Q);
L = [(2*L(1)+L(2))/3 (L(1:Q-2)+2*L(2:Q-1)+L(3:Q))/4 (L(Q-1)+2*L(Q))/3];
X = [log(area) norma*L']' - x_mean * ones(1,Q);

fmt = area2fmt(area, L', 3);
[area4, L4] = invert(fmt',M,N,'fourier');
area4 = area4';

clf
set(gcf,'Position',[50 800 400 600],'PaperPosition',[1 1 10 15]/2.54);
figure(gcf)
subplot(3,1,2)
position = get(gca,'position');
position(4) = 2.5*position(4);
position(3) = 1*position(3);
position(2) = 1.2*position(2);
[M,N] = size(area4);
clear X;
for i = 1:M
  Section_length(i) = L(i) / N;
  X(i,:) = 0:Section_length(i):N*Section_length(i);
end
Y = [0:1/50:(M-1)/50]' * ones(1,N+1);
Z = [area4, area4(:,N)]/2;
Z = [(Z(1,:)+Z(2,:))/2;...
    (Z(1:M-2,:)+Z(2:M-1,:)+Z(3:M,:))/3;...
    (Z(M-1,:)+Z(M,:))/2];
mesh(X,Y,Z);
if v >= 5, colormap(1-white); else, colormap(white); end
set(gca,'fontsize',12,'position',position);
hold on
view(135,45);
h = get(gca,'children');
set(h(1),'meshstyle','both');
if v >= 5
  plot3(X(:,1),Y(:,1),Z(:,1),'k-');
  plot3(X(:,N+1),Y(:,N+1),Z(:,N+1),'k-');
else
  plot3(X(:,1),Y(:,1),Z(:,1),'w-');
  plot3(X(:,N+1),Y(:,N+1),Z(:,N+1),'w-');
end
axis([0 18 0 0.2 0 5]);
set(gca,'xtick',0:5:20,...
        'ytick',0:0.1:0.2,...
	'ztick',0:5:10);
text('position',[18 0 6],'string','Fourier (All Terms)','fontsize',12,...
    'HorizontalAlignment','left');
ylabel('Time (s)','fontsize',12);
xlabel('Position (cm)','fontsize',12);
zlabel('Area (cm2)')
hold off


subplot(3,1,3)
position = get(gca,'position');
% position(3) = 1.1*position(3);
F = fmt/1000;
F4 = area2fmt(area4,L4',3)/1000;
t = 0.01:0.02:0.19;
max_difF4 = max(abs(100*(F4 - F)./F));
if v >= 5
  plot(t,F4(:,1),'k-',t,F4(:,2),'k-',t,F4(:,3),'k-');
else
  plot(t,F4(:,1),'w-',t,F4(:,2),'w-',t,F4(:,3),'w-');
end
hold on
plot(t,F(:,1),'r--',t,F(:,2),'r--',t,F(:,3),'r--');
set(gca,'xtick',[],'ytick',-5:5:5,'fontsize',12,'position',position);
axis([0 0.2 0.01 3.8])
set(gca,'ytick',0:4);
set(gca,'xtick',0:0.1:0.2);
xlabel('Time (s)');
ylabel('Frequency (kHz)');
text('position',[0.195,0.7],...
	'string',['F1: ',num2str(max_difF4(1),2),'%'],...
	'HorizontalAlignment','right','fontsize',10)
text('position',[0.195,1.2],...
	'string',['Max. Diff. F2: ',num2str(max_difF4(2),2),'%'],...
	'HorizontalAlignment','right','fontsize',10)
text('position',[0.195,1.7],...
	'string',['F3: ',num2str(max_difF4(3),2),'%'],...
	'HorizontalAlignment','right','fontsize',10)
set(get(gca,'xlabel'),'fontsize',12);
set(get(gca,'ylabel'),'fontsize',12);
title('Formant Frequency Trajectories','FontSize',12)
set(gca,'fontsize',12);
hold off
%
% Uncomment next line to generate eps-file of the figure.
%
% print -depsc fig5_6
