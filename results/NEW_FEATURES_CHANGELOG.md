# Change log — technical correction and validation

## 2026-11-24

- Defined one seven-path edge list from the site coordinates: four tree links plus A-C, A-D, and A-E direct alternatives.
- Recomputed each distance, feeder loss, FSPL, receive power, EIRP, noise, SNR, fade margin, and propagation metric from the selected 900 MHz design assumptions.
- Replaced the fixed receiver NF in extended calculations with a 5.182 dB Friis cascade. The receive feeder is represented as one passive front-end stage; TX and RX feeder losses each appear once in received power.
- Kept traffic allocation on the four active tree links and checked each site and trunk target against allocated TDM payload capacity.
- Rebuilt topology path availability from link outputs. Independent backup paths are explicitly an idealized assumption; the intermediate site remains a single-link dependency.
- Added earth-curvature adjustment and per-path extra-height estimates to the 60% Fresnel check. The present assumed geometry fails this check; the report marks that limitation.
- Gated weighted candidate recommendations on throughput, nonnegative residual margin, and the 99.9% modeled availability target. QPSK is the highest-scoring feasible modulation option.
- Prepared the refreshed report artifact in `/tmp/Rural_Telecommunications_Report.docx` and updated the figure placement guide, viva guide, README, audit, and validation notes. The approval review rejected replacing the DOCX inside `report/`.

## Latest full MATLAB run

All 25 modules completed. Requirements: 9 PASS, 1 FAIL. The sole failure is 60% first-Fresnel clearance for all seven assumed paths. Minimum modeled site availability in the selected backup topology is 0.999094; equipment estimate is $22,160 of the assumed $25,000 cap. These are calculated values from illustrative inputs, not field measurements or verified regulatory/equipment data.
