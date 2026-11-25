function R = feeder_primary_constants(cfg,resDir,figDir)
%FEEDER_PRIMARY_CONSTANTS Coax model from R,L,G,C per metre.
% Z0=sqrt((R+j*w*L)/(G+j*w*C)); gamma=sqrt((R+j*w*L)(G+j*w*C));
% alpha_dB/100m=8.686*real(gamma)*100; GammaL=(ZL-Z0)/(ZL+Z0).
f=cfg.recommendedFrequency_Hz; w=2*pi*f;
Rohm=cfg.coaxResistance_ohm_per_m*sqrt(f/cfg.coaxReferenceFrequency_Hz);
L=cfg.coaxInductance_H_per_m; G=cfg.coaxConductance_S_per_m; C=cfg.coaxCapacitance_F_per_m;
Z0=sqrt((Rohm+1i*w*L)/(G+1i*w*C)); gamma=sqrt((Rohm+1i*w*L)*(G+1i*w*C));
alpha=real(gamma); beta=imag(gamma); alphaDb100=8.685889638*alpha*100;
velocity=w/beta; vf=velocity/299792458;
primary=table(f,Rohm,L,G,C,real(Z0),imag(Z0),abs(Z0),alpha,beta,alphaDb100,velocity,vf, ...
 'VariableNames',{'Frequency_Hz','R_ohm_per_m','L_H_per_m','G_S_per_m','C_F_per_m', ...
 'Z0_Real_ohm','Z0_Imag_ohm','Z0_Magnitude_ohm','Alpha_Np_per_m', ...
 'Beta_rad_per_m','Attenuation_dB_per_100m','PhaseVelocity_m_per_s','VelocityFactor'});
writetable(primary,fullfile(resDir,'Feeder_Primary_Constants.csv'));
dist=cfg.extendedLinkDistance_km*1000; ZL=cfg.feederLoad_ohm;
gl=(ZL-Z0)/(ZL+Z0); vswr=(1+abs(gl))/(1-abs(gl)); ret=-20*log10(abs(gl)); mis=-10*log10(1-abs(gl)^2);
atten=alphaDb100*cfg.feederLengths_m(:)/100; total=atten+mis;
perLink=table(cfg.extendedLinkNames(:),cfg.feederLengths_m(:),repmat(abs(Z0),numel(dist),1), ...
 repmat(abs(gl),numel(dist),1),atten,repmat(vswr,numel(dist),1),repmat(ret,numel(dist),1),repmat(mis,numel(dist),1),total, ...
 'VariableNames',{'Link','FeederLength_m','Z0Magnitude_ohm','ReflectionCoefficientMagnitude', ...
 'Attenuation_dB','VSWR','ReturnLoss_dB','MismatchLoss_dB','TotalFeederLoss_dB'});
writetable(perLink,fullfile(resDir,'Feeder_Per_Link.csv'));
x=cfg.feederLengthSweep_m(:); pathloss=20*log10(4*pi*dist(4)*f/299792458);
rx=cfg.recommendedTxPower_dBm+cfg.recommendedTxGain_dBi(4)+cfg.recommendedRxGain_dBi(4)-cfg.otherLoss_dB ...
 -pathloss-2*(alphaDb100*x/100+mis);
figh=figure('Visible','off','Color','w'); tiledlayout(1,2,'Padding','compact');
nexttile; plot(x,alphaDb100*x/100,'o-','LineWidth',1.8); xlabel('Feeder length (m)'); ylabel('One-way attenuation (dB)'); title('Primary-constant cable loss'); grid on;
nexttile; plot(x,rx,'s-','LineWidth',1.8); xlabel('Feeder length per end (m)'); ylabel('B-E received power (dBm)'); title('Effect on B-E receive power'); grid on;
ax=findall(figh,'Type','axes'); set(ax,'Color','w','XColor','k','YColor','k','FontSize',10);
saveas(figh,fullfile(figDir,'Figure_23_Feeder_Length_Effect.png')); close(figh);
stageGain=cfg.rxStageGain_dB(:);stageNf=cfg.rxStageNoiseFigure_dB(:);
stageGain(1)=-total(1);stageNf(1)=total(1);g=10.^(stageGain/10);F=10.^(stageNf/10);
Ftot=F(1);gp=g(1);for q=2:numel(F),Ftot=Ftot+(F(q)-1)/gp;gp=gp*g(q);end
R=struct('Primary',primary,'PerLink',perLink,'Z0_ohm',Z0,'Gamma',gamma, ...
 'ReceiverCascadeNoiseFigure_dB',10*log10(Ftot), ...
 'Alpha_Np_per_m',alpha,'Beta_rad_per_m',beta,'Attenuation_dB_per_100m',alphaDb100, ...
 'MismatchLoss_dB',mis,'TotalFeederLoss_dB',total);
end
