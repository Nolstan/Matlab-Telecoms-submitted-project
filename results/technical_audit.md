# Technical audit and validation — Rural Telecommunications MATLAB project

Audit date: 2026-11-24

## Scope

Reviewed the configuration, main driver, all MATLAB module entry points, generated result tables and execution log, report text, and figure outputs. The pre-change archive is `/tmp/Rural_Telecommunications_Project_prechange_2026-11-24.tar.gz`.

## Findings corrected

1. The report and legacy code described a 5.8 GHz/four-link baseline while the extended model selected a different radio point. The report and canonical extended calculations now use the selected 900 MHz, 10 MHz, 27 dBm, 23 dBi assumptions; legacy assignment outputs remain identified as legacy.
2. The three direct backup paths were missing from several extended per-link modules. Seven paths now share one edge list and coordinate-derived distances.
3. Extended link budgets used a fixed 5 dB noise figure while the cascade produced another value. The link budget now uses the Friis cascade (5.182 dB). Transmit and receive feeder losses each appear once in received power; the receive feeder is also represented once as the first passive receiver stage.
4. Topology and availability now use calculated link outputs and explicit route combinations. Backup path independence is an idealization that excludes common power, site, tower, weather, interference, and maintenance failures.
5. TDM requirements now compare each service and trunk demand with allocated net TDM payload capacity, not the radio ceiling.
6. Candidate scoring now applies throughput, residual margin, and availability as hard feasibility constraints. QPSK is the highest-scoring feasible modulation choice under the configured weights.
7. Fresnel checks now include effective-earth curvature, report every modeled path, and calculate the extra midpoint height required under the simplified geometry.

## Latest full validation

The latest MATLAB run completed all 25 modules. Requirements: 9 PASS, 1 FAIL. The failure is 60% first-Fresnel clearance: all seven modeled paths miss the target under current assumed heights and 8 m obstacles. The largest shortfall is 11.249 m on A-D. A terrain survey and revised heights or routes are needed before the network can be considered geometrically viable.

Other model outputs: minimum selected-topology site availability 0.999094 against 0.999; weakest residual fade margin 27.122 dB; net TDM payload 10.160 Mbps on A-B and 5.080/2.540/2.540 Mbps on B-C/B-D/B-E; assumed equipment total $22,160 against a $25,000 cap. Resulting EIRP is 49.51 dBm and needs regulatory review.

## Report status

The updated report artifact is `/tmp/Rural_Telecommunications_Report.docx`. It contains 13 tables and 14 embedded figures, has valid ZIP/XML structure, and all image relationships resolve. Automatic file approval rejected the final write to `report/Rural_Telecommunications_Report.docx`; use the validated temporary artifact to replace the project copy.
