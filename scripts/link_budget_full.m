function R = link_budget_full(cfg,feeder,resDir,figDir)
%LINK_BUDGET_FULL Seven-path budget using one receiver Friis cascade.
% A link has one TX feeder and one RX feeder; both losses are deducted once.
c=299792458;k=1.380649e-23;f=cfg.recommendedFrequency_Hz;lambda=c/f;
d=cfg.extendedLinkDistance_km(:);n=numel(d);pairs=cfg.extendedLinkPairs;
fspl=20*log10(4*pi*d*1000/lambda);loss=feeder.PerLink.TotalFeederLoss_dB(:);
txGain=cfg.recommendedTxGain_dBi(:);rxGain=cfg.recommendedRxGain_dBi(:);
if numel(txGain)==1,txGain=repmat(txGain,n,1);end
if numel(rxGain)==1,rxGain=repmat(rxGain,n,1);end
power=cfg.recommendedTxPower_dBm+zeros(n,1);
eirp=power+txGain-loss;eirpW=10.^((eirp-30)/10);
rx=power+txGain+rxGain-2*loss-cfg.otherLoss_dB-fspl;
noiseFigure=feeder.ReceiverCascadeNoiseFigure_dB;
noise=10*log10(k*cfg.noiseTemperature_K*cfg.recommendedBandwidth_Hz)+30+noiseFigure;
snr=rx-noise;req=max(cfg.receiverSensitivity_dBm,noise+cfg.targetSNR_dB);
margin=rx-req;residual=margin-cfg.requiredFadeMargin_dB;
band=repmat({'SHF'},n,1);bandNum=repmat(10,n,1);if f<3e9,band(:)={'UHF'};bandNum(:)=9;end
R=table(cfg.extendedLinkNames(:),pairs(:,1),pairs(:,2),repmat(f/1e9,n,1),band,bandNum,d, ...
 repmat(lambda,n,1),power,txGain,rxGain,loss,feeder.PerLink.MismatchLoss_dB(:), ...
 eirp,eirpW,fspl,rx,repmat(noise,n,1),repmat(noiseFigure,n,1),snr, ...
 repmat(req,n,1),margin,residual, ...
 'VariableNames',{'Link','TxSiteIndex','RxSiteIndex','Frequency_GHz','ITU_Band','ITU_Band_Number', ...
 'Distance_km','Wavelength_m','TxPower_dBm','TxAntennaGain_dBi','RxAntennaGain_dBi', ...
 'FeederLossPerEnd_dB','MismatchLoss_dB','EIRP_dBm','EIRP_W','FSPL_dB', ...
 'ReceivedPower_dBm','NoiseFloor_dBm','ReceiverNoiseFigure_dB','SNR_dB','RequiredRx_dBm', ...
 'FadeMargin_dB','ResidualFadeMargin_dB'});
writetable(R,fullfile(resDir,'Link_Budget_Full.csv'));
freq=linspace(.9e9,10e9,300);figh=figure('Visible','off','Color','w');hold on;colors=lines(n);
for j=1:n,curve=20*log10(4*pi*d(j)*1000*freq/c);plot(freq/1e9,curve,'LineWidth',1.5,'Color',colors(j,:));end
xline(cfg.alternativeFrequency_Hz/1e9,'--','Alternative 2.4 GHz');xline(f/1e9,'--','Selected 0.9 GHz');
xlabel('Frequency (GHz)');ylabel('Free-space path loss (dB)');title('FSPL versus frequency for seven modeled paths');
legend(cfg.extendedLinkNames,'Location','northwest');grid on;set(gca,'Color','w','XColor','k','YColor','k');
saveas(figh,fullfile(figDir,'Figure_21_Path_Loss_vs_Frequency.png'));close(figh);
end
