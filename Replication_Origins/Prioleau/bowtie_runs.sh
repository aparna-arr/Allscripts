#!/bin/bash
echo "46"
bowtie2 -x /data/Bowtie2_Indexes/hg19/hg19.fa -U SRR830646_1.fastq -S 46.sam
echo "47"
bowtie2 -x /data/Bowtie2_Indexes/hg19/hg19.fa -U SRR830647_1.fastq -S 47.sam
echo "48"
bowtie2 -x /data/Bowtie2_Indexes/hg19/hg19.fa -U SRR830648_1.fastq -S 48.sam
echo "49"
bowtie2 -x /data/Bowtie2_Indexes/hg19/hg19.fa -U SRR830649_1.fastq -S 49.sam
echo "50"
bowtie2 -x /data/Bowtie2_Indexes/hg19/hg19.fa -U SRR830650_1.fastq -S 50.sam

