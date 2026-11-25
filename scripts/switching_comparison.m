function R = switching_comparison(cfg,resDir,figDir)
%SWITCHING_COMPARISON Circuit reservation versus M/M/1 packet queues.
% Per-hop M/M/1 system time W=1/(mu-lambda), lambda=rho*mu; store-and-forward adds L/R per hop.
c=299792458; pathKm=cfg.distance_km(1)+cfg.distance_km(4); hops=2;
prop_ms=pathKm*1000/c*1000; setup_ms=2*prop_ms+cfg.circuitSetupProcessing_ms;
rho=cfg.switchingUtilization(:); sizes=cfg.switchingMessageBytes(:)*8;
packetDelay=nan(numel(rho),numel(sizes)); circuitDelay=zeros(numel(sizes),1); block=erlang_b(cfg.offeredCircuitLoad_Erlang,cfg.circuitCount);
rows={};
for m=1:numel(sizes)
 bits=sizes(m); mu=cfg.queueServiceRate_Mbps*1e6/bits;
 circuitDelay(m)=setup_ms+2*(bits/(cfg.circuitReservedRate_Mbps*1e6)*1000)+prop_ms+cfg.processingDelay_ms*hops;
 for i=1:numel(rho)
  W=1/(mu-rho(i)*mu); % seconds per hop, includes service and queue wait.
  pkt=2*W*1000+prop_ms+cfg.queueProcessing_ms_per_hop*hops;
  packetDelay(i,m)=pkt;
  rows(end+1,:)={bits/8,rho(i),mu,rho(i)*100,cfg.circuitReservedRate_Mbps, ...
   setup_ms,circuitDelay(m),pkt,block}; %#ok<AGROW>
 end
end
R=cell2table(rows,'VariableNames',{'MessageSize_bytes','PacketServerUtilization_fraction', ...
 'ServiceRate_per_s','Utilization_percent','CircuitReservedRate_Mbps', ...
 'CircuitSetup_ms','CircuitEndToEndDelay_ms','PacketEndToEndDelay_ms','CircuitBlockingProbability'});
[~,idx50]=min(abs(rho-0.5));
recommendation='Packet switching recommended for bursty multi-service traffic at low/moderate load; circuit reservation has predictable delay but can block.';
if all(circuitDelay<packetDelay(idx50,:).'), recommendation='Circuit switching has lower modeled delay at 50% utilization; packet switching remains more flexible for bursty data.'; end
fid=fopen(fullfile(resDir,'Switching_Recommendation.txt'),'w');fprintf(fid,'%s\nBlocking probability (Erlang B): %.6f\n',recommendation,block);fclose(fid);
f=figure('Visible','off','Color','w');tiledlayout(1,2,'Padding','compact');
for m=1:numel(sizes)
 nexttile;semilogy(rho*100,packetDelay(:,m),'o-','LineWidth',1.8);hold on;
 semilogy(rho*100,circuitDelay(m)*ones(size(rho)),'--','LineWidth',1.8);
 yline(cfg.delayTarget_ms,'k:','Delay target');xlabel('Packet-server utilization (%)');ylabel('End-to-end delay (ms)');
 title(sprintf('Message size %.4g MB',sizes(m)/8e6));legend('Packet switching','Circuit switching','Location','best');grid on;
end
ax=findall(f,'Type','axes');set(ax,'Color','w','XColor','k','YColor','k','FontSize',10);
saveas(f,fullfile(figDir,'Figure_20_Circuit_vs_Packet.png'));close(f);
R.Properties.Description=recommendation;
R.Recommendation=repmat({recommendation},height(R),1);
writetable(R,fullfile(resDir,'Switching_Comparison.csv'));
end
function b=erlang_b(A,N)
% Erlang-B recursion avoids factorial overflow: Bn=A*B(n-1)/(n+A*B(n-1)).
b=1;for n=1:N,b=A*b/(n+A*b);end
end
