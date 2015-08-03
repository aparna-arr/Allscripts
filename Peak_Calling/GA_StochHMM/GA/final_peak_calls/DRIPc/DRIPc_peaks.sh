#!/bin/bash

for f in *.customfa
do
stochhmm -model DRIPc_Final_StochHMM_25runs50pop_GA_fromDRIP_plusbothtrained.hmm -seq $f -posterior -threshold 0.9 -gff > $f.peaks
done
