function R = duplex_services(cfg,resDir,figDir)
%DUPLEX_SERVICES Classify service directions and calculate TDD/FDD allocations.
% Guard fraction=guard/frame; net direction rate=BW*eta*(1-overhead)*direction share.
c=299792458; grossRate=cfg.recommendedBandwidth_Hz/(1+cfg.rolloff)*cfg.modulationBitsPerSymbol*cfg.codingRate/1e6;
longest=max(cfg.distance_km)*1000; prop_ms=longest/c*1000;
guard_ms=2*prop_ms+cfg.tddSwitchingTime_us/1000;
overhead=guard_ms/cfg.tddFrameDuration_ms;
available=max(0,1-overhead); dlShare=cfg.tddDownlinkFraction; ulShare=1-dlShare;
dlRate=grossRate*available*dlShare; ulRate=grossRate*available*ulShare;
serviceNames={'Telemedicine video';'Voice';'E-learning download';'Web browsing';'Telemetry/records upload'};
serviceMode={'Full-duplex';'Full-duplex';'Simplex downlink';'Half-duplex';'Simplex uplink'};
dataRate=[cfg.telemedicineRate_Mbps;cfg.voiceRate_kbps/1000;cfg.elearningRate_Mbps;cfg.webRate_Mbps;cfg.telemetryRate_kbps/1000];
rfBW=dataRate/(cfg.modulationBitsPerSymbol*cfg.codingRate)*(1+cfg.rolloff);
baseBW=dataRate/2;
signalType=repmat({'Digital'},5,1);
S=table(serviceNames,serviceMode,signalType,dataRate,baseBW,rfBW, ...
 'VariableNames',{'SignalOrService','DuplexClass','SignalType','SourceRate_Mbps','BasebandBandwidthEstimate_MHz','RequiredRFBandwidth_MHz'});
writetable(S,fullfile(resDir,'Signal_Classification.csv'));
linkDuplex=repmat({'TDD, shared channel'},numel(cfg.distance_km),1);
links=table(cfg.linkNames',cfg.distance_km',linkDuplex,repmat(cfg.tddFrameDuration_ms,4,1), ...
 repmat(guard_ms,4,1),repmat(overhead*100,4,1),repmat(dlRate,4,1),repmat(ulRate,4,1), ...
 'VariableNames',{'Link','Distance_km','DuplexMethod','FrameDuration_ms','GuardTime_ms', ...
 'GuardOverhead_percent','NetDownlinkRate_Mbps','NetUplinkRate_Mbps'});
fddDl=cfg.recommendedBandwidth_Hz*cfg.fddDownlinkFraction/1e6;
fddUl=cfg.recommendedBandwidth_Hz*(1-cfg.fddDownlinkFraction)/1e6;
comparison=table({'TDD';'FDD'},[cfg.recommendedBandwidth_Hz/1e6;fddDl+fddUl], ...
 [dlRate;fddDl*grossRate/(cfg.recommendedBandwidth_Hz/1e6)], ...
 [ulRate;fddUl*grossRate/(cfg.recommendedBandwidth_Hz/1e6)], ...
 [overhead*100;0],{'Time-separated directions on shared RF channel';'Paired frequency channels, no TDD guard interval'}, ...
 'VariableNames',{'DuplexMethod','AllocatedBandwidth_MHz','DownlinkRate_Mbps','UplinkRate_Mbps','GuardOverhead_percent','Description'});
links=[links; table({'TDD/FDD comparison';'TDD/FDD comparison'},[0;0],{'See comparison';'See comparison'}, ...
 [cfg.tddFrameDuration_ms;cfg.tddFrameDuration_ms],[guard_ms;0],[overhead*100;0], ...
 [dlRate;fddDl*grossRate/(cfg.recommendedBandwidth_Hz/1e6)],[ulRate;fddUl*grossRate/(cfg.recommendedBandwidth_Hz/1e6)], ...
 'VariableNames',links.Properties.VariableNames)];
writetable(links,fullfile(resDir,'Duplex_Plan.csv'));
writetable(comparison,fullfile(resDir,'Duplex_Method_Comparison.csv'));
f=figure('Visible','off','Color','w'); hold on;
frame=cfg.tddFrameDuration_ms; dl=frame*available*dlShare; ul=frame*available*ulShare;
rectangle('Position',[0 0 dl 1],'FaceColor',[.12 .52 .82],'EdgeColor','k');
rectangle('Position',[dl 0 guard_ms 1],'FaceColor',[.9 .25 .12],'EdgeColor','k');
rectangle('Position',[dl+guard_ms 0 ul 1],'FaceColor',[.12 .66 .35],'EdgeColor','k');
text(dl/2,.5,sprintf('Downlink %.1f%%',dlShare*100),'HorizontalAlignment','center','Color','w','FontWeight','bold');
text(dl+guard_ms/2,.5,sprintf('Guard\n%.3f ms',guard_ms),'HorizontalAlignment','center','Color','w','FontWeight','bold');
text(dl+guard_ms+ul/2,.5,sprintf('Uplink %.1f%%',ulShare*100),'HorizontalAlignment','center','Color','w','FontWeight','bold');
xlim([0 frame]);ylim([0 1]);yticks([]);xlabel('TDD frame time (ms)');title(sprintf('TDD frame; guard overhead %.1f%%',overhead*100));grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_19_Duplex_TDD_Frame.png'));close(f);
R=struct('ServiceClassification',S,'LinkPlan',links,'MethodComparison',comparison, ...
 'GuardTime_ms',guard_ms,'OverheadFraction',overhead,'GrossCapacity_Mbps',grossRate, ...
 'DownlinkRate_Mbps',dlRate,'UplinkRate_Mbps',ulRate,'TddFrameDuration_ms',frame);
end
