#!/bin/bash

#these are all with adjusted emission values. For unadjusted emission single stochhmm runs, see other folders. 7 state is in aparna@zeus:/data/aparna/GA/GA_7state_seperate_regions

# 7 state stochhmm DRIPc DRIP model single run
#echo "7 state stochhmm DRIPc DRIP model single run"
#stochhmm -model /data/aparna/GA/DRIPc/DRIP_model/7stateGA/DRIP_NT2_7states.hmm -seq /data/aparna/GA/DRIPc/DRIPc_plus_all_chr8_smallregion.wig.customfa -posterior -threshold 0.9 -gff > /data/aparna/GA/DRIPc/DRIP_model/7stateGA/7state_DRIPc_DRIPmodel_stochhmm.gff

# 4 state stochhmm DRIPc DRIP model single run
#echo "4 state stochhmm DRIPc DRIP model single run"
#stochhmm -model /data/aparna/GA/DRIPc/DRIP_model/4stateGA/DRIP_NT2_-small-sharp_moreem.hmm -seq /data/aparna/GA/DRIPc/DRIPc_plus_all_chr8_smallregion.wig.customfa -posterior -threshold 0.9 -gff > /data/aparna/GA/DRIPc/DRIP_model/4stateGA/4state_DRIPc_DRIPmodel_stochhmm.gff

# 7 state GA FINAL DRIP run to get hmm
#echo "7 state GA FINAL DRIP run to get hmm"
#cd /data/aparna/GA/GA_7state_seperate_regions/
#/data/aparna/GA/GA_7state_seperate_regions/G_A_7states_random.pl /data/aparna/GA/chr8_smallregion.wig.customfa /data/aparna/GA/GA_7state_seperate_regions/DRIP_NT2_7states.hmm /data/aparna/GA/GA_7state_seperate_regions/25run50popfinal/ 25 50 0.9 8
#./G_A_7states_random.pl ../chr8_smallregion.wig.customfa DRIP_NT2_7states.hmm 25run50popfinal/ 25 50 0.9 8

# 7 state GA DRIPc DRIP model
echo "7 state GA DRIPc DRIP model"
#/data/aparna/GA/DRIPc/DRIP_model/7stateGA/G_A_7states_random.pl /data/aparna/GA/DRIPc/DRIPc_plus_all_chr8_smallregion.wig.customfa /data/aparna/GA/DRIPc/DRIP_model/7stateGA/DRIP_NT2_7states.hmm /data/aparna/GA/DRIPc/DRIP_model/7stateGA/out/ 25 16 0.9 4
cd /data/aparna/GA/DRIPc/DRIP_model/7stateGA/
./G_A_7states_random.pl ../../2_DRIPcsmallregion.wig.customfa DRIP_NT2_7states.hmm out/ 25 50 0.9 8 

# 4 state GA DRIPc DRIP model
echo "4 state GA DRIPc DRIP model"
cd /data/aparna/GA/DRIPc/DRIP_model/4stateGA/
./G_A_DRIPc_4state_random.pl ../../2_DRIPcsmallregion.wig.customfa DRIP_NT2_-small-sharp_moreem.hmm out/ 25 50 0.9 8

