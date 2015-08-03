#!/bin/bash

echo GA_dripc_early
cd GA_dripc_early
./run.pl early /data/wearn/NT2_dripc/Peaks/NT2_dripc_merged.bed 1mil_simulation_GA_StochHMM_peaks_Merged_DRIPc_early.txt
cd ..

echo GA_dripc_late
cd GA_dripc_late
./run.pl late /data/wearn/NT2_dripc/Peaks/NT2_dripc_merged.bed 1mil_simulation_GA_StochHMM_peaks_Merged_DRIPc_late.txt
cd ..

echo GA_dripc_plus_early
cd GA_dripc_plus_early
./run.pl early /data/wearn/NT2_dripc/Peaks/NT2_dripc_plus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_plus_early.txt
cd ..

echo GA_dripc_minus_early
cd GA_dripc_minus_early
./run.pl early /data/wearn/NT2_dripc/Peaks/NT2_dripc_minus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_minus_early.txt
cd ..

echo GA_dripc_plus_late
cd GA_dripc_plus_late
./run.pl late /data/wearn/NT2_dripc/Peaks/NT2_dripc_plus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_plus_late.txt
cd ..

echo GA_dripc_minus_late
cd GA_dripc_minus_late
./run.pl late /data/wearn/NT2_dripc/Peaks/NT2_dripc_minus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_minus_late.txt
cd ..

echo GA_drip_early
cd GA_drip_early
./run.pl early /data/aparna/GA/final_peak_calls/peaks/DRIP_stringent_intersect_shifted_clean.bed 1mil_simulation_GA_StochHMM_peaks_DRIP_early.txt
cd ..

echo GA_drip_late
cd GA_drip_late
./run.pl late /data/aparna/GA/final_peak_calls/peaks/DRIP_stringent_intersect_shifted_clean.bed 1mil_simulation_GA_StochHMM_peaks_DRIP_late.txt
cd ..
