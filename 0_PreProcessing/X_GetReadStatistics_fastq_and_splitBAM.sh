#!/bin/bash
# -----------------------------Name of the job-------------------------
#SBATCH --job-name="GetRead_Statistics"
#-----------------------------Output files-----------------------------
#SBATCH --output=logs_slurm/output_%j.txt
#SBATCH --error=logs_slurm/error_output_%j.txt
#-----------------------------Other information------------------------
#SBATCH --comment='Extract alignment statistics across mapping stages'
#-----------------------------Required resources-----------------------
#SBATCH --time=04:00:00             # Reduced time: flagstat is much faster!
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8           # Multi-threading for flagstat
#SBATCH --mem-per-cpu=4GB           # Low memory needed for statistics

set -eo pipefail

mkdir -p logs_slurm

# Define paths
TrimPath="/zfs/omics/projects/cevolution/1_CnemEvol/2_Trim"
BamFolderFiltered="/zfs/omics/projects/cevolution/1_CnemEvol/3_CE_mapped/bam"
outFolder="/zfs/omics/projects/cevolution/1_CnemEvol/3_CE_mapped/bam"
outName="Readstats_fromBamSplit_20261110.txt"

mkdir -p "$outFolder"
outFile="$outFolder/$outName"

# Correct Bash Array syntax (space-separated, no commas)
IDlist=(
"Gent_bb_1_1"
"Gent_bb_1_2"
"Gent_bb_1_3"
"Gent_bb_1_4"
"Gent_bb_15_1"
"Gent_bb_15_2"
"Gent_bb_15_3"
"Gent_bb_15_4"
"Gent_bb_15_5"
"Gent_iso_15_1"
"Gent_iso_15_2"
"Gent_iso_15_3"
"Gent_iso_15_4"
"NIOO_A00_1_1"
"NIOO_A00_1_2"
"NIOO_A00_1_3"
"NIOO_A00_1_4"
"NIOO_A00_15_1"
"NIOO_A00_15_2"
"NIOO_A00_15_3"
"NIOO_A00_15_4"
"NIOO_A00_15_5"
"NIOO_A00_1_5"
"NIOO_bb_1_1"
"NIOO_bb_1_3"
"NIOO_bb_1_4"
"NIOO_bb_15_1"
"NIOO_bb_15_3"
"NIOO_bb_15_4"
"NIOO_M00_1_1"
"NIOO_M00_1_3"
"NIOO_M00_1_4"
"NIOO_M00_15_1"
"NIOO_M00_15_3"
"NIOO_M00_15_4"
"NIOO_M00_15_5"
"NIOO_M00_1_5"
"RUG_bb_1_1"
"RUG_bb_1_2"
"RUG_bb_1_4"
"RUG_bb_15_1"
"RUG_bb_15_2"
"RUG_bb_15_3"
"RUG_bb_15_4"
"RUG_bb_15_5"
"RUG_bb_1_5"
"UVA_anc_0_1"
"UVA_anc_0_2"
"UVA_anc_0_3"
"UVA_bb_0_1"
"VU_bb_0_1"
"VU_bb_0_2"
"VU_bb_0_3"
"VU_bb_0_4"
"VU_bb_0_5"
"VU_bb_1_1"
"VU_bb_1_2"
"VU_bb_1_3"
"VU_bb_1_4"
"VU_bb_15_1"
"VU_bb_15_2"
"VU_bb_15_3"
"VU_bb_15_4"
"VU_bb_15_5"
"VU_bb_1_5"
"VU_bn50_0_1"
"VU_bn50_0_2"
"VU_bn50_0_3"
"VU_bn50_0_4"
"VU_bn50_0_5"
"VU_bn50_15_1"
"VU_bn50_15_2"
"VU_bn50_15_3"
"VU_bn50_15_4"
"VU_bn50_15_5"
"VU_bn5_0_1"
"VU_bn5_0_2"
"VU_bn5_0_3"
"VU_bn5_0_4"
"VU_bn5_0_5"
"VU_bn5_15_1"
"VU_bn5_15_2"
"VU_bn5_15_3"
"VU_bn5_15_4"
"VU_bn5_15_5"
"WUR_bb_1_1"
"WUR_bb_1_2"
"WUR_bb_1_3"
"WUR_bb_15_1"
"WUR_bb_15_2"
"WUR_bb_15_3"
"WUR_bleach_15_1"
"WUR_bleach_15_2"
)

# Write Header
echo -e "Sample_ID\tTrimmedReads_All\tTrimmedReads_CE\tTrimmedReads_woCE\tFinal_Filtered_CE_Reads" > "$outFile"

echo "=== Starting Read Statistics Extraction ==="

for IDhere in "${IDlist[@]}"; do
    echo "Processing sample: $IDhere"

    # Define file paths
    trim_all="$TrimPath/${IDhere}_1P.fastq.gz"

    trim_CE="$TrimPath/${IDhere}_CE_R1.fastq.gz"

    # Define file paths
    trim_woCE="$TrimPath/${IDhere}_CEremoved_R1.fastq.gz"

    # Define file paths
    filt_bam="$BamFolderFiltered/${IDhere}_CE_2CE_sort_woDup_filt.bam"


    # 2a. Get the number of reads from the fastq.gz files with only the CE reads
    Reads_all=$(echo $(( $(zcat $trim_all | wc -l) / 4 )))

    Reads_CE=$(echo $(( $(zcat $trim_CE | wc -l) / 4 )))

    # 2b. ... and for the removed CE files 
    Reads_woCE=$(echo $(( $(zcat $trim_woCE | wc -l) / 4 )))

    # 3. Reads after Quality & Pairing Filtering (MAPQ >= 20)
    if [ -f "$filt_bam" ]; then
        ReadswoDup_Filt=$(samtools view -c -@ "$SLURM_CPUS_PER_TASK" "$filt_bam")
    else
        ReadswoDup_Filt="NA"
    fi

    # Append row to result table
    echo -e "${IDhere}\t${Reads_all}\t${Reads_CE}\t${Reads_woCE}\t${ReadswoDup_Filt}" >> "$outFile"

done

echo "=== Finished! Results saved to $outFile ==="
