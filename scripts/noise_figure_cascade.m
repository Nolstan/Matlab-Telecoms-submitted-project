function R = noise_figure_cascade(cfg,linkFull,feeder,resDir,figDir)
%NOISE_FIGURE_CASCADE Friis cascaded receiver noise figure in linear units.
% Ftotal=F1+(F2-1)/G1+(F3-1)/(G1*G2)+...; noise floor=-174+10log10(B)+NF.
stageGain=cfg.rxStageGain_dB(:);stageNf=cfg.rxStageNoiseFigure_dB(:);
feedLoss=feeder.PerLink.TotalFeederLoss_dB(1);stageGain(1)=-feedLoss;stageNf(1)=feedLoss;
g=10.^(stageGain/10); nf=10.^(stageNf/10);
[baseF,stageCumulative]=friis(nf,g);
scenarios={'Baseline: feeder/filter before LNA';'LNA before preselector';'No feeder loss ahead of LNA'; ...
 'LNA gain 10 dB';'LNA gain 30 dB'};
vals=zeros(5,1);gains=zeros(5,1);orders=cell(5,1);
vals(1)=10*log10(baseF);gains(1)=cfg.rxStageGain_dB(3);orders{1}='Feeder, preselector, LNA, filter, mixer, IF';
% Swap preselector and LNA to show ordering impact.
[f2,~]=friis(nf([1 3 2 4 5 6]),g([1 3 2 4 5 6]));vals(2)=10*log10(f2);gains(2)=cfg.rxStageGain_dB(3);orders{2}='Feeder, LNA, preselector, filter, mixer, IF';
nNo=nf;nNo(1)=1;gNo=g;gNo(1)=1;[f3,~]=friis(nNo,gNo);vals(3)=10*log10(f3);gains(3)=cfg.rxStageGain_dB(3);orders{3}='No pre-LNA feeder loss';
lnagain=[10 30];
for k=4:5
 gg=g;gg(3)=10.^(lnagain(k-3)/10);
 [ff,~]=friis(nf,gg);vals(k)=10*log10(ff);gains(k)=10*log10(gg(3));orders{k}=sprintf('Baseline, LNA gain %.0f dB',gains(k));
end
noiseDb=10*log10(1.380649e-23*cfg.noiseTemperature_K*cfg.recommendedBandwidth_Hz)+30+vals;
[weakRx,weakIx]=min(linkFull.ReceivedPower_dBm);
snr=weakRx-noiseDb;
R=table(scenarios,orders,gains,vals,noiseDb,repmat(weakRx,5,1),snr, ...
 'VariableNames',{'Scenario','StageOrder','LNAGain_dB','CascadeNoiseFigure_dB','NoiseFloor_dBm', ...
 'WeakLinkReceivedPower_dBm','WeakLinkSNR_dB'});
R.WeakestLink= repmat(linkFull.Link(weakIx),height(R),1);
writetable(R,fullfile(resDir,'Noise_Figure_Cascade.csv'));
stageNames=cfg.rxStageNames(:);stageGain=stageGain(:);stageNf=stageNf(:);
stageTable=table((1:6)',stageNames,stageGain,stageNf,stageCumulative, ...
 'VariableNames',{'StageNumber','Stage','Gain_dB','NoiseFigure_dB','CumulativeNoiseFigure_dB'});
writetable(stageTable,fullfile(resDir,'Noise_Figure_Cascade_Stages.csv'));
f=figure('Visible','off','Color','w');bar(vals,'FaceColor',[0 .42 .72]);
xticklabels({'Baseline','LNA first','No feeder','LNA 10 dB','LNA 30 dB'});ylabel('Cascade noise figure (dB)');
title(sprintf('Receiver Friis cascade; baseline %.2f dB',vals(1)));grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_25_Noise_Figure_Cascade.png'));close(f);
end
function [F,cumulative] = friis(Fi,Gi)
F=Fi(1);gainProduct=Gi(1);cumulative=zeros(numel(Fi),1);cumulative(1)=10*log10(F);
for k=2:numel(Fi),F=F+(Fi(k)-1)/gainProduct;gainProduct=gainProduct*Gi(k);cumulative(k)=10*log10(F);end
end
