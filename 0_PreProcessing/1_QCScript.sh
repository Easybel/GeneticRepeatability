#!/bin/bash
# -----------------------------Name of the job-------------------------
#SBATCH --job-name=GC_content
#-----------------------------Mail address-----------------------------
#SBATCH --mail-user=emma.diepeveen@hotmail.com
#SBATCH --mail-type=ALL
#-----------------------------Output files-----------------------------
#SBATCH --output=logs_slurm/output_%j.txt
#SBATCH --error=logs_slurm/error_output_%j.txt
#-----------------------------Other information------------------------
#SBATCH --comment='DK angsd'
#-----------------------------Required resources-----------------------
#SBATCH --time=24:00:00   # Adjust the time limit accordingly
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8  # Adjust this based on your system's configuration
#SBATCH --mem-per-cpu=16G  # Adjust this based on your memory requirements
#SBATCH --array=1 
i=$SLURM_ARRAY_TASK_ID


# Folders for data
myDataRaw="/zfs/omics/projects/cevolution/Raw"
myQCRaw="/zfs/omics/projects/cevolution/Raw/QC"
myDataTrim="/zfs/omics/projects/cevolution/Trim"
myQCTrim="/zfs/omics/projects/cevolution/Trim/QC"

# Define folders where software is installed.
TrimmFold="/zfs/omics/software/packages/Trimmomatic-0.39"

# Define the name of data file or retrieve the name for every run i.
#ID="63297_ID1932_1-DNA1_S4_L001_R"
# possible way of looping over samples:
ID=$(ls -1 $myDataRaw | grep "R" | grep "1_1.fastq.gz" | sed -n ''$i'p'| cut -d"_" -f1)

# Perform FastQC quality control on the raw reads.
fastqc -o $myQCRaw/ $myDataRaw/$ID"1_001.fastq.gz" -t 8
fastqc -o $myQCRaw/ $myDataRaw/$ID"2_001.fastq.gz" -t 8

cd $TrimmFold
java -Xmx30G -Xms24G -jar trimmomatic-0.39.jar PE -threads 8 -trimlog $myDataRaw/$ID.TrimLog $myDataRaw/$ID"1_001.fastq.gz" $myDataRaw/$ID"2_001.fastq.gz" $myDataTrim/$ID"_1P".fastq.gz $myDataTrim/$ID"_1U".fastq.gz $myDataTrim/$ID"_2P".fastq.gz $myDataTrim/$ID"_2U".fastq.gz ILLUMINACLIP:$TrimmFold/adapters/TruSeq3-PE-2.fa:2:30:10:4 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# Perform FastQC quality control again on trimmed data.
fastqc -o $myQCTrim $myDataTrim/$ID"_1P.fastq.gz" -t 8
fastqc -o $myQCTrim $myDataTrim/$ID"_2P.fastq.gz" -t 8

exit 0
