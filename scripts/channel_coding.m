function R = channel_coding(cfg, resDir, figDir)
%CHANNEL_CODING Energy-normalized repetition-code BER with majority decoding.
% For fixed information-bit energy, each of the three repeated bits has Eb/3.
eb=cfg.berEbN0dB; base=.5*erfc(sqrt(10.^(eb/10)));
berResults=readtable(fullfile(resDir,'BER_Results.csv'));
if cfg.repetitionFactor~=3
    error('This simple majority-decoder model requires repetitionFactor = 3.');
end
p=.5*erfc(sqrt(10.^(eb/10)/cfg.repetitionFactor));
coded=3*p.^2.*(1-p)+p.^3;
R=table(eb',base',coded','VariableNames',{'EbN0_dB','UncodedBPSK_BER','Repetition3_BER_Approx'});
writetable(R,fullfile(resDir,'Channel_Coding_Results.csv'));
f=figure('Visible','off','Color','w');
simulated=berResults.SimulatedBER;
semilogy(eb,max(simulated,1/cfg.berBits),'o-','LineWidth',1.8,'Color',[0.00 0.42 0.72]); hold on;
semilogy(eb,base,'--','LineWidth',1.8,'Color',[0.85 0.20 0.10]);
semilogy(eb,max(coded,realmin),'s-','LineWidth',1.8,'Color',[0.10 0.60 0.25]);
grid on; xlabel('E_b/N_0 per information bit (dB)'); ylabel('BER');
title('BPSK AWGN and rate-1/3 repetition code');
legend('Uncoded Monte Carlo (floor = 1/N)','Uncoded theory','Repetition-3 theory, fixed information-bit energy','Location','southwest');
ax=gca; set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(figDir,'Figure_11_BER_vs_EbN0.png')); close(f);
end
