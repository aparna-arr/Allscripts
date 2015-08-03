#!/bin/bash

# DRIP

regions=("picard_both." "picard_both_ext." "picard_genebody." "picard_intergenic." "picard_prom." "picard_promoter_ext." "picard_term." "picard_terminal_ext.")

for r in $regions
  do
    wc -l $r"bed"
  done
