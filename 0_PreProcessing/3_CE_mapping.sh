#!/bin/bash
# -----------------------------Name of the job-------------------------
#SBATCH --job-name=Map-onlyCE
#-----------------------------Output files-----------------------------
#SBATCH --output=logs_slurm/output_%j.txt
#SBATCH --error=logs_slurm/error_output_%j.txt
#-----------------------------Other information------------------------
#SBATCH --comment='COMMENT'
#-----------------------------Required resources-----------------------
#SBATCH --time=30:00:00   # Adjust the time limit accordingly
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8  # Adjust this based on your system's configuration
#SBATCH --mem-per-cpu=16G  # Adjust this based on your memory requirements
#SBATCH --array=1-47%15   #adjust to amount samples!  
set -euo pipefail

i=$SLURM_ARRAY_TASK_ID

#Define input and output paths.
myDataTrim="/zfs/omics/projects/cevolution/1_CnemEvol/2_Trim"
myIdxPath="/zfs/omics/projects/cevolution/dictionaries/Celegans"
myBamPath="/scratch/easy"

# Set file names
ref_index="WBcel235_ref" # Change this to your reference index (already indexed reference genome)

#CHECK THIS!
#in order to loop, automatically get the file names following some rules
ID=$(ls -1 $myDataTrim | grep "R1" | grep "_CE_" | sed -n ''$i'p'| cut -d'_' -f1,2,3,4,5)
IDout=$ID"_2CE"

#index reference genome
#already done! (with bwa index)

# Mapping with BWA - and convert to bam to save space
## add read group tags to that the reads can be associated correctly by name in downstream analysis (such as bcftools, GATK, ..)
 
bwa mem -t $SLURM_CPUS_PER_TASK -M \
-R "@RG\tID:${IDout}\tSM:${IDout}\tPL:ILLUMINA\tLB:${IDout}" \
$myIdxPath/$ref_index".fasta" $myDataTrim/$ID"_R1.fastq.gz" $myDataTrim/$ID"_R2.fastq.gz" |\
samtools view --threads 1 -bS - -o $myBamPath/$IDout".bam"
    
    

#sort bam files based on coordinates 
samtools sort $myBamPath/$IDout".bam" -o $myBamPath/$IDout"_sort.bam"

#remove duplicate reads with Picard https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard 
/zfs/omics/software/bin/picard MarkDuplicates -I $myBamPath/$IDout"_sort.bam" -M $myBamPath/$IDout"_marked_dup_metrics" -O $myBamPath/$IDout"_sort_woDup.bam" --REMOVE_DUPLICATES
# -I input file SAM, BAM or CRAN. must be coordinate sorted !
# -M file to write duplication metrics
# -O output file to write the marked records
# -- REMOVE_DUPLICATES -> removes the found duplicates

## now also sort for min MAPQ quality of 20 and only keep properly mapped and paired reads:
samtools view -q 20 -f 0x0002 -F 0x0004 -F 0x0008 -b $myBamPath/$IDout"_sort_woDup.bam" > $myBamPath/$IDout"_sort_woDup_filt.bam"

#index bam file
samtools index $myBamPath/$IDout"_sort_woDup_filt.bam"

#collect alignment & insert size metrics (https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/)
#tools: Picard Tools, R, Samtools
/zfs/omics/software/bin/picard CollectAlignmentSummaryMetrics R=$myIdxPath/$ref_index".fasta" I=$myBamPath/$IDout"_sort_woDup_filt.bam" O=$myBamPath/$IDout"_sort_woDup_filt_AlignSum.txt"
# -R = reference genome 
# -I = sorted bam file
# -O = alignment_metrics.txt

/zfs/omics/software/bin/picard CollectInsertSizeMetrics I=$myBamPath/$IDout"_sort_woDup_filt.bam" O=$myBamPath/$IDout"_sort_woDup_filt_insertsizeMetric.txt" H=$myBamPath/$IDout"_sort_woDup_filt_HistSize.pdf" M=0.5
# INPUT: sorted bam file
# OUTPUT: insert metrics.txt
# HISTOGRAM_FILE: insert_size_histogram.pdf

# -a = sorted bam file   
samtools depth -a $myBamPath/$IDout"_sort_woDup_filt.bam" > $myBamPath/$IDout"_cov.txt"

## clean up the bams: 
rm $myBamPath/$IDout".bam" \
     $myBamPath/$IDout"_sort.bam" \
     $myBamPath/$IDout"_sort_woDup.bam"
     
## copy the created data to the final destination
cp $myBamPath/$IDout"_sort_woDup_filt"* /zfs/omics/projects/cevolution/1_CnemEvol/3_CE_mapped/bam/new
cp $myBamPath/$IDout"_cov.txt" /zfs/omics/projects/cevolution/1_CnemEvol/3_CE_mapped/bam/new
