#!/bin/bash
echo "early"
shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome . 1000000 /data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_early_origins.txt /data/aparna/Data/cpg_promoter/cpg_-u_promoter.bed 3cell_early_cpg_promoter_1mil_CORRECT.txt 
echo "late"
#shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome . 1000000 /data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_late_origins.txt /data/wearn/NT2_dripc/Peaks/NT2_DRIPc_merged_rep12_intersect_peaks.bed /data/aparna/Peak_Calling/GA_StochHMM/DRIP_DRIPc_peaks_clean/NT2_DRIP_intersect_peaks.bed 3cell_late_cpg_promoter_dripc_1mil.txt 3cell_late_cpg_promoter_drip_1mil.txt
#shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome . 30000 /data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_late_origins.txt /data/wearn/NT2_dripc/Peaks/NT2_DRIPc_merged_rep12_intersect_peaks.bed /data/aparna/Peak_Calling/GA_StochHMM/DRIP_DRIPc_peaks_clean/NT2_DRIP_intersect_peaks.bed 3cell_late_cpg_promoter_dripc_1mil.txt 3cell_late_cpg_promoter_drip_1mil.txt
shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome . 1000000 /data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_late_origins.txt /data/aparna/Data/cpg_promoter/cpg_-u_promoter.bed 3cell_early_cpg_promoter_1mil_CORRECT.txt 