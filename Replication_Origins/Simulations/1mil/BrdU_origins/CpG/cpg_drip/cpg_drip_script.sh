echo "early"
shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome . 1000000 /data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_early_origins.txt /data/aparna/Data/cpg_drip/cpg_-u_drip.bed 1mil_cpg_-u_drip_early_3cell.txt
echo "late"
shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome . 1000000 /data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_late_origins.txt /data/aparna/Data/cpg_drip/cpg_-u_drip.bed 1mil_cpg_-u_drip_late_3cell.txt

