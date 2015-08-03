#!/bin/bash

# !!!!Replace it with your own directory!!!
SICER=/data/aparna/SICER1.1/SICER

# ["InputDir"] ["bed file"] ["OutputDir"] ["species"] ["redundancy threshold"] ["window size (bp)"] ["fragment size"] ["effective genome fraction"] ["gap size (bp)"] ["E-value"]
#default
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex test.bed . hg18 1 200 150 0.74 400 100
#Gap 1000
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg18 1 200 150 0.74 1000 100
#E-value .50 HG 19 !!!
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 200 150 0.74 400 .50
#default HG 19
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 200 150 0.74 400 100
#E-value .0005 HG 19 !!!
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 200 150 0.74 400 .0005
#E-value .00000005 HG 19 !!!
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 200 150 0.74 400 .00000005
#E-value .00000005 Window 600 Gap 600 HG 19 !!!
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 600 150 0.74 600 .00000005
#E-value .00000005 Window 100 Gap 400 HG 19 !!!
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 100 150 0.74 400 .00000005
#E-value .00000005 Window 50 Gap 400 HG 19 !!!
#sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 50 150 0.74 400 .00000005
#E-value 5-15 Window 100 Gap 400 HG 19 !!!
sh $SICER/SICER-rb.sh /data/aparna/SICER1.1/SICER/ex chr19.bed . hg19 1 100 150 0.74 400 .000000000000005
