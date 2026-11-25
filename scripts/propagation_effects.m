function R = propagation_effects(cfg,fresnel,link,resDir,figDir)
%PROPAGATION_EFFECTS Per-path propagation estimates and idealized Rayleigh outage.
% Site terrain and correlated/common-cause failures are not represented.
c=299792458;lambda=c/cfg.recommendedFrequency_Hz;n=height(link);d=link.Distance_km(:);
pairs=cfg.extendedLinkPairs;d1=d/2;d2=d/2;
earth=d1.*d2/(12.74*cfg.effectiveEarthRadiusFactor);
r1=sqrt(lambda.*(d1*1000).*(d2*1000)./((d1+d2)*1000));
los=fresnel.MidpointLineOfSightHeight_m(:);ob=repmat(cfg.obstacleHeight_m(1),n,1);
available=los-ob-earth;clearMargin=available-.6*r1;
hObs=ob-los+earth;v=hObs.*sqrt(2*(d1+d2)*1000./(lambda.*d1.*1000.*d2.*1000));
diffLoss=zeros(n,1);mask=v>-.78;diffLoss(mask)=6.9+20*log10(sqrt((v(mask)-.1).^2+1)+v(mask)-.1);
gammaRain=cfg.rainK_assumed*cfg.rainRate_mm_per_h^cfg.rainAlpha_assumed;
reduction=1./(1+cfg.rainPathReductionCoeff*sqrt(d*gammaRain));rainLoss=gammaRain*d.*reduction;
FM=link.ResidualFadeMargin_dB;outage=1-exp(-10.^(-FM/10));availability=1-outage;
fd=(cfg.mobileSpeed_kmh/3.6)*cfg.recommendedFrequency_Hz/c;
mode=repmat({'LOS space-wave; terrain profile not surveyed'},n,1);
R=table(link.Link,d,mode,earth,r1,available,clearMargin,v,diffLoss,repmat(gammaRain,n,1), ...
 reduction,rainLoss,FM,outage,availability,repmat(cfg.gasAttenuation_dB_per_km_assumed,n,1), ...
 repmat(fd,n,1),'VariableNames',{'Link','Distance_km','DominantMode','EarthBulge_m', ...
 'FresnelRadius_m','AvailableClearanceAfterEarthBulge_m','MarginAfter60PercentFresnel_m', ...
 'KnifeEdgeNu','KnifeEdgeLoss_dB','RainSpecificAttenuation_dB_per_km','RainPathReductionFactor', ...
 'RainAttenuation_dB','ResidualFadeMargin_dB','RayleighOutageProbability','RayleighAvailability', ...
 'AssumedGasAttenuation_dB_per_km','DopplerAt100kmh_Hz'});
writetable(R,fullfile(resDir,'Propagation_Effects.csv'));
writetable(R(:,{'Link','ResidualFadeMargin_dB','RayleighOutageProbability','RayleighAvailability'}), ...
 fullfile(resDir,'Link_Availability.csv'));
branch=cfg.diversityBranchCounts(:);target=cfg.diversityOutageTarget;needed=zeros(size(branch));
for q=1:numel(branch),needed(q)=-10*log10(-log(1-target^(1/branch(q))));end
gain=needed(1)-needed;D=table(branch,repmat(target,numel(branch),1),needed,gain, ...
 'VariableNames',{'IndependentSelectionBranches','OutageTarget','FadeMarginRequired_dB','GainVersusSingleBranch_dB'});
writetable(D,fullfile(resDir,'Diversity_Gain.csv'));
f=figure('Visible','off','Color','w');tiledlayout(1,2,'Padding','compact');
nexttile;bar(rainLoss,'FaceColor',[0 .42 .72]);xticks(1:n);xticklabels(link.Link);xtickangle(30);ylabel('Rain attenuation (dB)');title('Illustrative rain attenuation');grid on;
nexttile;bar(availability,'FaceColor',[.85 .2 .1]);xticks(1:n);xticklabels(link.Link);xtickangle(30);ylabel('Availability');title('Single-link Rayleigh model');ylim([0 1]);grid on;
ax=findall(f,'Type','axes');set(ax,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_30_Propagation_Effects.png'));close(f);
fid=fopen(fullfile(resDir,'Propagation_Assumptions.txt'),'w');
fprintf(fid,['Availability uses Pout=1-exp(-10^(-M/10)) with residual fade margin M and an ideal Rayleigh envelope. ', ...
 'This is a statistical single-link estimate, not measured uptime. Topology redundancy assumes independent radio path outages; shared power, structures, weather, interference and site failures are excluded. ', ...
 'Fresnel and earth-curvature checks use flat-ground assumed heights, not terrain data. Rain k=%.5g and alpha=%.3f are illustrative, not a verified ITU-R lookup. ', ...
 'Gas attenuation %.3f dB/km is assumed; fixed-site Doppler is near zero (100 km/h comparison %.1f Hz).\n'], ...
 cfg.rainK_assumed,cfg.rainAlpha_assumed,cfg.gasAttenuation_dB_per_km_assumed,fd);fclose(fid);
end
