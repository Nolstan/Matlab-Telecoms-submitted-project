function R = network_design(cfg, outDir)
%NETWORK_DESIGN Create architecture and communication-chain diagrams.
f=figure('Visible','off','Color','w'); hold on; axis off;
xy=[0 2; 2 2; 4 3.4; 4 2; 4 .6];
edges=[1 2;2 3;2 4;2 5];
for k=1:size(edges,1)
    a=xy(edges(k,1),:); b=xy(edges(k,2),:); v=b-a;
    quiver(a(1),a(2),v(1),v(2),0,'Color',[0.00 0.42 0.72],'LineWidth',2,'MaxHeadSize',.18);
end
labels={'A: Central distribution','B: Intermediate node','C: Health centre','D: Secondary school','E: Information centre'};
for k=1:5
    plot(xy(k,1),xy(k,2),'o','MarkerSize',14,'MarkerFaceColor',[0.00 0.62 0.82],'MarkerEdgeColor','k','LineWidth',1.2);
    text(xy(k,1),xy(k,2)+.28,labels{k},'HorizontalAlignment','center','FontWeight','bold','Color','k');
end
text(.85,2.15,sprintf('%.0f km',cfg.distance_km(1)),'Color','k','FontWeight','bold');
text(3.1,2.9,sprintf('%.0f km',cfg.distance_km(2)),'Color','k','FontWeight','bold');
text(3.1,2.05,sprintf('%.0f km',cfg.distance_km(3)),'Color','k','FontWeight','bold');
text(3.1,1.0,sprintf('%.0f km',cfg.distance_km(4)),'Color','k','FontWeight','bold');
text(2,-.15,'Tree backhaul with a single intermediate branch point','HorizontalAlignment','center','Color','k');
title('Figure 1: Rural tree distribution topology','Color','k');
saveas(f,fullfile(outDir,'Figure_01_Rural_Network_Architecture.png')); close(f);
f=figure('Visible','off','Color','w'); axis off; hold on;
items={'Information source','Source encoding','Line encoding','Modulation','Transmitter','Channel','Receiver','Demodulation','Decoding','Destination'};
W=1.65; H=.62; gap=.25; yTop=2.0; yBottom=.65;
for k=1:numel(items)
    if k<=5, col=k-1; y=yTop; else, col=10-k; y=yBottom; end
    x=col*(W+gap);
    fc=[.82 .92 1]; if k==6, fc=[1 .84 .55]; end
    rectangle('Position',[x y W H],'Curvature',.05,'FaceColor',fc,'EdgeColor',[.00 .25 .45],'LineWidth',1.4);
    text(x+W/2,y+H/2,items{k},'HorizontalAlignment','center','FontSize',8,'Color','k');
    if k==5
        quiver(x+W/2,y,.0,-.88,0,'Color','k','LineWidth',1.2,'MaxHeadSize',.8);
    elseif k<5 || k>=6
        if k<5, dx=W+gap; dy=0; else, dx=-(W+gap); dy=0; end
        quiver(x+(dx>0)*W,y+H/2,dx,dy,0,'Color','k','LineWidth',1.2,'MaxHeadSize',.8);
    end
end
text(8.42,1.48,'Noise enters here','Color',[.75 .10 .08],'FontWeight','bold','HorizontalAlignment','center');
title('Figure 2: Digital communication system and noise entry','Color','k');
saveas(f,fullfile(outDir,'Figure_02_Communication_System_Block_Diagram.png')); close(f);
R.topology='Tree'; R.distances_km=cfg.distance_km;
R.totalAccessDistance_km=sum(cfg.distance_km);
R.alternative='Full mesh (conceptual)';
end
