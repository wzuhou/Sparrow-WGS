#!/bin/bash
SAMPLE=$1          #Prefix     ## Give sample name via command line
RAWSEQ=./Raw_data/DNA_WGS/clean/$1      #./   ## Give full path to fastQ.gz files via command line
DATOUT=./WholeGenomeSequence/bam_dna/$1      #prefix   ## Give path for output directory
REF=./NCBI/GCF_028769735.1_RI_Zleu_2.0_genomic.fna
R_prefix=`less ./WholeGenomeSequence/Rawdata/${1}_fq`
READS_1=$RAWSEQ/paired_${R_prefix}1.fq.gz
READS_2=$RAWSEQ/paired_${R_prefix}2.fq.gz
#SAMPLE=${1} #Sample name

mkdir -p $DATOUT

# modules to load
module load igmm/libs/ncurses/6.0
module load igmm/libs/htslib/1.6
module load igmm/apps/samtools/1.20
module load java/jdk-22.0.1
module load igmm/apps/OpenJDK/17.0.11
module load roslin/bwa/0.7.18
module load igmm/apps/picard/3.1.1

# packages
bwa=`which bwa`
picard=`which picard` 

##############################
# Mapping reads with BWA
##############################
#Need to index the fasta first
# bwa index $REF
###
echo "mapping started for ${SAMPLE}: $(date)"
bwa mem -t 8 -M -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:Illumina\tLB:${SAMPLE}\tPU:unkn-0.0" ${REF} ${READS_1} ${READS_2} > ${DATOUT}/${SAMPLE}.sam

echo "mapping ended for ${SAMPLE}: $(date)"

# Sort SAM into coordinate order and save as BAM
mkdir -p ${DATOUT}/sortedBam

$picard SortSam \
  I=${DATOUT}/${SAMPLE}.sam \
  O=${DATOUT}/sortedBam/${SAMPLE}_sorted.bam \
  SORT_ORDER=coordinate  \
  TMP_DIR=${DATOUT}/tmp_${SAMPLE}

echo "Sorting complete for ${SAMPLE}: $(date)"

# Delete SAM file  (if sorted bam index file present)
if test -f ${DATOUT}/sortedBam/${SAMPLE}_sorted.bam
then
rm ${DATOUT}/${SAMPLE}.sam
fi

# Mark duplicates and create bam index
mkdir -p ${DATOUT}/metrics
mkdir -p ${DATOUT}/mdupBam

$picard  MarkDuplicates \
  I=${DATOUT}/sortedBam/${SAMPLE}_sorted.bam \
  O=${DATOUT}/mdupBam/${SAMPLE}_mdup.bam  \
  CREATE_INDEX=true  \
  M=${DATOUT}/metrics/${SAMPLE}_mdup_metrics.txt \
  TMP_DIR=${DATOUT}/tmp_${SAMPLE} \
  MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=4000 \
  OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500

echo "MarkDup finished for ${SAMPLE}: $(date)"

# Delete sorted Bam (if markduplicate index file present)
if test -f ${DATOUT}/mdupBam/${SAMPLE}_mdup.bai
then
rm ${DATOUT}/sortedBam/${SAMPLE}_sorted.bam
rm ${DATOUT}/sortedBam/${SAMPLE}_sorted.bai
fi

# Get flagstat of mdup bam file
echo "Flagstat of ${SAMPLE}_mdup.bam"
echo "########"
samtools flagstat ${DATOUT}/mdupBam/${SAMPLE}_mdup.bam
echo "###FINISHED ${SAMPLE}#####"
