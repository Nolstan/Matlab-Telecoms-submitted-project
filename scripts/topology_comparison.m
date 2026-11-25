function R = topology_comparison(cfg,feeder,linkFull,resDir,figDir)
%TOPOLOGY_COMPARISON Compare tree, star, and tree with direct backup paths.
% Redundant route availability assumes independent path outages and excludes common causes.
base=[1 2;2 3;2 4;2 5];star=[1 2;1 3;1 4;1 5];
candidates={base,star,cfg.extendedLinkPairs};names={'Tree','Star','Tree with direct backup links'};
res=linkFull;linkA=exp(-10.^(-res.ResidualFadeMargin_dB/10));
linkMap=zeros(size(cfg.extendedLinkPairs,1));for q=1:size(cfg.extendedLinkPairs,1),linkMap(cfg.extendedLinkPairs(q,1),cfg.extendedLinkPairs(q,2))=q;end
rows={};linkRows={};summary={};
for t=1:numel(candidates)
 e=candidates{t};nlinks=size(e,1);siteA=ones(5,1);hops=zeros(5,1);paths=cell(5,1);spf=cell(5,1);
 for q=1:nlinks
  ix=find(all(cfg.extendedLinkPairs==e(q,:),2),1);
  if isempty(ix),error('No seven-path budget for edge %d-%d.',e(q,1),e(q,2));end
  perCost=cfg.radioUnitsPerLink*cfg.radioCost_USD+2*cfg.dishCost_USD+ ...
    cfg.feederRunsPerLink*cfg.feederLength_m*cfg.feederCost_USD_per_m+cfg.connectorCountPerLink*cfg.connectorCost_USD;
  linkRows(end+1,:)={names{t},res.Link{ix},cfg.siteShortNames{e(q,1)},cfg.siteShortNames{e(q,2)}, ...
    res.Distance_km(ix),res.FSPL_dB(ix),res.ReceivedPower_dBm(ix),res.ResidualFadeMargin_dB(ix), ...
    res.ResidualFadeMargin_dB(ix)>=0,linkA(ix),t==3&&q>4,perCost}; %#ok<AGROW>
 end
 ab=linkA(find(all(cfg.extendedLinkPairs==[1 2],2),1));
 for site=2:5
  if site==2
   siteA(site)=ab;hops(site)=1;paths{site}='A-B';spf{site}='A-B';continue
  end
  treeIx=find(all(cfg.extendedLinkPairs==[2 site],2),1);directIx=find(all(cfg.extendedLinkPairs==[1 site],2),1);
  if t==1
   siteA(site)=ab*linkA(treeIx);hops(site)=2;paths{site}=sprintf('A-B, B-%s',cfg.siteShortNames{site});spf{site}='A-B';
  elseif t==2
   siteA(site)=linkA(directIx);hops(site)=1;paths{site}=sprintf('A-%s',cfg.siteShortNames{site});spf{site}=paths{site};
  else
   treePath=ab*linkA(treeIx);directPath=linkA(directIx);siteA(site)=1-(1-treePath)*(1-directPath);
   hops(site)=1;paths{site}=sprintf('A-B-%s || A-%s',cfg.siteShortNames{site},cfg.siteShortNames{site});spf{site}='Independent-path assumption';
  end
 end
 infra=cfg.siteCount*(cfg.mastCost_USD+cfg.powerBackupCost_USD+cfg.lightningProtectionCost_USD);
 cost=nlinks*(cfg.radioUnitsPerLink*cfg.radioCost_USD+2*cfg.dishCost_USD+ ...
  cfg.feederRunsPerLink*cfg.feederLength_m*cfg.feederCost_USD_per_m+cfg.connectorCountPerLink*cfg.connectorCost_USD)+infra;
 for site=1:5
  if site==1,idx=[];d=0;pl=0;pr=0;m=Inf;pass=true;path='Local';
  else
   path=paths{site};
   if site==2,ix=find(all(cfg.extendedLinkPairs==[1 2],2),1);idx=ix;
   elseif t==1,idx=[find(all(cfg.extendedLinkPairs==[1 2],2),1),find(all(cfg.extendedLinkPairs==[2 site],2),1)];
   elseif t==2,idx=find(all(cfg.extendedLinkPairs==[1 site],2),1);
   else,idx=[find(all(cfg.extendedLinkPairs==[2 site],2),1),find(all(cfg.extendedLinkPairs==[1 site],2),1)];end
   d=max(res.Distance_km(idx));pl=max(res.FSPL_dB(idx));pr=min(res.ReceivedPower_dBm(idx));m=min(res.ResidualFadeMargin_dB(idx));pass=m>=0;
  end
  rows(end+1,:)={names{t},cfg.siteShortNames{site},nlinks,path,d,hops(site),pl,pr,m,pass,cost,siteA(site),spf{site}}; %#ok<AGROW>
 end
 summary(end+1,:)={names{t},nlinks,max(res.Distance_km(ismember(res.Link,linkNamesFor(cfg,e)))),max(hops), ...
  min(res.ResidualFadeMargin_dB(ismember(res.Link,linkNamesFor(cfg,e)))),cost,min(siteA(2:5))}; %#ok<AGROW>
end
R=cell2table(rows,'VariableNames',{'Topology','DestinationSite','NumberOfLinks','PathLinks','LongestPathLink_km', ...
 'HopCount','WorstPathLoss_dB','WorstReceivedPower_dBm','WorstPathMargin_dB','MeetsReceiveThreshold', ...
 'TotalEquipmentCost_USD','SiteAvailability','SinglePointFailure'});
writetable(R,fullfile(resDir,'Topology_Comparison.csv'));
L=cell2table(linkRows,'VariableNames',{'Topology','Link','TxSite','RxSite','Distance_km','FSPL_dB', ...
 'ReceivedPower_dBm','ResidualMargin_dB','MeetsThreshold','Availability','IsBackupLink','EquipmentCost_USD'});
writetable(L,fullfile(resDir,'Topology_Link_Metrics.csv'));
S=cell2table(summary,'VariableNames',{'Topology','NumberOfLinks','LongestLink_km','MaximumSiteHops', ...
 'MinimumLinkMargin_dB','EquipmentCost_USD','MinimumSiteAvailability'});writetable(S,fullfile(resDir,'Topology_Summary.csv'));
f=figure('Visible','off','Color','w');tiledlayout(1,2,'Padding','compact');
nexttile;bar(S.EquipmentCost_USD,'FaceColor',[0 .42 .72]);xticks(1:height(S));xticklabels(S.Topology);xtickangle(25);ylabel('Assumed equipment cost (USD)');title('Topology cost comparison');grid on;
nexttile;bar(S.MinimumSiteAvailability,'FaceColor',[.15 .6 .35]);hold on;yline(cfg.availabilityTarget,'r--','Target');xticks(1:height(S));xticklabels(S.Topology);xtickangle(25);ylabel('Minimum site availability');title('End-to-end availability model');ylim([0 1]);grid on;
ax=findall(f,'Type','axes');set(ax,'Color','w','XColor','k','YColor','k');saveas(f,fullfile(figDir,'Figure_19_Topology_Comparison.png'));close(f);
R.Properties.Description='Backup route availability assumes independent path outages and excludes common site, power, weather, interference, and infrastructure failures.';
end
function names=linkNamesFor(cfg,e)
idx=zeros(size(e,1),1);for j=1:size(e,1),idx(j)=find(all(cfg.extendedLinkPairs==e(j,:),2),1);end
names=cfg.extendedLinkNames(idx);
end
