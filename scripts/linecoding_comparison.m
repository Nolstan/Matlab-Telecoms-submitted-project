function R = linecoding_comparison(cfg,resDir,figDir)
%LINECODING_COMPARISON Long-sequence line-code PSD using a hand Welch periodogram.
% PSD averages windowed FFT periodograms; 99% bandwidth integrates one-sided PSD.
rng(cfg.randomSeed+1);bits=randi([0 1],cfg.lineCodeBits,1);s=cfg.lineCodeOversampling;
nrz=repelem(2*bits-1,s); man=zeros(cfg.lineCodeBits*s,1);
for k=1:cfg.lineCodeBits
 ix=(k-1)*s+(1:s); half=s/2;
 if bits(k),man(ix)=[ones(half,1);-ones(half,1)];else,man(ix)=[-ones(half,1);ones(half,1)];end
end
ami=zeros(cfg.lineCodeBits*s,1);pol=1;
for k=1:cfg.lineCodeBits
 if bits(k),ami((k-1)*s+(1:s))=pol;pol=-pol;end
end
signals={nrz,man,ami};names={'NRZ-L','Manchester','AMI'};
firstNull=[1 2 1];suitability={'Simple; possible DC and long transition-free runs'; ...
 'Self-clocking; higher bandwidth';'Low DC; timing can fail on long zero runs'};
rows=cell(3,7);figh=figure('Visible','off','Color','w');hold on;cols=lines(3);faxis=[];
for k=1:3
 [freq,psd]=welch_onesided(signals{k},s,cfg.psdWindowSamples,cfg.psdOverlapFraction);
 faxis=freq;cum=cumtrapz(freq,psd);if cum(end)>0,cum=cum/cum(end);end
 id=find(cum>=.99,1);bw99=freq(id);
 sig=signals{k};mu=mean(sig);p0=psd(1);edges=find(diff(sig)~=0);density=numel(edges)/cfg.lineCodeBits;
 if isempty(edges),runmax=cfg.lineCodeBits;else,gaps=diff([0;edges(:);numel(sig)])/s;runmax=max(gaps);end
 rows(k,:)={names{k},mu,p0,firstNull(k),bw99,density,runmax};
 plot(freq,10*log10(max(psd,realmin)),'LineWidth',1.6,'Color',cols(k,:));
end
% Theoretical normalized spectra for NRZ-L and Manchester.
f=faxis;sn=ones(size(f));nz=f~=0;sn(nz)=(sin(pi*f(nz))./(pi*f(nz))).^2;
sm=ones(size(f));sm(nz)=(sin(pi*f(nz)/2)./(pi*f(nz)/2)).^2.*sin(pi*f(nz)/2).^2;
plot(f,10*log10(max(sn,realmin)),'k--','LineWidth',1);plot(f,10*log10(max(sm,realmin)),'k:','LineWidth',1.4);
xlim([0 min(s/2,4)]);xlabel('Frequency (cycles per bit)');ylabel('PSD (dB, normalized units)');
title('Line-code PSD from 10,000 random bits');legend('NRZ-L estimate','Manchester estimate','AMI estimate','NRZ-L theory','Manchester theory','Location','northeast');grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(figh,fullfile(figDir,'Figure_24_LineCode_PSD.png'));close(figh);
R=cell2table(rows,'VariableNames',{'LineCode','MeanLevel','PSD_at_0Hz','FirstNull_cycles_per_bit', ...
 '99PercentPowerBandwidth_cycles_per_bit','TransitionDensity_per_bit','LongestRunWithoutTransition_bits'});
R.Suitability=suitability(:);
writetable(R,fullfile(resDir,'LineCode_Comparison.csv'));
fid=fopen(fullfile(resDir,'LineCode_Comparison_Note.txt'),'w');
fprintf(fid,'Line codes are baseband representations. RF modulation and radio channel bandwidth are selected separately in modulation_comparison.m.\n');fclose(fid);
end
function [f,P] = welch_onesided(x,fs,nwin,overlapFraction)
nwin=min(nwin,numel(x));hop=max(1,round(nwin*(1-overlapFraction)));nfft=2^nextpow2(nwin);
w=.54-.46*cos(2*pi*(0:nwin-1)'/(nwin-1));starts=1:hop:(numel(x)-nwin+1);P=zeros(nfft/2+1,1);
for i=1:numel(starts)
 seg=x(starts(i):starts(i)+nwin-1);Y=fft((seg-mean(seg)).*w,nfft);
 P=P+abs(Y(1:nfft/2+1)).^2/(fs*sum(w.^2));
end
P=P/max(1,numel(starts));P(2:end-1)=2*P(2:end-1);f=(0:nfft/2)'*fs/nfft;
end
