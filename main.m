function main()
%MAIN Execute all legacy and extended analyses from a clean MATLAB workspace.
clear; clc; close all;
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'scripts'));
figDir=fullfile(root,'figures'); resDir=fullfile(root,'results');
if ~exist(figDir,'dir'), mkdir(figDir); end
if ~exist(resDir,'dir'), mkdir(resDir); end
set(groot,'defaultFigureColor','w','defaultAxesColor','w','defaultAxesXColor','k', ...
 'defaultAxesYColor','k','defaultTextColor','k','defaultAxesFontSize',10, ...
 'defaultLegendColor','w','defaultLegendTextColor','k','defaultLegendEdgeColor','k');
logFile=fullfile(resDir,'execution_log.txt');fid=fopen(logFile,'w');
if fid<0,error('Cannot create execution log: %s',logFile);end;fclose(fid);
diary(logFile);diaryCleanup=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('Rural Telecommunications Project started: %s\n',datestr(now));
try
 cfg=config();
 fprintf('\n[1/25] Legacy network model\n');network=network_design(cfg,figDir);
 fprintf('[2/25] Legacy link budget\n');link=link_budget(cfg,resDir,figDir);
 fprintf('A-B FSPL %.2f dB, Pr %.2f dBm, SNR %.2f dB, residual fade margin %.2f dB; weakest residual margin %.2f dB\n', ...
  link.PathLoss_dB(1),link.ReceivedPower_dBm(1),link.SNR_dB(1),link.ResidualFadeMargin_dB(1),min(link.ResidualFadeMargin_dB));
 fprintf('[3/25] Legacy Fresnel analysis\n');fresnel=propagation_fresnel(cfg,resDir,figDir);
 fprintf('[4/25] Legacy antenna and feeder analysis\n');feederLegacy=antenna_feeder_analysis(cfg,figDir,resDir);
 fprintf('[5/25] Legacy line coding\n');linecoding=signal_linecoding(cfg,figDir);
 fprintf('[6/25] Legacy source coding\n');source=source_coding(cfg,resDir);
 fprintf('[7/25] Legacy modulation BER\n');ber=modulation_ber(cfg,resDir,figDir);
 fprintf('[8/25] Legacy channel coding\n');channel=channel_coding(cfg,resDir,figDir);
 fprintf('[9/25] Legacy multiplexing and capacity\n');capacity=capacity_multiplexing(cfg,resDir,figDir);
 fprintf('Legacy assignment TDM utilization %.1f%%\n',capacity.Utilization_percent);
 fprintf('[10/25] Legacy switching diversity\n');switchingLegacy=switching_diversity(cfg,resDir,figDir);
 fprintf('[11/25] Legacy final summary\n');summary=final_summary(cfg,link,capacity,resDir,figDir);

 fprintf('[12/25] Feeder primary-constant model at recommended carrier\n');feeder=feeder_primary_constants(cfg,resDir,figDir);
 fprintf('Coax Z0 %.2f ohm, attenuation %.2f dB/100 m\n',abs(feeder.Z0_ohm),feeder.Attenuation_dB_per_100m);
 fprintf('[13/25] Duplex and service classification\n');duplex=duplex_services(cfg,resDir,figDir);
 fprintf('[14/25] Extended seven-path link budget\n');linkFull=link_budget_full(cfg,feeder,resDir,figDir);
 fprintf('[15/25] Topology comparison from link budgets\n');topo=topology_comparison(cfg,feeder,linkFull,resDir,figDir);
 fprintf('[16/25] Circuit versus packet switching\n');switching=switching_comparison(cfg,resDir,figDir);
 fprintf('Switching recommendation: %s\n',switching.Properties.Description);
 fprintf('[17/25] Antenna parameter comparison\n');antenna=antenna_parameters(cfg,resDir,figDir);
 fprintf('[18/25] Line-code spectral comparison\n');linecodeExtended=linecoding_comparison(cfg,resDir,figDir);
 fprintf('[19/25] Receiver noise cascade\n');noise=noise_figure_cascade(cfg,linkFull,feeder,resDir,figDir);
 fprintf('[20/25] Link capacity and TDM sizing\n');capacityFull=link_capacity_check(cfg,duplex,resDir,figDir);
 fprintf('Maximum radio utilization %.1f%%\n',100*max(capacityFull.PerLinkUtilization));
 fprintf('[21/25] Modulation, coding and Shannon comparison\n');modulation=modulation_comparison(cfg,linkFull,duplex,resDir,figDir);
 fprintf('[22/25] Propagation effects and diversity\n');propagation=propagation_effects(cfg,fresnel,linkFull,resDir,figDir);
 fprintf('[23/25] Weighted design optimization\n');optimization=design_optimization(cfg,linkFull,topo,capacityFull,resDir,figDir);
 [~,winnerIx]=max(optimization.WeightedScore);fprintf('Weighted recommendation: %s — %s\n', ...
  optimization.ChoiceGroup{winnerIx},optimization.Option{winnerIx});
 fprintf('[24/25] Final design and equipment summary\n');design=final_design_summary(cfg,linkFull,feeder,capacityFull,propagation,resDir,figDir);
 fprintf('Redundant equipment estimate $%.0f against $%.0f cap\n',design.EquipmentCost_USD,cfg.budgetCap_USD);

 % Preserve the established transmitter-power sweep output and Figure_15.
 power=cfg.powerSweep_dBm;c=299792458;lambda=c/cfg.recommendedFrequency_Hz;
 fspl=20*log10(4*pi*(cfg.extendedLinkDistance_km(1)*1000)/lambda);
 rx=power+cfg.recommendedTxGain_dBi(1)+cfg.recommendedRxGain_dBi(1)-2*feeder.PerLink.TotalFeederLoss_dB(1)-cfg.otherLoss_dB-fspl;
 req=linkFull.RequiredRx_dBm(1)+cfg.requiredFadeMargin_dB;
 opt=table(power',rx',rx'-req,'VariableNames',{'TxPower_dBm','AB_ReceivedPower_dBm','AB_MarginToTarget_dB'});
 writetable(opt,fullfile(resDir,'Optimization_Results.csv'));
 f=figure('Visible','off','Color','w');yyaxis left;plot(power,rx,'o-','LineWidth',2,'Color',[0 .42 .72]);ylabel('Received power (dBm)');
 yyaxis right;plot(power,rx'-req,'s-','LineWidth',2,'Color',[.85 .2 .1]);ylabel('Margin to required receive level (dB)');
 xlabel('Transmit power (dBm)');title('A-B link sensitivity to transmitter power');grid on;
 ax=findall(f,'Type','axes');set(ax,'Color','w','XColor','k','YColor','k','FontSize',10,'LineWidth',1);
 saveas(f,fullfile(figDir,'Figure_15_Transmitter_Power_Analysis.png'));close(f);

 fprintf('[25/25] Requirements check (must run last)\n');
 requirements=requirements_check(cfg,linkFull,capacityFull,switching,propagation,modulation,topo,design,resDir);
 fprintf('Requirements: %d PASS, %d FAIL\n',sum(requirements.Pass),sum(~requirements.Pass));
 newCsv={'Topology_Comparison.csv','Topology_Link_Metrics.csv','Topology_Summary.csv','Duplex_Plan.csv', ...
  'Duplex_Method_Comparison.csv','Signal_Classification.csv','Switching_Comparison.csv', ...
  'Link_Budget_Full.csv','Antenna_Parameters.csv','Link_Antenna_Justification.csv', ...
  'Feeder_Primary_Constants.csv','Feeder_Per_Link.csv','LineCode_Comparison.csv', ...
  'Noise_Figure_Cascade.csv','Noise_Figure_Cascade_Stages.csv','Link_Capacity_Check.csv', ...
  'Modulation_Comparison.csv','Coding_Gain.csv','Shannon_Operating_Points.csv', ...
  'Propagation_Effects.csv','Link_Availability.csv','Diversity_Gain.csv', ...
  'Optimization_Decision_Matrix.csv','Optimization_Sensitivity.csv', ...
  'Final_Design_Summary.csv','Equipment_List.csv','Requirements_Table.csv'};
 newOutputs=struct();
 for k=1:numel(newCsv)
  file=fullfile(resDir,newCsv{k});if exist(file,'file')
   [~,key]=fileparts(newCsv{k});newOutputs.(matlab.lang.makeValidName(key))=readtable(file);
  end
 end
 save(fullfile(resDir,'Rural_Telecommunications_Results.mat'),'cfg','network','link','fresnel', ...
  'feederLegacy','linecoding','source','ber','channel','capacity','switchingLegacy','summary','opt', ...
  'feeder','topo','duplex','switching','linkFull','antenna','linecodeExtended','noise', ...
  'capacityFull','modulation','propagation','optimization','design','requirements','newOutputs');
 fprintf('\nCompleted all modules. Results: %s\n',resDir);
 fprintf('Selected-design weakest received power %.2f dBm; minimum residual fade margin %.2f dB; maximum radio utilization %.1f%%\n', ...
  min(linkFull.ReceivedPower_dBm),min(linkFull.ResidualFadeMargin_dB),100*max(capacityFull.PerLinkUtilization));
catch ME
 fprintf(2,'PROJECT FAILED: %s\n',ME.message);
 for k=1:numel(ME.stack),fprintf(2,'  in %s at line %d\n',ME.stack(k).name,ME.stack(k).line);end
 rethrow(ME);
end
diary off;
end
