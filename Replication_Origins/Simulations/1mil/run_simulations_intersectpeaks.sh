#!/bin/bash

echo GA_dripc_early
cd GA_dripc_early
./run.pl early /data/aparna/GA/final_peak_calls/peaks/clean/NT2_DRIPc_merged_rep12_intersect_peaks.bed 1mil_simulation_GA_StochHMM_peaks_Intersect_DRIPc_early.txt
cd ..

echo GA_dripc_late
cd GA_dripc_late
./run.pl late /data/aparna/GA/final_peak_calls/peaks/clean/NT2_DRIPc_merged_rep12_intersect_peaks.bed 1mil_simulation_GA_StochHMM_peaks_Intersect_DRIPc_late.txt
cd ..

echo GA_dripc_plus_early
cd GA_dripc_plus_early
./run.pl early /data/aparna/GA/final_peak_calls/peaks/clean/split_strands_intersect/NT2_DRIP_intersect_peaks_plus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_plus_Intersect_early.txt
cd ..

echo GA_dripc_minus_early
cd GA_dripc_minus_early
./run.pl early /data/aparna/GA/final_peak_calls/peaks/clean/split_strands_intersect/NT2_DRIP_intersect_peaks_minus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_minus_Intersect_early.txt
cd ..

echo GA_dripc_plus_late
cd GA_dripc_plus_late
./run.pl late /data/aparna/GA/final_peak_calls/peaks/clean/split_strands_intersect/NT2_DRIP_intersect_peaks_plus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_plus_Intersect_late.txt
cd ..

echo GA_dripc_minus_late
cd GA_dripc_minus_late
./run.pl late /data/aparna/GA/final_peak_calls/peaks/clean/split_strands_intersect/NT2_DRIP_intersect_peaks_minus.bed 1mil_simulation_GA_StochHMM_peaks_DRIPc_minus_Intersect_late.txt
cd ..


echo GA_drip_early
cd GA_drip_early
./run.pl early /data/aparna/GA/final_peak_calls/peaks/clean/NT2_DRIP_intersect_peaks.bed 1mil_simulation_GA_StochHMM_peaks_DRIP_Intersect_early.txt
cd ..

echo GA_drip_late
cd GA_drip_late
./run.pl late /data/aparna/GA/final_peak_calls/peaks/clean/NT2_DRIP_intersect_peaks.bed 1mil_simulation_GA_StochHMM_peaks_DRIP_Intersect_late.txt
cd ..
