#!/bin/bash
# -----------------------------Name of the job-------------------------
#SBATCH --job-name=snp_sync
#-----------------------------Output files-----------------------------
#SBATCH --output=logs_slurm/output_%j.txt
#SBATCH --error=logs_slurm/error_output_%j.txt
#-----------------------------Other information------------------------
#SBATCH --comment='DK angsd'
#-----------------------------Required resources-----------------------
#SBATCH --time=96:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=40G
#SBATCH --array=1   #adjust to amount samples!  

set -euo pipefail

## Basic pipeline for SNP identification
# set Condition paths
myIdxPath="/zfs/omics/projects/cevolution/dictionaries/Celegans"
myBamPath="/zfs/omics/projects/cevolution/1_CnemEvol/3_CE_mapped/bam"
myOutPath="/zfs/omics/projects/cevolution/1_CnemEvol/5_PCA_CnemAll/output_Nov2026"

# set file names
ref_index="WBcel235_ref"

IDout="Cnem_AllSamples_mpileup"

BamList="$myBamPath/Gent_bb_1_1_CE_2CE_sort_woDup_filt.bam $myBamPath/UVA_anc_0_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_1_2_CE_2CE_sort_woDup_filt.bam $myBamPath/UVA_anc_0_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_1_3_CE_2CE_sort_woDup_filt.bam $myBamPath/UVA_bb_0_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_1_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_0_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_15_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_0_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_15_2_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_0_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_15_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_0_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_15_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_0_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_bb_15_5_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_1_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_iso_15_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_1_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_iso_15_2_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_1_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_iso_15_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_1_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/Gent_iso_15_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_15_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_1_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_15_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_1_2_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_15_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_1_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_15_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_1_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_15_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_15_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bb_1_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_15_2_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_0_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_15_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_0_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_15_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_0_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_15_5_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_0_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_A00_1_5_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_0_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_bb_1_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_15_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_bb_1_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_15_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_bb_1_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_15_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_bb_15_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_15_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_bb_15_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn50_15_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_bb_15_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_0_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_1_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_0_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_1_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_0_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_1_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_0_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_15_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_0_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_15_3_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_15_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_15_4_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_15_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_15_5_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_15_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/NIOO_M00_1_5_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_15_4_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_1_1_CE_2CE_sort_woDup_filt.bam $myBamPath/VU_bn5_15_5_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_1_2_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bb_1_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_1_4_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bb_1_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_15_1_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bb_1_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_15_2_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bb_15_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_15_3_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bb_15_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_15_4_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bb_15_3_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_15_5_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bleach_15_1_CE_2CE_sort_woDup_filt.bam \
$myBamPath/RUG_bb_1_5_CE_2CE_sort_woDup_filt.bam $myBamPath/WUR_bleach_15_2_CE_2CE_sort_woDup_filt.bam \
$myBamPath/UVA_anc_0_1_CE_2CE_sort_woDup_filt.bam"

# Perform mpileup: Alignments are piled up for every position on the reference genome. and 
# Variant calling - Here, only variants are called are given as an output.

### Here, I tale all ALT along with the -A option, completely bipassing the diploid bias that bcftools has
bcftools mpileup -L 10000 -a FORMAT/AD -a FORMAT/DP -d 8000 \
    -f $myIdxPath/$ref_index".fasta" $BamList | \
bcftools call -m -A - > $myOutPath/$IDout"_bcfcall.vcf"

########################
#######################
### Filtering the bcfcall output

## PART A: Get information:

## RESULTS:
## How many position are missing from the bcf.vcf file:
## grep -v "^#" $myOutPath/$IDout".vcf" | wc -l
## 

## How many position are there in total in the bcfcall.vcf file:
## grep -v "^#" $myOutPath/$IDout"_bcfcall.vcf" | wc -l
## 700.000

#################################
## PART B: Filter out the lines you don't want

##
# 1. Exclude INDELS
bcftools view -i 'TYPE="SNP"' $myOutPath/$IDout"_bcfcall.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS.vcf"

## How many positions are only SNP?
#grep -v "^#" $myOutPath/$IDout"_bcfcall_woINDELS.vcf" | wc -l
#604213 (95787 INDELs excluded)

##
# 2. exclude specific samples
## Figuring out which samples:

## If I include all samples, I loose super many positions when filtering for DP
#bcftools filter -e 'FORMAT/DP[*]==0' $myOutPath/$IDout"_bcfcall_woINDELS.vcf" | grep -v "^#" | wc -l
#507897
#bcftools filter -e 'FORMAT/DP[*]<=10' $myOutPath/$IDout"_bcfcall_woINDELS.vcf" | grep -v "^#" | wc -l
#23824
#bcftools filter -e 'FORMAT/DP[*]<=20' $myOutPath/$IDout"_bcfcall_woINDELS.vcf" | grep -v "^#" | wc -l
#2872

## Exclude samples:
# Exclude 14 samples that have the worst coverage by providing the ones that should stay in in a list:
#(if you read out samples like this, then the number of rows stays the same as in the source file and also the global DP stays the same)

bcftools view --samples-file $myOutPath/FilterData_forPCA_KeepAllBut10WorstSamples.txt $myOutPath/$IDout"_bcfcall_woINDELS.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS_wo10Samples.vcf"
bcftools view --samples-file $myOutPath/FilterData_forPCA_KeepAllBut14WorstSamples.txt $myOutPath/$IDout"_bcfcall_woINDELS.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples.vcf"
# bcftools view --samples-file $myOutPath/FilterData_forPCA_KeepAllBut24WorstSamples.txt $myOutPath/$IDout"_bcfcall_woINDELS.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS_wo24Samples.vcf"

# bcftools filter -e 'FORMAT/DP[*]<=20' Cnem_AllSamples_mpileup_bcfcall_woINDELS_wo10Samples.vcf | wc -l
## 208283
# bcftools filter -e 'FORMAT/DP[*]<=20' Cnem_AllSamples_mpileup_bcfcall_woINDELS_wo14Samples.vcf | wc -l
## 365372
## -> conclusion, go for the one where 14 samples are not in, because then I have much more positions
## samples that are out: NIOO_A00_1_4, _5; NIOO_A00_15_1, _5; NIOO_bb_15_3; NIOO_bb_1_4; NIOO_M00_1_ALL (_1,_3,_4,_5); Gent_iso_15_4; VU_bb_15_2; VU_bn5_15_3,_5 

## Filter for coverage bigger 20
bcftools filter -e 'FORMAT/DP[*]<=20' $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20.vcf"

## grep -v "^#" $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20.vcf" | wc -l
# 365324

## Filter out positions in which not maximum 1 sample has an allelic count of at least 3
## FORMAT/AD[*:1] or AD[:1]        .. any sample, second AD field
bcftools filter -e 'MAX(AD[*:1])<=2' $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20_maxAD3.vcf" 

# grep -v "^#" $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20_maxAD3.vcf" | wc -l
# 364809


## Get the data out that I want
bcftools query -f "%CHROM\t[%DP,%AD\t]\n" $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20_maxAD3.vcf" > $myOutPath/$IDout"_bcfcall_woINDELS_wo14Samples_DP20_maxAD3_QUERY.txt"

