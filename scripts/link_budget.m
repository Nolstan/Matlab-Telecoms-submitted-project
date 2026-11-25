function R = link_budget(cfg, resDir, figDir)
%LINK_BUDGET Free-space link budget and receiver-threshold margins.
c=299792458; k=1.380649e-23; lambda=c/cfg.frequency_Hz; d=cfg.distance_km*1000;
fspl=20*log10(4*pi*d/lambda);
pr=cfg.txPower_dBm+cfg.txGain_dBi+cfg.rxGain_dBi-cfg.feederLoss_dB-cfg.otherLoss_dB-fspl;
noise=10*log10(k*cfg.noiseTemperature_K*cfg.bandwidth_Hz)+30+cfg.noiseFigure_dB;
snr=pr-noise; sensitivityMargin=pr-cfg.receiverSensitivity_dBm;
requiredRx=max(cfg.receiverSensitivity_dBm,noise+cfg.targetSNR_dB);
fadeMargin=pr-requiredRx;
fadeReserveMargin=fadeMargin-cfg.requiredFadeMargin_dB;
R=table(cfg.linkNames',cfg.distance_km',repmat(cfg.frequency_Hz/1e9,numel(d),1), ...
    repmat(lambda,numel(d),1),fspl',pr',repmat(noise,numel(d),1),snr', ...
    repmat(cfg.receiverSensitivity_dBm,numel(d),1),sensitivityMargin', ...
    repmat(requiredRx,numel(d),1),fadeMargin', ...
    repmat(cfg.requiredFadeMargin_dB,numel(d),1),fadeReserveMargin', ...
    'VariableNames',{'Link','Distance_km','Frequency_GHz','Wavelength_m','PathLoss_dB', ...
    'ReceivedPower_dBm','NoisePower_dBm','SNR_dB','Sensitivity_dBm', ...
    'SensitivityMargin_dB','RequiredRxForTarget_dBm','MarginToTarget_dB', ...
    'RequiredFadeMargin_dB','ResidualFadeMargin_dB'});
writetable(R,fullfile(resDir,'Link_Budget_Results.csv'));
f=figure('Visible','off','Color','w'); tiledlayout(1,2,'Padding','compact');
nexttile; bar(fspl,'FaceColor',[0.00 0.42 0.72]); title('Free-space path loss'); ylabel('Path loss (dB)'); xticklabels({'A-B','B-C','B-D','B-E'}); grid on;
nexttile; bar([pr' requiredRx*ones(1,numel(d))']); title('Received power vs required level'); ylabel('Power (dBm)'); xticklabels({'A-B','B-C','B-D','B-E'}); legend('Received','Required for target SNR','Location','best'); grid on;
ax=findall(f,'Type','axes'); set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_03_Link_Budget_Results.png')); close(f);
f=figure('Visible','off','Color','w'); tiledlayout(2,1,'Padding','compact');
nexttile; plot(cfg.distance_km,fspl,'o-','LineWidth',2,'Color',[0.00 0.42 0.72]); ylabel('Path loss (dB)'); title('Path loss versus distance'); grid on;
nexttile; plot(cfg.distance_km,pr,'s-','LineWidth',2,'Color',[0.85 0.25 0.10]); ylabel('Received power (dBm)'); xlabel('Distance (km)'); title('Received power versus distance'); grid on;
ax=findall(f,'Type','axes'); set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_04_Path_Loss_and_Received_Power.png')); close(f);
R.Properties.Description='Hypothetical free-space link budget; assumptions are in config.m.';
end
