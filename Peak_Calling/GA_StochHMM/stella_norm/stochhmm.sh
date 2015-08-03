#!/bin/bash

for f in norm_wig/*
do
  echo "wig2fa $f"
  perl -I /usr/local/bin/Perl /usr/local/bin/Perl/wig2fa.pl -i $f -o $f.customfa
done

for f in norm_wig/*.customfa
do
  echo "stochhmm $f"
  stochhmm -seq $f -model /data/aparna/scripts/GA/models/GA_StochHMM_DRIP_7state_model_25run50pop_FINAL.hmm -posterior -threshold 0.9 -gff $f.gff
done

