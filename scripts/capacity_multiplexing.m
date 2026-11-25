function R = capacity_multiplexing(cfg, resDir, figDir)
%CAPACITY_MULTIPLEXING Fixed-slot TDM allocation and ideal Shannon limit.
demand=sum(cfg.trafficMbps); n=numel(cfg.trafficMbps);
payloadPerFrame=cfg.tdmSlotPayload_bits*n;
grossPerFrame=payloadPerFrame+cfg.tdmFrameOverhead_bits+cfg.tdmGuardBits_perSlot*n;
grossRate=grossPerFrame*cfg.tdmFrameRate_Hz/1e6;
payloadRate=payloadPerFrame*cfg.tdmFrameRate_Hz/1e6;
snr=10^(cfg.targetSNR_dB/10); shannon=cfg.bandwidth_Hz*log2(1+snr)/1e6;
util=demand/payloadRate*100; remaining=payloadRate-demand;
R=table(demand,grossRate,payloadRate,util,remaining,shannon, ...
 'VariableNames',{'AggregateDemand_Mbps','TDMGrossRate_Mbps','TDMNetPayloadRate_Mbps', ...
 'Utilization_percent','UnallocatedPayloadCapacity_Mbps','ShannonCapacity_Mbps'});
writetable(R,fullfile(resDir,'TDM_Capacity_Results.csv'));
slotRate=cfg.tdmSlotPayload_bits*cfg.tdmFrameRate_Hz/1e6;
service=table({'Health Centre';'Secondary School';'Information Centre'},cfg.trafficMbps(:), ...
 repmat(slotRate,n,1),slotRate-cfg.trafficMbps(:), ...
 'VariableNames',{'ServiceSite','Demand_Mbps','AllocatedTdmSlotRate_Mbps','UnusedSlotCapacity_Mbps'});
writetable(service,fullfile(resDir,'TDM_Traffic_Allocation.csv'));
f=figure('Visible','off','Color','w'); tiledlayout(1,2,'Padding','compact');
nexttile; bar([cfg.trafficMbps(:) repmat(slotRate,n,1)]);
xticklabels({'Health centre','Secondary school','Information centre'}); ylabel('Rate (Mbps)');
title('Per-site demand and TDM slot'); legend('Demand','Allocated slot','Location','best'); grid on;
ylim([0 slotRate*1.2]);
nexttile; bar([demand payloadRate]); xticklabels({'Aggregate demand','TDM net payload'}); ylabel('Rate (Mbps)');
title(sprintf('Trunk utilization: %.1f%%',util)); grid on;
ax=findall(f,'Type','axes'); set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_14_Traffic_Capacity.png')); close(f);
f=figure('Visible','off','Color','w'); snrdb=0:30; cap=cfg.bandwidth_Hz*log2(1+10.^(snrdb/10))/1e6;
plot(snrdb,cap,'LineWidth',2,'Color',[0.00 0.42 0.72]); hold on;
plot(cfg.targetSNR_dB,shannon,'o','MarkerFaceColor',[0.85 0.20 0.10],'MarkerEdgeColor','k','MarkerSize',8);
xlabel('SNR (dB)'); ylabel('Ideal Shannon capacity (Mbps)'); title('Shannon capacity versus SNR'); grid on;
legend('C = B log_2(1+SNR)','Selected target SNR','Location','northwest');
ax=gca; set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_12_Shannon_Capacity.png')); close(f);
end
