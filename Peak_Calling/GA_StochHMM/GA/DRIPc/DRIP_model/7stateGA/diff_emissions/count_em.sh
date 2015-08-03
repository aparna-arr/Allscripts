#!/bin/bash

#./higher_wig2fa.pl -i chr8.wig
#./lower_wig2fa.pl -i DRIPc_plus_all_chr8_smallregion.wig
for f in *.bed
do
  fastaFromBed -fi chr8.wig.customfa -bed $f -fo $f.fa
  ./HMM_Counter.pl -i $f.fa -r 3 -w N,L,O,M,H,S -o $f.count
  echo $f >> DRIPc_from_DRIP_model_diffem_7st.hmm
  cat $f.count >> DRIPc_from_DRIP_model_diffem_7st.hmm
  echo "\#" >> DRIPc_from_DRIP_model_diffem_7st.hmm 
done
