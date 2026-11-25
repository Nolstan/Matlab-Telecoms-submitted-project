function R = requirements_check(cfg,link,capacity,switching,propagation,modulation,topo,design,resDir)
%REQUIREMENTS_CHECK Compare configured targets with achieved module outputs.
% PASS/FAIL is evaluated from achieved values and each configured target.
req={};target={};unit={};verifier={};achieved={};pass=[];
for k=1:numel(cfg.siteRateTarget_Mbps)
 req{end+1,1}=sprintf('Site %s minimum payload rate',cfg.siteShortNames{k+2});
 target{end+1,1}=cfg.siteRateTarget_Mbps(k);unit{end+1,1}='Mbps';verifier{end+1,1}='link_capacity_check';
 siteCap=capacity.Table.NetTdmPayloadCapacity_Mbps(k+1);
achieved{end+1,1}=siteCap;pass(end+1,1)=siteCap>=cfg.siteRateTarget_Mbps(k); %#ok<AGROW>
end
req{end+1,1}='Trunk minimum payload rate';target{end+1,1}=cfg.trunkRateTarget_Mbps;unit{end+1,1}='Mbps';verifier{end+1,1}='link_capacity_check';
trunkCap=capacity.Table.NetTdmPayloadCapacity_Mbps(1);
achieved{end+1,1}=trunkCap;pass(end+1,1)=trunkCap>=cfg.trunkRateTarget_Mbps;

packet=switching(switching.MessageSize_bytes==min(switching.MessageSize_bytes) & ...
 abs(switching.PacketServerUtilization_fraction-cfg.requirementsCheckPacketUtilization)<1e-9,:);
if isempty(packet), [~,ix]=min(abs(switching.PacketServerUtilization_fraction-cfg.requirementsCheckPacketUtilization)); packet=switching(ix,:); end
delay=max(packet.PacketEndToEndDelay_ms);
req{end+1,1}='Small-message end-to-end packet delay';target{end+1,1}=cfg.delayTarget_ms;unit{end+1,1}='ms';verifier{end+1,1}='switching_comparison';
achieved{end+1,1}=delay;pass(end+1,1)=delay<=cfg.delayTarget_ms;

selected=topo(strcmp(topo.Topology,'Tree with direct backup links'),:);
siteAvail=min(selected.SiteAvailability(~strcmp(selected.DestinationSite,'A')));
req{end+1,1}='Minimum end-to-end site availability with selected backup topology';target{end+1,1}=cfg.availabilityTarget;unit{end+1,1}='fraction';verifier{end+1,1}='topology_comparison';
achieved{end+1,1}=siteAvail;pass(end+1,1)=siteAvail>=cfg.availabilityTarget;

fresnelMargin=min(propagation.MarginAfter60PercentFresnel_m);
req{end+1,1}='At least 60% first-Fresnel clearance on every modeled path';target{end+1,1}=0;unit{end+1,1}='m minimum margin';verifier{end+1,1}='propagation_fresnel';
achieved{end+1,1}=fresnelMargin;pass(end+1,1)=fresnelMargin>=0;

snr=min(link.SNR_dB);ber=qfunc_simple(sqrt(2*10^(snr/10)));
req{end+1,1}='Weakest-link uncoded BPSK BER';target{end+1,1}=cfg.berTarget;unit{end+1,1}='BER';verifier{end+1,1}='modulation_comparison (theory at weakest-link SNR)';
achieved{end+1,1}=ber;pass(end+1,1)=ber<=cfg.berTarget;

maxUtil=max(capacity.PerLinkUtilization);
req{end+1,1}='Maximum radio utilization';target{end+1,1}=1;unit{end+1,1}='fraction';verifier{end+1,1}='link_capacity_check';
achieved{end+1,1}=maxUtil;pass(end+1,1)=maxUtil<1;

budget=design.EquipmentCost_USD;
req{end+1,1}='Redundant design equipment cost';target{end+1,1}=cfg.budgetCap_USD;unit{end+1,1}='USD maximum';verifier{end+1,1}='final_design_summary';
achieved{end+1,1}=budget;pass(end+1,1)=budget<=cfg.budgetCap_USD;

pass=logical(pass(:));
R=table(req,target,unit,verifier,achieved,pass, ...
 'VariableNames',{'Requirement','Target','Unit','VerifiedBy','AchievedValue','Pass'});
status=repmat({'FAIL'},height(R),1);status(R.Pass)={'PASS'};R.Status=status;
writetable(R,fullfile(resDir,'Requirements_Table.csv'));
end
