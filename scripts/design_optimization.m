function R = design_optimization(cfg,linkFull,topo,capacity,resDir,figDir)
%DESIGN_OPTIMIZATION Weighted score across frequency, antenna, topology, modulation and power choices.
% Each criterion is min-max normalized; beneficial scores rise with metric, costs/complexity invert.
rows={};labels={};groups={};rate=[];margin=[];avail=[];coverage=[];complexity=[];cost=[];
noise=linkFull.NoiseFloor_dBm(1);
reqRx=linkFull.RequiredRx_dBm(1)+cfg.requiredFadeMargin_dB;
% Candidate frequency options use free-space loss and the configured skin-effect cable model.
for i=1:numel(cfg.frequencyCandidates_Hz)
 f=cfg.frequencyCandidates_Hz(i);lam=299792458/f;[loss,mis]=feeder_loss_at_frequency(cfg,f);
 pl=20*log10(4*pi*cfg.extendedLinkDistance_km(:)*1000/lam);
 pr=cfg.recommendedTxPower_dBm+mean(cfg.recommendedTxGain_dBi)+mean(cfg.recommendedRxGain_dBi)-2*loss-cfg.otherLoss_dB-pl;
 m=min(pr-reqRx);a=exp(-10^(-m/10)); % single-branch Rayleigh availability.
 rate(end+1)=capacity.RadioNetCapacity_Mbps;margin(end+1)=m;avail(end+1)=a; %#ok<AGROW>
 coverage(end+1)=coverage_radius(cfg,f,mean(cfg.recommendedTxGain_dBi),mean(cfg.recommendedRxGain_dBi),loss,linkFull.ReceiverNoiseFigure_dB(1)); %#ok<AGROW>
 complexity(end+1)=cfg.frequencyComplexity(i);cost(end+1)=redundant_equipment_cost(cfg); %#ok<AGROW>
 groups{end+1}='Frequency';labels{end+1}=sprintf('%.3g MHz',f/1e6); %#ok<AGROW>
end
% Antenna candidates apply the same candidate at each radio end for a conservative comparison.
for i=1:numel(cfg.antennaNames)
 gain=cfg.antennaGain_dBi(i);pl=linkFull.FSPL_dB;
 pr=cfg.recommendedTxPower_dBm+gain+gain-2*mean(linkFull.FeederLossPerEnd_dB)-cfg.otherLoss_dB-pl;
 m=min(pr-reqRx);rate(end+1)=capacity.RadioNetCapacity_Mbps;margin(end+1)=m;avail(end+1)=exp(-10^(-m/10)); %#ok<AGROW>
 coverage(end+1)=coverage_radius(cfg,cfg.recommendedFrequency_Hz,gain,gain,mean(linkFull.FeederLossPerEnd_dB),linkFull.ReceiverNoiseFigure_dB(1)); %#ok<AGROW>
 complexity(end+1)=cfg.antennaComplexity(i);cost(end+1)=antenna_option_cost(cfg,cfg.antennaCost_USD(i)); %#ok<AGROW>
 groups{end+1}='Antenna';labels{end+1}=cfg.antennaNames{i}; %#ok<AGROW>
end
% Topology candidates use the computed per-site and per-link comparison table.
tn=unique(topo.Topology,'stable');
for i=1:numel(tn)
 idx=strcmp(topo.Topology,tn{i});t=topo(idx,:);idxRemote=~strcmp(t.DestinationSite,'A');
 rate(end+1)=capacity.RadioNetCapacity_Mbps;margin(end+1)=min(t.WorstPathMargin_dB(idxRemote)); %#ok<AGROW>
 avail(end+1)=min(t.SiteAvailability(idxRemote));coverage(end+1)=max(vecnorm(cfg.siteCoordinates_km(idxRemote,:)-cfg.siteCoordinates_km(1,:),2,2)); %#ok<AGROW>
 complexity(end+1)=cfg.topologyComplexity(i);cost(end+1)=max(t.TotalEquipmentCost_USD); %#ok<AGROW>
 groups{end+1}='Topology';labels{end+1}=tn{i}; %#ok<AGROW>
end
% RF choices use the configured minimum required SNR thresholds.
weakSNR=min(linkFull.SNR_dB);
for i=1:numel(cfg.modulationCandidates)
 m=weakSNR-cfg.modulationRequiredSNR_dB(i)-cfg.requiredFadeMargin_dB;
 spectral=[1 2 4];rate(end+1)=cfg.recommendedBandwidth_Hz/(1+cfg.rolloff)*spectral(i)*cfg.codingRate*(1-duplex_overhead(cfg))/1e6; %#ok<AGROW>
 margin(end+1)=m;avail(end+1)=exp(-10^(-m/10));coverage(end+1)=coverage_radius(cfg,cfg.recommendedFrequency_Hz,mean(cfg.recommendedTxGain_dBi),mean(cfg.recommendedRxGain_dBi),mean(linkFull.FeederLossPerEnd_dB),linkFull.ReceiverNoiseFigure_dB(1)); %#ok<AGROW>
 complexity(end+1)=cfg.modulationComplexity(i);cost(end+1)=redundant_equipment_cost(cfg); %#ok<AGROW>
 groups{end+1}='Modulation';labels{end+1}=cfg.modulationCandidates{i}; %#ok<AGROW>
end
% Transmit-power alternatives leave every other default parameter fixed.
for i=1:numel(cfg.powerCandidates_dBm)
 pr=linkFull.ReceivedPower_dBm(1:4)+(cfg.powerCandidates_dBm(i)-cfg.recommendedTxPower_dBm);m=min(pr-reqRx);
 rate(end+1)=capacity.RadioNetCapacity_Mbps;margin(end+1)=m;avail(end+1)=exp(-10^(-m/10)); %#ok<AGROW>
 coverage(end+1)=coverage_radius(cfg,cfg.recommendedFrequency_Hz,mean(cfg.recommendedTxGain_dBi),mean(cfg.recommendedRxGain_dBi),mean(linkFull.FeederLossPerEnd_dB),linkFull.ReceiverNoiseFigure_dB(1)) ...
  *10^((cfg.powerCandidates_dBm(i)-cfg.recommendedTxPower_dBm)/20); %#ok<AGROW>
 complexity(end+1)=cfg.complexityScores(i);cost(end+1)=redundant_equipment_cost(cfg)*cfg.powerCostMultiplier(i); %#ok<AGROW>
 groups{end+1}='Transmit power';labels{end+1}=sprintf('%.0f dBm',cfg.powerCandidates_dBm(i)); %#ok<AGROW>
end
% Normalize to [0,1] for a reproducible decision matrix.
metrics=[rate(:) margin(:) avail(:) coverage(:) complexity(:) cost(:)];
norms=zeros(size(metrics));
for j=1:size(metrics,2),lo=min(metrics(:,j));hi=max(metrics(:,j));if hi>lo,norms(:,j)=(metrics(:,j)-lo)/(hi-lo);else,norms(:,j)=ones(size(metrics,1),1);end,end
norms(:,5)=1-norms(:,5);norms(:,6)=1-norms(:,6);
% Reliability receives a target-relative score: options below the configured
% availability target receive zero, while target-compliant options approach one.
norms(:,3)=max(0,min(1,(avail(:)-cfg.availabilityTarget)/(1-cfg.availabilityTarget)));
w=cfg.designWeights(:);scores=norms*w;w2=w;w2(6)=w2(6)*cfg.weightSensitivityCostMultiplier;w2=w2/sum(w2);scores2=norms*w2;
feasible=(rate(:)>=cfg.trunkRateTarget_Mbps)&(margin(:)>=0)&(avail(:)>=cfg.availabilityTarget);
if ~any(feasible),error('No candidate satisfies the throughput, margin and availability constraints.');end
scores(~feasible)=0;scores2(~feasible)=0;[~,best]=max(scores);[~,best2]=max(scores2);
R=table(groups(:),labels(:),rate(:),margin(:),avail(:),feasible,coverage(:),complexity(:),cost(:), ...
 norms(:,1),norms(:,2),norms(:,3),norms(:,4),norms(:,5),norms(:,6),scores,scores2, ...
 repmat(best,numel(rate),1), ...
 'VariableNames',{'ChoiceGroup','Option','Throughput_Mbps','MinimumMargin_dB','Availability','MeetsHardConstraints', ...
 'CoverageOrReach_km','ComplexityScore_1to5','Cost_USD','NormThroughput','NormMargin', ...
 'NormAvailability','NormCoverage','NormComplexity','NormCost','WeightedScore', ...
 'ScoreWithDoubleCostWeight','BaseWinnerRow'});
writetable(R,fullfile(resDir,'Optimization_Decision_Matrix.csv'));
[~,ix]=sort(scores,'descend');f=figure('Visible','off','Color','w');bar(scores(ix),'FaceColor',[0 .42 .72]);
xticklabels(labels(ix));xtickangle(35);ylabel('Weighted normalized score');title(sprintf('Weighted design comparison: top option %s',labels{best}));grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_32_Decision_Matrix_Scores.png'));close(f);
% Sensitivity: weakest-link margin versus frequency and distance, plus cost-weight rank.
sensRows={};freqs=cfg.frequencyCandidates_Hz;distGrid=linspace(min(cfg.extendedLinkDistance_km),max(cfg.extendedLinkDistance_km)*2,50);
for i=1:numel(freqs)
 [loss,~]=feeder_loss_at_frequency(cfg,freqs(i));
 for k=1:numel(distGrid)
  pl=20*log10(4*pi*distGrid(k)*1000*freqs(i)/299792458);
  m=cfg.recommendedTxPower_dBm+mean(cfg.recommendedTxGain_dBi)+mean(cfg.recommendedRxGain_dBi)-2*loss-cfg.otherLoss_dB-pl-reqRx;
  sensRows(end+1,:)={freqs(i)/1e9,distGrid(k),m}; %#ok<AGROW>
 end
end
Sensitivity=cell2table(sensRows,'VariableNames',{'Frequency_GHz','Distance_km','ResidualMargin_dB'});
writetable(Sensitivity,fullfile(resDir,'Optimization_Sensitivity.csv'));
f=figure('Visible','off','Color','w');tiledlayout(1,2,'Padding','compact');nexttile;hold on;
for i=1:numel(freqs),idx=abs(Sensitivity.Frequency_GHz-freqs(i)/1e9)<1e-9;plot(Sensitivity.Distance_km(idx),Sensitivity.ResidualMargin_dB(idx),'LineWidth',1.8);end
xlabel('Link distance (km)');ylabel('Residual margin (dB)');title('Margin versus frequency and distance');legend('900 MHz','2.4 GHz','5.8 GHz','Location','best');grid on;
nexttile;bar([scores scores2]);xticklabels(labels);xtickangle(35);ylabel('Weighted score');title(sprintf('Cost weight x%.1f changes winner: %s to %s',cfg.weightSensitivityCostMultiplier,labels{best},labels{best2}));legend('Base weights','Higher cost weight','Location','best');grid on;
ax=findall(f,'Type','axes');set(ax,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_33_Sensitivity_Analysis.png'));close(f);
fid=fopen(fullfile(resDir,'Optimization_Recommendation.txt'),'w');fprintf(fid,'Highest weighted option: %s (%s), score %.3f. With cost weight multiplied by %.2f, winner: %s (%s).\n',groups{best},labels{best},scores(best),cfg.weightSensitivityCostMultiplier,groups{best2},labels{best2});fclose(fid);
end
function oh=duplex_overhead(cfg)
c=299792458;d=max(cfg.distance_km)*1000;oh=(2*d/c*1000+cfg.tddSwitchingTime_us/1000)/cfg.tddFrameDuration_ms;
end
function r=coverage_radius(cfg,f,gt,gr,loss,nf)
noise=10*log10(1.380649e-23*cfg.noiseTemperature_K*cfg.recommendedBandwidth_Hz)+30+nf;
req=max(cfg.receiverSensitivity_dBm,noise+cfg.targetSNR_dB)+cfg.requiredFadeMargin_dB;
budget=cfg.recommendedTxPower_dBm+gt+gr-2*loss-cfg.otherLoss_dB-req;
r=(299792458/f)/(4*pi)*10^(budget/20)/1000;
end
function [loss,mis]=feeder_loss_at_frequency(cfg,f)
R=cfg.coaxResistance_ohm_per_m*sqrt(f/cfg.coaxReferenceFrequency_Hz);w=2*pi*f;
L=cfg.coaxInductance_H_per_m;G=cfg.coaxConductance_S_per_m;C=cfg.coaxCapacitance_F_per_m;
z=sqrt((R+1i*w*L)/(G+1i*w*C));g=sqrt((R+1i*w*L)*(G+1i*w*C));
gamma=(cfg.feederLoad_ohm-z)/(cfg.feederLoad_ohm+z);mis=-10*log10(1-abs(gamma)^2);
loss=8.685889638*real(g)*cfg.feederLength_m/100+mis;
end
function c=redundant_equipment_cost(cfg)
nlinks=cfg.redundantTopologyLinkCount;ant=cfg.redundantTopologyAntennaCounts;
c=nlinks*cfg.radioUnitsPerLink*cfg.radioCost_USD+ant(1)*cfg.dishCost_USD+ant(2)*cfg.panelCost_USD+ant(3)*cfg.yagiCost_USD ...
 +nlinks*cfg.feederRunsPerLink*cfg.feederLength_m*cfg.feederCost_USD_per_m ...
 +cfg.connectorCountPerLink*nlinks*cfg.connectorCost_USD+cfg.siteCount*(cfg.mastCost_USD+cfg.powerBackupCost_USD+cfg.lightningProtectionCost_USD);
end
function c=antenna_option_cost(cfg,unitAntennaCost)
c=cfg.siteCount*(cfg.mastCost_USD+cfg.powerBackupCost_USD+cfg.lightningProtectionCost_USD) ...
 +14*(cfg.radioCost_USD+unitAntennaCost+cfg.feederCost_USD_per_m*cfg.feederLength_m+cfg.connectorCost_USD);
end
