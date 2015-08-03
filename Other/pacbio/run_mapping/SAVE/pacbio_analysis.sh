#!/bin/bash

GENOME_DIR="../pFC53"
RAW_FILES_DIR="../raw"
SCRIPTS_DIR="../scripts"

bismark_genome_preparation --bowtie2 --path_to_bowtie /usr/bin $GENOME_DIR
bowtie2-build barcode_ref.fa barcode_ref

for n in 1 2 3
do
  $SCRIPTS_DIR/pacbio_fasta_debarcoder.pl $RAW_FILES_DIR/m140312_211430_42145_c100628642550000001823107908061453_s1_p0.$n.ccs.fasta $n 
  bowtie2 --norc -f -N 1 -L 8 --no-head -i S,1,0.50 --gbar 1 barcode_ref $n\_left.fa | awk '{print $10 "\t" $3}' > temp1
  bowtie2 --nofw -f -N 1 -L 8 --no-head -i S,1,0.50 --gbar 1 barcode_ref $n\_right.fa | cut -f 3 > temp2
  paste temp1 temp2 > $n\_bc_mapped.txt
done

cat $RAW_FILES_DIR/m140312_211430_42145_c100628642550000001823107908061453_s1_p0.[123].ccs.fasta > allccsreads.fa

cat [123]_bc_mapped.txt > all_bc_mapped.txt

$SCRIPTS_DIR/match_barcode_stringent.pl all_bc_mapped.txt allccsreads.fa

for m in 1 2 3 4 5 6
do
#  bismark --bowtie2 --unmapped --ambiguous -f -o . $GENOME_DIR bc_$m.fa --score_min L,0,-0.4
# 0.4 has ~33% mapping efficiency
  bismark --bowtie2 --unmapped --ambiguous -f -o . $GENOME_DIR bc_$m.fa --rdg 1,1 --rfg 1,1 --score_min L,0,-0.8
# original parameters (relaxed) 
# bismark --bowtie2 --unmapped --ambiguous -f -o . $GENOME_DIR bc_$m.fa 
# default parameters, most stringent. Mapping efficientcy ~1.5%

done

mkdir samfiles_pacbio
mv bc_[123456].fa_bt2_bismark.sam samfiles_pacbio
