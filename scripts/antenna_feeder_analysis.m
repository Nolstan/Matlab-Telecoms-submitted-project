function R = antenna_feeder_analysis(cfg, figDir, resDir)
%ANTENNA_FEEDER_ANALYSIS Compare illustrative antenna patterns and feeder mismatch.
theta=linspace(-180,180,721);
% Gaussian main-lobe approximations, normalized to peak power and truncated at -35 dB.
dish=max(10^(-35/10),10.^(-12.041*(theta/8).^2));
panel=max(10^(-35/10),10.^(-12.041*(theta/35).^2));
f=figure('Visible','off','Color','w'); polarplot(deg2rad(theta),dish,'LineWidth',2,'Color',[0.00 0.42 0.72]); hold on;
polarplot(deg2rad(theta),panel,'LineWidth',2,'Color',[0.85 0.20 0.10]); title('Illustrative normalized antenna power patterns','Color','k');
rlim([0 1]); rticks([0 .25 .5 .75 1]);
lgd=legend('Parabolic dish (narrow beam)','Directional panel (wider beam)','Location','southoutside');
set(lgd,'Color','w','TextColor','k','EdgeColor','k');
ax=gca; set(ax,'Color','w','ThetaColor','k','RColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_06_Antenna_Comparison.png')); close(f);
antenna=table({'Parabolic dish';'Directional panel'},[23;18],[8;35], ...
    {'Long point-to-point backhaul';'Shorter distribution links'}, ...
    'VariableNames',{'Antenna','IllustrativeGain_dBi','IllustrativeBeamwidth_deg','TypicalUse'});
writetable(antenna,fullfile(resDir,'Antenna_Comparison.csv'));
Z0=cfg.feederZ0_ohm; ZL=cfg.feederLoad_ohm; gamma=(ZL-Z0)/(ZL+Z0);
vswr=(1+abs(gamma))/(1-abs(gamma)); returnLoss=-20*log10(abs(gamma));
mismatchLoss=-10*log10(1-abs(gamma)^2);
atten=cfg.feederAlpha_dB_per_100m*cfg.feederLength_m/100;
R=table(Z0,real(ZL),imag(ZL),abs(ZL),cfg.feederLength_m,atten,abs(gamma),vswr,returnLoss,mismatchLoss, ...
 'VariableNames',{'Z0_ohm','LoadResistance_ohm','LoadReactance_ohm','LoadMagnitude_ohm', ...
 'Length_m','Attenuation_dB','ReflectionCoefficientMagnitude','VSWR','ReturnLoss_dB','MismatchLoss_dB'});
writetable(R,fullfile(resDir,'Feeder_Results.csv'));
f=figure('Visible','off','Color','w'); bar([atten mismatchLoss],'FaceColor',[0.00 0.42 0.72]); xticklabels({'Feeder attenuation','Mismatch loss'}); ylabel('Loss (dB)'); title('Feeder loss components'); grid on;
ax=gca; set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_07_Feeder_Analysis.png')); close(f);
end
