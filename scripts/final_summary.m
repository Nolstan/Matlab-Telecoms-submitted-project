function R = final_summary(cfg, link, capacity, resDir, figDir)
%FINAL_SUMMARY Collect core design metrics and save summary.
R=table(mean(link.ReceivedPower_dBm),min(link.MarginToTarget_dB),capacity.AggregateDemand_Mbps, ...
 min(link.ResidualFadeMargin_dB),capacity.ShannonCapacity_Mbps,capacity.Utilization_percent, ...
 'VariableNames',{'MeanReceivedPower_dBm','MinimumMarginToTarget_dB','TrafficDemand_Mbps', ...
 'MinimumResidualFadeMargin_dB','ShannonCapacity_Mbps','TDMUtilization_percent'});
writetable(R,fullfile(resDir,'Final_System_Summary.csv'));
f=figure('Visible','off','Color','w'); tl=tiledlayout(f,1,2,'Padding','compact');
ax1=nexttile(tl); bar(ax1,link.ResidualFadeMargin_dB,'FaceColor',[0.00 0.42 0.72]); hold(ax1,'on'); yline(ax1,0,'k--');
xticklabels(ax1,{'A-B','B-C','B-D','B-E'}); ylabel(ax1,'Residual margin after fade reserve (dB)'); title(ax1,'Link fade reserve'); grid(ax1,'on');
ylim(ax1,[-1 max(link.ResidualFadeMargin_dB)+2]);
ax2=nexttile(tl); bar(ax2,[capacity.AggregateDemand_Mbps capacity.TDMNetPayloadRate_Mbps]);
xticklabels(ax2,{'Traffic demand','TDM payload'}); ylabel(ax2,'Rate (Mbps)'); title(ax2,'Traffic capacity check'); grid(ax2,'on');
ylim(ax2,[0 max(capacity.TDMNetPayloadRate_Mbps)*1.2]);
ax1.Title.Color='k'; ax2.Title.Color='k';
ax=findall(f,'Type','axes'); set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_16_Final_System_Summary.png')); close(f);
end
