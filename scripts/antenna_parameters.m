function R = antenna_parameters(cfg,resDir,figDir)
%ANTENNA_PARAMETERS Compare assumed antenna gain, directivity and pattern properties.
% Approximate directivity D=41253/(HPBWE*HPBWH); efficiency=G/D in linear units.
names=cfg.antennaNames(:);gain=cfg.antennaGain_dBi(:);be=cfg.antennaHpbwE_deg(:);bh=cfg.antennaHpbwH_deg(:);
directivity=10*log10(41253./(be.*bh));eff=10.^((gain-directivity)/10);
constraint={'Rigid tower and precise alignment';'Moderate wind load; panel mount';'Small aperture; boom alignment'};
measure=repmat({'Gain: substitution/comparison in an antenna range; pattern: rotate on positioner against reference; HPBW: -3 dB points; F/B: 0/180 degree levels; bandwidth: VNA S11/VSWR.'},3,1);
R=table(names,gain,directivity,eff,be,bh,cfg.antennaFrontBack_dB(:), ...
 cfg.antennaBandwidth_MHz(:),cfg.antennaPolarization(:),cfg.antennaMountHeight_m(:),constraint,measure, ...
 'VariableNames',{'Antenna_Assumed','Gain_dBi','Directivity_dBi','RadiationEfficiency', ...
 'HPBWE_deg','HPBWH_deg','FrontToBack_dB','VSWR2Bandwidth_MHz','Polarization', ...
 'TypicalMountHeight_m','PracticalConstraint','HowToMeasure'});
writetable(R,fullfile(resDir,'Antenna_Parameters.csv'));
linkNames={'A-B';'B-C';'B-D';'B-E';'A-C backup';'A-D backup';'A-E backup'};
tx={'Parabolic dish';'Directional panel';'Directional panel';'Directional panel'; ...
 'Directional panel';'Directional panel';'Directional panel'};
rx={'Parabolic dish';'Yagi antenna';'Yagi antenna';'Yagi antenna'; ...
 'Yagi antenna';'Yagi antenna';'Yagi antenna'};
reason={'Highest illustrative gain on longest trunk';'Panel sector at B, compact directional terminal'; ...
 'Panel sector at B, compact directional terminal';'Panel sector at B, compact directional terminal'; ...
 'Backup direct path; directional end antennas';'Backup direct path; directional end antennas';'Backup direct path; directional end antennas'};
writetable(table(linkNames,tx,rx,reason,'VariableNames',{'Link','TxAntenna','RxAntenna','Reason'}), ...
 fullfile(resDir,'Link_Antenna_Justification.csv'));
theta=linspace(-180,180,721);f=figure('Visible','off','Color','w');tiledlayout(2,3,'Padding','compact');
for k=1:3
 pattern=max(10^(cfg.antennaPatternFloor_dB/10),10.^(-12.041*(theta/be(k)).^2));
 nexttile(k);plot(theta,10*log10(pattern),'LineWidth',1.6);xlim([-90 90]);ylim([cfg.antennaPatternFloor_dB 1]);
 xlabel('Angle (deg)');ylabel('Normalized power (dB)');title(names{k});grid on;
 nexttile(k+3);polarplot(deg2rad(theta),pattern,'LineWidth',1.6);rlim([0 1]);title(names{k});
 ax=gca;set(ax,'Color','w','ThetaColor','k','RColor','k');
end
ax=findall(f,'Type','axes');for k=1:numel(ax),try,set(ax(k),'Color','w','XColor','k','YColor','k');catch,end,end
saveas(f,fullfile(figDir,'Figure_22_Antenna_Parameters.png'));close(f);
end
