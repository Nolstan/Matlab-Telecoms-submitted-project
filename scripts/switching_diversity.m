function R = switching_diversity(cfg, resDir, figDir)
%SWITCHING_DIVERSITY Two-hop packet delay and independent branch outage model.
packetBits=12000; rate=cfg.bandwidth_Hz;
% Worst destination path is A-B plus B-C (8+4 km).
pathKm=cfg.distance_km(1)+max(cfg.distance_km(2:4)); hops=2;
tx=packetBits/rate*1000*hops;
prop=pathKm*1000/299792458*1000;
proc=cfg.processingDelay_ms*hops; queue=cfg.queueingDelay_ms*hops;
total=tx+prop+proc+queue;
R.TransmissionDelay_ms=tx; R.PropagationDelay_ms=prop;
R.ProcessingDelay_ms=proc; R.QueueingDelay_ms=queue;
R.TotalPacketDelay_ms=total; R.WorstPath_km=pathKm;
R.SwitchingMethod='Packet switching';
% Independent selection branches: outage occurs only when every branch is down.
p=cfg.diversityBranchOutageProbability; single=p; multi=p^cfg.diversityBranches;
diversity=table(cfg.diversityBranches,p,single,multi, ...
 'VariableNames',{'SelectionBranches','PerBranchOutageProbability','SingleBranchOutageProbability','SelectionOutageProbability'});
writetable(diversity,fullfile(resDir,'Diversity_Results.csv'));
delay=table(packetBits,rate/1e6,pathKm,tx,prop,proc,queue,total, ...
 'VariableNames',{'PacketLength_bits','LinkRate_Mbps','WorstPath_km','TransmissionDelay_ms','PropagationDelay_ms','ProcessingDelay_ms','QueueingDelay_ms','TotalPacketDelay_ms'});
writetable(delay,fullfile(resDir,'Switching_Delay_Results.csv'));
f=figure('Visible','off','Color','w'); bar([single multi],'FaceColor',[0.00 0.42 0.72]); xticklabels({'Single branch','Selection diversity'}); ylabel('Outage probability'); title('Independent-branch diversity illustration'); grid on;
ax=gca; set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_13_Diversity_Performance.png')); close(f);
end
