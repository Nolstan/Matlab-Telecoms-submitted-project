function R = signal_linecoding(cfg, outDir)
%SIGNAL_LINECODING Compare NRZ-L and Manchester waveforms and spectra.
bits=[1 1 1 1 1 0 0 0]; s=100;
nrz=repelem(2*bits-1,s);
man=zeros(1,numel(bits)*s);
for k=1:numel(bits), a=(k-1)*s+1; h=s/2; if bits(k)==1, man(a:a+h-1)=1; man(a+h:a+s-1)=-1; else, man(a:a+h-1)=-1; man(a+h:a+s-1)=1; end, end
t1=(0:numel(nrz)-1)/s; t2=(0:numel(man)-1)/s;
f=figure('Visible','off','Color','w'); tiledlayout(3,1);
nexttile; stairs(0:7,bits,'LineWidth',2); ylim([-.2 1.2]); title('Input bits');
nexttile; plot(t1,nrz); ylim([-1.3 1.3]); title('NRZ-L');
nexttile; plot(t2,man); ylim([-1.3 1.3]); title('Manchester'); xlabel('Bit intervals');
saveas(f,fullfile(outDir,'Figure_08_Line_Coding.png')); close(f);
N=4096; a=abs(fft(nrz,N)).^2/(numel(nrz)*s); b=abs(fft(man,N)).^2/(numel(man)*s);
freq=(0:N/2-1)*s/N;
f=figure('Visible','off','Color','w'); plot(freq,10*log10(max(a(1:N/2),1e-12)),'LineWidth',1.8,'Color',[0.00 0.42 0.72]); hold on;
plot(freq,10*log10(max(b(1:N/2),1e-12)),'LineWidth',1.8,'Color',[0.85 0.20 0.10]);
xlabel('Frequency (cycles per bit interval)'); ylabel('Relative power (dB)'); title('Finite-sequence line-code spectra'); legend('NRZ-L','Manchester','Location','best'); grid on;
ax=gca; set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
saveas(f,fullfile(outDir,'Figure_09_Line_Coding_Spectrum.png')); close(f);
R.meanNRZ=mean(nrz); R.meanManchester=mean(man); R.bits=bits;
end
