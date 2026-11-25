function cfg = config()
%CONFIG Central hypothetical design parameters for the rural wireless network.
% All values are illustrative engineering assumptions, not field measurements.
cfg.projectName = 'Rural Wireless Telecommunications Network';
cfg.siteNames = {'Central Distribution Station','Intermediate Distribution Node', ...
    'Rural Health Centre','Community Secondary School','Community Information Centre'};
cfg.linkNames = {'A-B: Central to Intermediate','B-C: Intermediate to Health Centre', ...
    'B-D: Intermediate to Secondary School','B-E: Intermediate to Information Centre'};
cfg.distance_km = [8 4 5 6];
cfg.frequency_Hz = 5.8e9;
cfg.alternativeFrequency_Hz = 2.4e9;
cfg.bandwidth_Hz = 20e6;
cfg.txPower_dBm = 23;
cfg.txGain_dBi = [23 18 18 18];
cfg.rxGain_dBi = [18 18 18 18];
% Recommended extended design, separate from the legacy baseline above.
cfg.recommendedFrequency_Hz = 900e6; % illustrative UHF option selected by the weighted frequency comparison.
cfg.recommendedBandwidth_Hz = 10e6; % illustrative channel width that preserves trunk capacity with TDD overhead.
cfg.recommendedTxPower_dBm = 27; % assumed radio setting for the extended design; licensed links may require authorization.
cfg.recommendedTxGain_dBi = repmat(23,1,7); % assumed dish gain at each link transmitter.
cfg.recommendedRxGain_dBi = repmat(23,1,7); % assumed dish gain at each link receiver.
cfg.otherLoss_dB = 2;
cfg.noiseFigure_dB = 5;
cfg.receiverSensitivity_dBm = -75;
cfg.targetSNR_dB = 15;
cfg.requiredFadeMargin_dB = 5; % illustrative reserve above the receive threshold
cfg.noiseTemperature_K = 290;
% Node order: A (central), B (intermediate), C (health), D (school), E (information).
cfg.antennaHeight_m = [20 18 15 15 15];
cfg.obstacleHeight_m = [8 8 8 8];
% Downstream site demands in order C, D, E; the A-B trunk carries their sum.
cfg.trafficMbps = [3 2 2];
cfg.tdmGuardBits_perSlot = 0;
cfg.processingDelay_ms = 2;
cfg.queueingDelay_ms = 3;
cfg.berBits = 2e5;
cfg.berEbN0dB = 0:2:14;
cfg.repetitionFactor = 3;
cfg.powerSweep_dBm = 15:2:31;
cfg.symbolProbabilities = [0.4 0.3 0.2 0.1];
cfg.symbolNames = {'A','B','C','D'};
cfg.sourceSymbolRate_Hz = 1000;
cfg.tdmSlotPayload_bits = 1000;
cfg.tdmFrameOverhead_bits = 80;
cfg.tdmFrameRate_Hz = 3000;
cfg.feederLength_m = 30;
cfg.feederAlpha_dB_per_100m = 3.5;
cfg.feederZ0_ohm = 50;
cfg.feederLoad_ohm = 60 + 1i*10;
feederGamma=(cfg.feederLoad_ohm-cfg.feederZ0_ohm)/(cfg.feederLoad_ohm+cfg.feederZ0_ohm);
cfg.feederLoss_dB=cfg.feederAlpha_dB_per_100m*cfg.feederLength_m/100 ...
    -10*log10(1-abs(feederGamma)^2);
cfg.diversityBranches = 2;
cfg.diversityBranchOutageProbability = 0.1;
cfg.randomSeed = 23;

% Assignment A: measurable requirements; these are illustrative design targets.
cfg.siteRateTarget_Mbps = [3 2 2]; % C, D and E downstream payload targets.
cfg.trunkRateTarget_Mbps = sum(cfg.siteRateTarget_Mbps);
cfg.delayTarget_ms = 50; % maximum modeled end-to-end packet delay.
cfg.availabilityTarget = 0.999; % per-link target (fraction).
cfg.topologyAssumedLinkAvailability = 0.999; % independent availability per assumed radio link.
cfg.berTarget = 1e-6; % uncoded service BER target.
cfg.budgetCap_USD = 25000; % illustrative equipment budget.
cfg.serviceTypes = {'Telemedicine video, voice, records'; ...
    'E-learning, voice';'Web/data, voice'};

% Assignment B: assumed planar site coordinates in km, chosen to reproduce
% the four existing tree distances exactly (A=(0,0), B=(8,0)).
cfg.siteCoordinates_km = [0 0; 8 0; 8 4; 11 4; 8 6];
cfg.siteShortNames = {'A','B','C','D','E'};
cfg.linkTxAntenna = repmat({'Parabolic dish'},4,1); % assumed aligned dishes for the reliable point-to-point design.
cfg.linkRxAntenna = repmat({'Parabolic dish'},4,1); % assumed aligned dishes for the reliable point-to-point design.
cfg.topologyBackupPairs = [1 3;1 4;1 5]; % A-to-C/D/E direct alternatives.
cfg.extendedLinkPairs = [[1 2;2 3;2 4;2 5];cfg.topologyBackupPairs];
cfg.extendedLinkNames = {'A-B';'B-C';'B-D';'B-E';'A-C (direct)';'A-D (direct)';'A-E (direct)'};
cfg.extendedLinkDistance_km = sqrt(sum((cfg.siteCoordinates_km(cfg.extendedLinkPairs(:,1),:) - ...
    cfg.siteCoordinates_km(cfg.extendedLinkPairs(:,2),:)).^2,2));
cfg.linkTxAntenna = repmat({'Parabolic dish'},7,1);
cfg.linkRxAntenna = repmat({'Parabolic dish'},7,1);
cfg.radioCost_USD = 600; % per assumed radio unit.
cfg.dishCost_USD = 250; % per assumed dish.
cfg.panelCost_USD = 150; % per assumed panel.
cfg.yagiCost_USD = 80; % per assumed Yagi.
cfg.feederCost_USD_per_m = 2; % assumed installed cable cost, USD/m.
cfg.connectorCost_USD = 15; % per assumed connector.
cfg.mastCost_USD = 500; % per assumed site mast.
cfg.powerBackupCost_USD = 1200; % per assumed site DC/backup set.
cfg.lightningProtectionCost_USD = 100; % per assumed site protection kit.
cfg.feederLengths_m = repmat(30,7,1); % one assumed feeder run at each endpoint for every modeled path.
cfg.feederLengthSweep_m = 0:10:100; % illustrative B-E feeder sensitivity sweep.

% Assignment C/F: radio and duplex assumptions for added analyses.
cfg.rolloff = 0.25; % raised-cosine excess bandwidth fraction (assumed).
cfg.modulationName = 'QPSK';
cfg.modulationBitsPerSymbol = 2;
cfg.codingRate = 0.75; % illustrative FEC rate.
cfg.tddDownlinkFraction = 0.70; % based on assumed downstream-heavy services.
cfg.tddFrameDuration_ms = 1; % illustrative TDD frame duration.
cfg.tddSwitchingTime_us = 100; % illustrative RF turnaround time per frame.
cfg.fddDownlinkFraction = 0.70; % illustrative FDD channel split.
cfg.voiceRate_kbps = 64; % assumed voice payload rate per call.
cfg.telemedicineRate_Mbps = 4; % assumed compressed video payload rate.
cfg.elearningRate_Mbps = 2; % assumed e-learning stream payload rate.
cfg.webRate_Mbps = 1; % assumed concurrent web/data payload rate.
cfg.telemetryRate_kbps = 64; % assumed telemetry/records payload rate.
cfg.analogueExampleFrequency_Hz = 3e3; % illustrative voice-band source tone.

% Assignment D: candidate antenna parameters are illustrative, not datasheet data.
cfg.antennaNames = {'Parabolic dish','Directional panel','Yagi antenna'};
cfg.antennaGain_dBi = [23 18 15];
cfg.antennaCost_USD = [cfg.dishCost_USD cfg.panelCost_USD cfg.yagiCost_USD]; % assumed unit cost for each candidate antenna.
cfg.antennaHpbwE_deg = [8 18 25];
cfg.antennaHpbwH_deg = [8 35 40];
cfg.antennaEfficiency = [0.31 0.96 0.77];
cfg.antennaFrontBack_dB = [35 25 20];
cfg.antennaBandwidth_MHz = [600 500 300];
cfg.antennaPolarization = {'Linear dual-polarized','Linear dual-polarized','Linear'};
cfg.antennaMountHeight_m = [20 18 15];
cfg.antennaPatternFloor_dB = -35;

% Assignment E: illustrative coaxial primary constants at cfg.frequency_Hz.
cfg.coaxResistance_ohm_per_m = 0.40; % series R at carrier, skin-effect adjusted.
cfg.coaxInductance_H_per_m = 250e-9;
cfg.coaxConductance_S_per_m = 1e-6;
cfg.coaxCapacitance_F_per_m = 100e-12;
cfg.coaxReferenceFrequency_Hz = cfg.frequency_Hz;
cfg.coaxVelocityFactor_assumed = 0.67;

% Assignment F/H: long-sequence PSD and Monte Carlo bounds (assumed settings).
cfg.lineCodeBits = 10000;
cfg.lineCodeOversampling = 8;
cfg.psdWindowSamples = 1024;
cfg.psdOverlapFraction = 0.5;
cfg.berComparisonEbN0_dB = 0:2:14;
cfg.berComparisonMinBits = 100000;
cfg.berComparisonMaxBits = 1000000;
cfg.berTargetErrors = 100;
cfg.hammingInfoBits = 200000;
cfg.codingGainTargetBER = 1e-5; % illustrative BER point used for coding-gain comparison.
cfg.berComparisonMaxBits = 5000000; % runtime cap; zero-error points are reported as censored observations.
cfg.berPlotAnnotationY = 1e-7; % annotation position for zero-error Monte Carlo points.

% Assignment B: switching model assumptions.
cfg.circuitReservedRate_Mbps = 10;
cfg.circuitSetupProcessing_ms = 2;
cfg.circuitCount = 8;
cfg.offeredCircuitLoad_Erlang = 0.6;
cfg.switchingUtilization = 0.10:0.05:0.95;
cfg.switchingMessageBytes = [1000 5e6];
cfg.queueServiceRate_Mbps = 20;
cfg.queueProcessing_ms_per_hop = 2;

% Assignment H/J: receiver cascade and propagation assumptions.
cfg.rxStageNames = {'Feeder','Preselector','LNA','Post-LNA filter','Mixer','IF amplifier'};
cfg.rxStageGain_dB = [-1.122 -2.5 20 -1 0 20];
cfg.rxStageNoiseFigure_dB = [1.122 2.5 2 1 7 4];
cfg.rainRate_mm_per_h = 30; % illustrative rain rate, not a local climate statistic.
cfg.rainK_assumed = 0.00002; % illustrative 900 MHz coefficient; not a certified ITU-R P.838 lookup.
cfg.rainAlpha_assumed = 1.0; % illustrative specific attenuation exponent at the selected band.
cfg.rainPathReductionCoeff = 0.045; % illustrative path-reduction model coefficient.
cfg.effectiveEarthRadiusFactor = 4/3; % assumed standard-refraction comparison case.
cfg.kFactorRange_assumed = [0.7 2.0]; % illustrative refractivity sensitivity range.
cfg.gasAttenuation_dB_per_km_assumed = 0.01; % illustrative dry-air loss, dB/km.
cfg.obstacleSweep_m = 0:1:25; % illustrative obstacle-height sweep.
cfg.mobileSpeed_kmh = 100; % comparison case; proposed sites are fixed.
cfg.diversityOutageTarget = 0.01;
cfg.diversityBranchCounts = [1 2 3];
cfg.availabilityFloor = 1e-12;

% Assignment I: fixed-rate TDM service assumptions.
cfg.tdmSlotCount = 3;
cfg.tdmFrameOverheadBits_perLink = 80;
cfg.voiceChannelRate_kbps = 64;
cfg.e1LikeRate_Mbps = 2;
cfg.videoStreamRate_Mbps = 4;
cfg.linkLoadWarningFraction = 0.80;
cfg.requirementsCheckPacketUtilization = 0.50; % illustrative operating load for the small-message delay target check.

% Assignment K: candidate design values and weighted-score assumptions.
cfg.frequencyCandidates_Hz = [900e6 2.4e9 5.8e9];
cfg.powerCandidates_dBm = [17 23 27];
cfg.modulationCandidates = {'BPSK','QPSK','16-QAM'};
cfg.modulationRequiredSNR_dB = [10 13 19]; % illustrative thresholds.
cfg.designWeights = [0.10 0.15 0.45 0.05 0.10 0.15]; % rate, margin, availability compliance, coverage, complexity, cost; reliability prioritized to meet target.
cfg.weightSensitivityCostMultiplier = 2;
cfg.complexityScores = [1 2 3]; % relative engineering complexity, assumed scale 1..5.
cfg.frequencyComplexity = [1.5 1.5 2.5]; % relative 900 MHz, 2.4 GHz, 5.8 GHz deployment complexity.
cfg.antennaComplexity = [3 2 2]; % assumed alignment/installation scores.
cfg.topologyComplexity = [1 2 4]; % assumed tree/star/redundant-link complexity.
cfg.modulationComplexity = [1 2 3]; % assumed receiver complexity scores.
cfg.powerCostMultiplier = [0.9 1 1.15]; % assumed radio cost scaling by candidate power tier.

% Assignment L: equipment quantity assumptions for the redundant recommendation.
cfg.siteCount = 5;
cfg.connectorCountPerLink = 4; % assumed connectors per point-to-point link.
cfg.radioUnitsPerLink = 2; % assumed point-to-point radio endpoints per link.
cfg.feederRunsPerLink = 2; % assumed one feeder run at each link endpoint.
cfg.redundantTopologyLinkCount = 4 + size(cfg.topologyBackupPairs,1); % four tree links plus configured backups.
cfg.redundantTopologyAntennaCounts = [14 0 0]; % two assumed dish antennas per point-to-point link in the seven-link design.
cfg.powerSystemPerSite = 1;
cfg.lightningKitPerSite = 1;
cfg.mastPerSite = 1;
end
