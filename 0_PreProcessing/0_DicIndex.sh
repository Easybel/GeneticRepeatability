#specify the software that is needed, the path to the dict and the name if the dict
#Define input and output paths
#In the myQCPath there should be a folder called FastQC_AfterTrimm, where the trimmed QC of the results will be put

myDictPath="/home/irathman/scripts/scripts_git/test"

#Define folders where software is installed

# here you map against: .fasta
dict="BsubNC_000964wt"

bwa index $myDictPath/$dict.fasta
samtools faidx $myDictPath/$dict.fasta
