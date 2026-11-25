function R = propagation_fresnel(cfg,resDir,figDir)
%PROPAGATION_FRESNEL Midpoint first-zone clearance including effective-earth curvature.
c=299792458;lambda=c/cfg.recommendedFrequency_Hz;pairs=cfg.extendedLinkPairs;
d=cfg.extendedLinkDistance_km(:);n=numel(d);d1=d/2;d2=d/2;
r1=sqrt(lambda.*d*1000/4);losMid=((cfg.antennaHeight_m(pairs(:,1))+cfg.antennaHeight_m(pairs(:,2)))/2);losMid=losMid(:);
ob=repmat(cfg.obstacleHeight_m(1),n,1);earth=d1.*d2/(12.74*cfg.effectiveEarthRadiusFactor);
clearance=losMid-ob-earth;required=.6*r1;margin=clearance-required;
additional=max(0,-margin);meets=margin>=0;
R=table(cfg.extendedLinkNames(:),d,r1,required,losMid,ob,earth,clearance,margin,additional,meets, ...
 'VariableNames',{'Link','Distance_km','FresnelRadius_m','Required60Percent_m', ...
 'MidpointLineOfSightHeight_m','AssumedObstacleHeight_m','EarthBulge_m', ...
 'AvailableClearanceAfterEarthBulge_m','ClearanceMargin_m','AdditionalMidpointHeightNeeded_m','Meets60PercentClearance'});
writetable(R,fullfile(resDir,'Fresnel_Clearance_Results.csv'));
f=figure('Visible','off','Color','w');bar(margin,'FaceColor',[0 .42 .72]);hold on;yline(0,'r--','60% boundary');
xticks(1:n);xticklabels(cfg.extendedLinkNames);xtickangle(30);ylabel('Clearance margin after earth bulge (m)');
title('Midpoint first Fresnel clearance (assumed flat terrain)');grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_05_Fresnel_Clearance.png'));close(f);
R=struct('Table',R,'MidpointLineOfSightHeight_m',losMid,'Required60Percent_m',required);
end
