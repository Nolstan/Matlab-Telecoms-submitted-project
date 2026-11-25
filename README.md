# Rural Telecommunications MATLAB Project

## Purpose

This undergraduate project models a hypothetical rural wireless network. Site A connects to site B, which serves the health centre (C), secondary school (D), and information centre (E). It compares a four-link tree, a four-link star, and a seven-link tree with three direct backup paths. No sites, equipment, or links have been deployed or field measured.

## Run

Open this folder in MATLAB and run `main`. The script locates its own project folder, runs the 25 analysis modules, regenerates `figures/` and canonical outputs in `results/`, saves `Rural_Telecommunications_Results.mat`, and writes `execution_log.txt`. Run only the un-suffixed result files as current; `_REFERENCE` files are preserved historical outputs.

## Model and assumptions

The selected illustrative radio point is 900 MHz, 10 MHz channel bandwidth, 27 dBm transmit power, 23 dBi antennas, QPSK, rate-0.75 coding, and TDD. The receiver noise figure is calculated from a Friis cascade (5.182 dB for the configured stages); feeder loss is represented once in each end's power budget and once as the passive receive stage in the noise cascade. The four tree-link payload demands are 7 Mbps on A-B and 3/2/2 Mbps on B-C/B-D/B-E. Backup links carry no extra allocated demand.

All positions, distances, radio settings, antenna properties, feeder constants, traffic, obstacle heights, propagation coefficients, equipment prices, and availability models are assumptions in `config.m`. The assumed 49.51 dBm EIRP requires a separate spectrum and regulatory review before any real use. The Rayleigh availability estimate is statistical, and route redundancy assumes independent path outages; common site power, structure, weather, interference, and other shared failures are excluded.

## Current validation result

The latest full MATLAB run completes all 25 modules. The requirements table reports 9 PASS and 1 FAIL. The remaining failure is first-Fresnel clearance: the current assumed heights and obstacles do not provide 60% clearance on the modeled paths, including the direct backups. `Fresnel_Clearance_Results.csv` reports earth bulge and the extra midpoint height each path needs under this simplified geometry. Treat the selected design as provisional until a terrain survey supports adjusted heights or routes.

The modeled minimum site availability for the selected backup topology is 0.999094, above its 0.999 target. The weakest residual single-link fade margin across all seven paths is 27.12 dB. The allocated net TDM payload capacities are 10.16 Mbps for A-B and 5.08/2.54/2.54 Mbps for B-C/B-D/B-E. The assumed equipment total is $22,160 against the configured $25,000 cap.

## Project files

- `config.m` — central assumptions and requirement targets.
- `main.m` — complete run and saved results.
- `scripts/` — MATLAB analysis modules.
- `figures/` — regenerated figures.
- `results/` — CSV, MAT, log, audit, and validation outputs.
- `/tmp/Rural_Telecommunications_Report.docx` — validated refreshed report artifact with 13 tables and 14 embedded figures. The approval review rejected replacing the DOCX inside `report/` during this run.
- `report/Figure_Placement_Guide.md` and `report/Student_Viva_Guide.md` — report and viva references.

The report and code are conceptual academic work. Validate terrain, equipment specifications, spectrum authorization, interference, weather, and installation costs before treating the design as deployable.
