#!/bin/bash

#macs14 -t /data/shared/Normalization/Preprocess/Human/HEK293_DRIP.sam -f SAM -n HEK293_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Human/HeLa_DRIP.sam -f SAM -n HeLa_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Human/K562_DRIP.sam -f SAM -n K562_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Human/NT21_DRIP.sam -f SAM -n NT21_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Human/NT22_DRIP.sam -f SAM -n NT22_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Human/NT2RNAseA_DRIP.sam -f SAM -n NT2RNAseA_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Human/NT2RNAseH_DRIP.sam -f SAM -n NT2RNAseH_DRIP -g hs -w
#macs14 -t /data/shared/Normalization/Preprocess/Mouse/3T3_DRIP.sam -f SAM -n 3T3_DRIP -g mm -w
#macs14 -t /data/shared/Normalization/Preprocess/Mouse/E14_DRIP.sam -f SAM -n E14_DRIP -g mm -w

#cat 3T3_DRIP_MACS_wiggle/treat/*.gz > wigs/3T3_DRIP.wig.gz
#cat E14_DRIP_MACS_wiggle/treat/*.gz > wigs/E14_DRIP.wig.gz
#cat Fibro2_DRIP_MACS_wiggle/treat/*.gz > wigs/Fibro2_DRIP.wig.gz
#cat Fibro_DRIP_MACS_wiggle/treat/*.gz > wigs/Fibro_DRIP.wig.gz
#cat HEK293_DRIP_MACS_wiggle/treat/*.gz > wigs/HEK293_DRIP.wig.gz
#cat HeLa_DRIP_MACS_wiggle/treat/*.gz > wigs/HeLa_DRIP.wig.gz
#cat K562_DRIP_MACS_wiggle/treat/*.gz > wigs/K562_DRIP.wig.gz
#cat NT21_DRIP_MACS_wiggle/treat/*.gz > wigs/NT21_DRIP.wig.gz
#cat NT22_DRIP_MACS_wiggle/treat/*.gz > wigs/NT22_DRIP.wig.gz
#cat NT2RNAseA_DRIP_MACS_wiggle/treat/*.gz > wigs/NT2RNAseA_DRIP.wig.gz
#cat NT2RNAseH_DRIP_MACS_wiggle/treat/*.gz > wigs/NT2RNAseH_DRIP.wig.gz

./normalize.pl wigs/3T3_DRIP.wig X3T3_DRIP norm_wig/3T3_DRIP.wig.norm
#./normalize.pl wigs/E14_DRIP.wig E14_DRIP norm_wig/E14_DRIP.wig.norm
#./normalize.pl wigs/Fibro2_DRIP.wig Fibro2_DRIP norm_wig/Fibro2_DRIP.wig.norm
#./normalize.pl wigs/Fibro_DRIP.wig Fibro_DRIP norm_wig/Fibro_DRIP.wig.norm
#./normalize.pl wigs/HEK293_DRIP.wig 3T3_DRIP norm_wig/3T3_DRIP.wig.norm
#./normalize.pl wigs/HeLa_DRIP.wig HeLa_DRIP norm_wig/HeLa_DRIP.wig.norm
#./normalize.pl wigs/K562_DRIP.wig K562_DRIP norm_wig/K562_DRIP.wig.norm
#./normalize.pl wigs/NT21_DRIP.wig NT21_DRIP norm_wig/NT21_DRIP.wig.norm
#./normalize.pl wigs/NT22_DRIP.wig NT22_DRIP norm_wig/NT22_DRIP.wig.norm
#./normalize.pl wigs/NT2RNAseA_DRIP.wig NT2RNAseA_DRIP norm_wig/NT2RNAseA_DRIP.wig.norm
#./normalize.pl wigs/NT2RNAseH_DRIP.wig NT2RNAseH_DRIP norm_wig/NT2RNAseH_DRIP.wig.norm
