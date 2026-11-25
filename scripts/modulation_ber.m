function R = modulation_ber(cfg, resDir, figDir)
%MODULATION_BER BPSK AWGN BER simulation and theoretical reference.
rng(cfg.randomSeed); N=cfg.berBits; eb=cfg.berEbN0dB; ber=zeros(size(eb)); theory=.5*erfc(sqrt(10.^(eb/10)));
bits=randi([0 1],N,1); symbols=2*bits-1;
for k=1:numel(eb)
    sigma=sqrt(1/(2*10^(eb(k)/10))); rx=symbols+sigma*randn(N,1);
    ber(k)=mean((rx>=0)~=bits);
end
R=table(eb',ber',theory','VariableNames',{'EbN0_dB','SimulatedBER','TheoreticalBER'});
writetable(R,fullfile(resDir,'BER_Results.csv'));
f=figure('Visible','off','Color','w'); semilogy(eb,max(ber,1/N),'o-','LineWidth',1.8,'Color',[0.00 0.42 0.72]); hold on;
semilogy(eb,theory,'--','LineWidth',1.8,'Color',[0.85 0.20 0.10]); grid on; xlabel('E_b/N_0 (dB)'); ylabel('BER'); title('BPSK over AWGN'); legend('Monte Carlo','Theory','Location','southwest');
ax=gca; set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_11_BER_vs_EbN0.png')); close(f);
f=figure('Visible','off','Color','w'); subplot(1,2,1); plot([-1 1],[0 0],'o','MarkerSize',9,'LineWidth',1.8,'Color',[0.00 0.42 0.72]); grid on; axis equal; xlim([-1.5 1.5]); ylim([-1 1]); xlabel('In-phase'); ylabel('Quadrature'); title('BPSK');
subplot(1,2,2); q=1/sqrt(2); plot([q -q q -q],[q q -q -q],'s','MarkerSize',8,'LineWidth',1.8,'Color',[0.85 0.20 0.10]); grid on; axis equal; xlim([-1.2 1.2]); ylim([-1.2 1.2]); xlabel('In-phase'); ylabel('Quadrature'); title('Unit-energy QPSK');
ax=findall(f,'Type','axes'); set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_10_Modulation_Constellations.png')); close(f);
end
