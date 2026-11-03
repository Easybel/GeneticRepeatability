#!/bin/bash
set -euo pipefail
# -----------------------------Name of the job-------------------------
#SBATCH --job-name="Map-removeHost"
#-----------------------------Output files-----------------------------
#SBATCH --output=logs_slurm/output_%j.txt
#SBATCH --error=logs_slurm/error_output_%j.txt
#-----------------------------Other information------------------------
#SBATCH --comment='COMMENT'
#-----------------------------Required resources-----------------------
#SBATCH --time=48:00:00   # Adjust the time limit accordingly
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8  # Adjust this based on your system's configuration
#SBATCH --mem-per-cpu=16G  # Adjust this based on your memory requirements
#SBATCH --array=1-17
i=$SLURM_ARRAY_TASK_ID

#Define input and output paths.
myDataTrim="/zfs/omics/projects/cevolution/Trim"
myIdxPath="/zfs/omics/projects/cevolution/dictionaries/Celegans"
myBamPath="/zfs/omics/projects/cevolution/Out"

# Set file names
ref_index="WBcel235_ref" # Change this to your reference index (already indexed reference genome)

# in order to loop, automatically get the file names following some rules
ID=$(ls -1 $myDataTrim | grep 'Gent\|UVA' | grep "1P" | grep -v "TrimLog" | sed -n ''$i'p'| cut -d'_' -f1,2,3,4)
IDout=$ID"_2CE"

# Mapping with BWA - and convert to bam to save space
bwa mem -t $SLURM_CPUS_PER_TASK $myIdxPath/$ref_index".fasta" $myDataTrim/$ID"_1P.fastq.gz" $myDataTrim/$ID"_2P.fastq.gz" |\
 samtools view --threads 1 -bS - -o $myBamPath/$IDout"_all.bam"

# sort the reads according to names
samtools sort -n $myBamPath/$IDout"_all.bam" -o $myBamPath/$IDout"_all_sort.bam"

####
##### Get the unmapped reads and separate them in fastq files
# split the reads into separate files .._R1 ..R2 & singletons
samtools fastq -f 4 -F 256 -@ 8 $myBamPath/$IDout"_all_sort.bam" \
  -1 $myDataTrim/$ID"_CE_removed_R1.fastq.gz" \
  -2 $myDataTrim/$ID"_CE_removed_R2.fastq.gz" \
  -0 /dev/null -s $myDataTrim/$ID"_CE_removed_S.fastq.gz" -n


####
##### Get the mapped reads and separate them in fastq files

# exclude all unmapped and none-primary alignments
samtools fastq -f 1 -F 4 -F 256 -@ 8 $myBamPath/$IDout"_all_sort.bam" \
  -1 $myDataTrim/$ID"_CE_R1.fastq.gz" \
  -2 $myDataTrim/$ID"_CE_R2.fastq.gz" \
  -0 /dev/null -s $myDataTrim/$ID"_CE_S.fastq.gz" -n
  
rm $myBamPath/$IDout"_all.bam" $myBamPath/$IDout"_all_sort.bam"
