function R = modulation_comparison(cfg,linkFull,duplex,resDir,figDir)
%MODULATION_COMPARISON Monte Carlo BPSK/QPSK, 16-QAM theory and Hamming(7,4).
% Q(x)=0.5*erfc(x/sqrt(2)); BPSK/QPSK Pb=Q(sqrt(2*Eb/N0)).
% Hamming coded symbol energy is Es=(4/7)Eb; all BER calculations use Eb per information bit.
eb=cfg.berComparisonEbN0_dB(:);mods={'BPSK';'QPSK';'16-QAM'};allRows={};simB=nan(numel(eb),1);simQ=nan(numel(eb),1);errB=zeros(numel(eb),1);errQ=errB;bitsB=errB;bitsQ=errB;
rng(cfg.randomSeed+2);
for i=1:numel(eb)
 gamma=10^(eb(i)/10);theoryB=qfunc_simple(sqrt(2*gamma));theory16=(4/log2(16))*(1-1/sqrt(16))*qfunc_simple(sqrt(3*log2(16)/(16-1)*gamma));
 [simB(i),errB(i),bitsB(i)]=simulate_bpsk(gamma,cfg);
 [simQ(i),errQ(i),bitsQ(i)]=simulate_qpsk(gamma,cfg);
 specs=[cfg.codingRate;2*cfg.codingRate;4*cfg.codingRate];
 bws=cfg.trunkRateTarget_Mbps*(1+cfg.rolloff)./specs;
 theory=[theoryB;theoryB;theory16];sim=[simB(i);simQ(i);NaN];errs=[errB(i);errQ(i);NaN];nbits=[bitsB(i);bitsQ(i);0];
 for m=1:3,allRows(end+1,:)={mods{m},eb(i),theory(m),sim(m),errs(m),nbits(m),specs(m),bws(m)};end %#ok<AGROW>
end
R=cell2table(allRows,'VariableNames',{'Modulation','EbN0_dB','TheoreticalBER','SimulatedBER', ...
 'ErrorCount','BitsSimulated','SpectralEfficiency_bits_per_s_Hz','BandwidthFor9p24Mbps_MHz'});
writetable(R,fullfile(resDir,'Modulation_Comparison.csv'));
f=figure('Visible','off','Color','w');hold on;
theoryB=qfunc_simple(sqrt(2*10.^(eb/10)));theory16=(4/log2(16))*(1-1/sqrt(16))*qfunc_simple(sqrt(3*log2(16)/(16-1)*10.^(eb/10)));
semilogy(eb,theoryB,'k--','LineWidth',1.8);semilogy(eb,theory16,'Color',[.65 .2 .7],'LineStyle','--','LineWidth',1.8);
semilogy(eb(simB>0),simB(simB>0),'o-','Color',[0 .42 .72],'LineWidth',1.4);
semilogy(eb(simQ>0),simQ(simQ>0),'s-','Color',[.85 .2 .1],'LineWidth',1.4);
zeroB=find(errB==0);zeroQ=find(errQ==0);
xlabel('E_b/N_0 (dB)');ylabel('BER');title('BPSK and QPSK AWGN Monte Carlo, with 16-QAM theory');
legend('BPSK theory','16-QAM theory (approx.)','BPSK Monte Carlo','QPSK Monte Carlo','Location','southwest');grid on;
if ~isempty(zeroB),text(eb(1),cfg.berPlotAnnotationY,sprintf('Zero observed errors: BPSK at %s dB; QPSK at %s dB',mat2str(eb(zeroB)'),mat2str(eb(zeroQ)')),'Color','k');end
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_27_Modulation_Comparison_BER.png'));close(f);
% Hamming(7,4) systematic code with hard-decision nearest-codeword decoding.
G=[1 0 0 0 1 1 0;0 1 0 0 1 0 1;0 0 1 0 0 1 1;0 0 0 1 1 1 1];msgs=dec2bin(0:15,4)-'0';code=mod(msgs*G,2);
hammingSim=zeros(numel(eb),1);hammingErr=zeros(numel(eb),1);hammingTheory=zeros(numel(eb),1);repTheory=zeros(numel(eb),1);
for i=1:numel(eb)
 gamma=10^(eb(i)/10);[hammingSim(i),hammingErr(i)]=simulate_hamming(gamma,cfg,code);
 p=qfunc_simple(sqrt(2*(4/7)*gamma));hammingTheory(i)=hamming_exact_ber(p,code);
 pr=qfunc_simple(sqrt(2*gamma/cfg.repetitionFactor));repTheory(i)=3*pr^2*(1-pr)+pr^3;
end
uncodedTheory=qfunc_simple(sqrt(2*10.^(eb/10)));
gammaUncoded=interp_at_log_ber(eb,uncodedTheory,cfg.codingGainTargetBER);
gammaHamming=interp_at_log_ber(eb,hammingTheory,cfg.codingGainTargetBER);
gainDb=gammaUncoded-gammaHamming;cross=find(hammingTheory<uncodedTheory,1);
if isempty(cross),crossEb=NaN;else,crossEb=eb(cross);end
CG=table(eb,uncodedTheory,hammingSim,hammingErr,hammingTheory,repTheory, ...
 repmat(gainDb,numel(eb),1),repmat(crossEb,numel(eb),1), ...
 'VariableNames',{'EbN0_dB','UncodedBPSK_TheoryBER','Hamming74_SimulatedBER', ...
 'Hamming74_ErrorCount','Hamming74_TheoryBER','Repetition3_FixedEnergyBER', ...
 'HammingCodingGainAt1eMinus5_dB','FirstEbN0BelowUncoded_dB'});
writetable(CG,fullfile(resDir,'Coding_Gain.csv'));
f=figure('Visible','off','Color','w');semilogy(eb,uncodedTheory,'k--','LineWidth',1.8);hold on;
semilogy(eb,hammingTheory,'Color',[0 .42 .72],'LineWidth',2);
semilogy(eb(hammingSim>0),hammingSim(hammingSim>0),'o','Color',[.85 .2 .1]);
semilogy(eb,repTheory,'Color',[.1 .6 .25],'LineStyle',':','LineWidth',1.8);
xlabel('E_b/N_0 per information bit (dB)');ylabel('BER');
title(sprintf('Hamming (7,4): theoretical gain %.2f dB at 10^{-5}',gainDb));
legend('Uncoded BPSK theory','Hamming (7,4) hard-decision theory','Hamming Monte Carlo','Repetition-3 fixed-energy theory','Location','southwest');grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_28_Coding_Gain.png'));close(f);
% Shannon upper bound and practical QPSK operating point per link.
link=linkFull;actual=link.SNR_dB;demand=[cfg.trunkRateTarget_Mbps;cfg.siteRateTarget_Mbps(:);zeros(numel(link.Link)-4,1)];
shannon=cfg.recommendedBandwidth_Hz/1e6*log2(1+10.^(actual/10));practical=duplex.GrossCapacity_Mbps*(1-duplex.OverheadFraction)*ones(numel(link.Link),1);
SP=table(link.Link,demand,actual,shannon,practical, ...
 'VariableNames',{'Link','RequiredRate_Mbps','OperatingSNR_dB','ShannonCapacity_Mbps','PracticalModulationCapacity_Mbps'});
writetable(SP,fullfile(resDir,'Shannon_Operating_Points.csv'));
f=figure('Visible','off','Color','w');snrdb=0:35;cap=cfg.recommendedBandwidth_Hz/1e6*log2(1+10.^(snrdb/10));plot(snrdb,cap,'LineWidth',2);hold on;
colors=lines(4);reqRates=[cfg.trunkRateTarget_Mbps cfg.siteRateTarget_Mbps];
for k=1:4,yline(reqRates(k),'--',sprintf('%s demand %.1f Mbps',cfg.linkNames{k},reqRates(k)));plot(actual(k),shannon(k),'o','Color',colors(k,:),'MarkerFaceColor',colors(k,:));plot(actual(k),practical(k),'s','Color',colors(k,:),'MarkerFaceColor','w');end
xlabel('SNR (dB)');ylabel('Capacity/rate (Mbps)');title('Shannon limits and QPSK practical capacity at link SNRs');
legend('Shannon C=B log_2(1+SNR)','Operating Shannon point','Practical QPSK point','Location','northwest');grid on;
set(gca,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_29_Shannon_Operating_Points.png'));close(f);
R.Properties.Description='Monte Carlo BPSK/QPSK and theory, plus 16-QAM theory; zero-error points are listed in the CSV, not plotted at an artificial floor.';
end
function [ber,err,n]=simulate_bpsk(gamma,cfg)
err=0;n=0;while n<cfg.berComparisonMaxBits && err<cfg.berTargetErrors
 batch=min(cfg.berComparisonMinBits,cfg.berComparisonMaxBits-n);b=randi([0 1],batch,1);x=2*b-1;
 y=x+sqrt(1/(2*gamma))*randn(batch,1);err=err+sum((y>=0)~=logical(b));n=n+batch;
end
ber=err/n;
end
function [ber,err,n] = simulate_qpsk(gamma,cfg)
err=0;n=0;while n<cfg.berComparisonMaxBits && err<cfg.berTargetErrors
 batch=min(cfg.berComparisonMinBits,cfg.berComparisonMaxBits-n);bits=randi([0 1],2*batch,1);
 sigma=sqrt(1/(4*gamma));I=(2*bits(1:2:end)-1)/sqrt(2)+sigma*randn(batch,1);Q=(2*bits(2:2:end)-1)/sqrt(2)+sigma*randn(batch,1);
decI=I>=0;decQ=Q>=0;err=err+sum(decI~=logical(bits(1:2:end)))+sum(decQ~=logical(bits(2:2:end)));n=n+2*batch;
end
ber=err/n;
end
function [ber,err] = simulate_hamming(gamma,cfg,code)
nInfo=cfg.hammingInfoBits;blocks=ceil(nInfo/4);msg=randi([0 1],blocks,4);ix=1+msg*[8;4;2;1];cw=code(ix,:);
tx=1-2*cw;sigma=sqrt(1/(2*gamma));rx=sqrt(4/7)*tx+sigma*randn(size(tx));hard=rx<0;best=zeros(blocks,7);bestDist=inf(blocks,1);
for c=1:size(code,1),d=sum(xor(hard,logical(code(c,:))),2);mask=d<bestDist;best(mask,:)=repmat(code(c,:),sum(mask),1);bestDist(mask)=d(mask);end
decoded=best(:,1:4);
err=sum(sum(xor(decoded(1:ceil(nInfo/4),:),logical(msg(1:ceil(nInfo/4),:)))));
ber=err/nInfo;
end
function ber=hamming_exact_ber(p,code)
errProb=0;for mask=0:127
 bits=dec2bin(mask,7)-'0';w=sum(bits);rx=mod(bits+code(1,:),2);dist=sum(xor(logical(code),logical(rx)),2);[~,idx]=min(dist);
 nerr=sum(code(idx,1:4));errProb=errProb+nerr*p^w*(1-p)^(7-w)/4;
end
ber=errProb;
end
function x=interp_at_log_ber(eb,ber,target)
valid=ber>0;xx=log10(ber(valid));ee=eb(valid);[xx,ix]=sort(xx);ee=ee(ix);
if target<10^min(xx) || target>10^max(xx),x=NaN;else,x=interp1(xx,ee,log10(target));end
end
