#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem 128gb -p batch
#SBATCH --time=3-00:15:00
#SBATCH --output=logs/train.%a.log
#SBATCH --job-name="TrainFun"

# Define program name
module load funannotate
MEM=128G

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
# Set some vars
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
export PASACONF=$HOME/pasa.config.txt

# Determine CPUS
if [[ -z ${SLURM_CPUS_ON_NODE} ]]; then
    CPUS=1
else
    CPUS=${SLURM_CPUS_ON_NODE}
fi


N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
ODIR=annotate
INDIR=genomes
RNAFOLDER=lib/RNASeq
SAMPLEFILE=samples.csv
IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SPECIES STRAIN VERSION PHYLUM BIOPROJECT BIOSAMPLE LOCUSTAG
do
    echo "SPECIES is $SPECIES"
    SPECIESNOSPACE=$(echo -n "$SPECIES" | perl -p -e 's/\s+/_/g')
    if [[ ! -d $RNAFOLDER/$SPECIESNOSPACE || ! -f $RNAFOLDER/$SPECIESNOSPACE/Forward.fq.gz ]]; then
	     echo "For training step Need RNASeq files in folder  $RNAFOLDER/$SPECIESNOSPACE as  $RNAFOLDER/$SPECIESNOSPACE/Forward.fq.gz and  $RNAFOLDER/$SPECIESNOSPACE/Reverse.fq.gz"
	     exit
    fi
    BASE=$(echo -n ${SPECIES}_${STRAIN}.${VERSION} | perl -p -e 's/\s+/_/g')
    echo "sample is $BASE"
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
	     echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
       exit
    fi
    STRAINFIX=$(echo -n $STRAIN | perl -p -e 's/-/_/g')
    echo $ODIR/$BASE/training
    funannotate train -i $MASKED -o $ODIR/$BASE \
   	--jaccard_clip --species "$SPECIES" --isolate $STRAINFIX \
  	--cpus $CPUS --memory $MEM  --pasa_db mysql \
  	--left $RNAFOLDER/$SPECIESNOSPACE/Forward.fq.gz --right $RNAFOLDER/$SPECIESNOSPACE/Reverse.fq.gz
    # add --pasa_db mysql to the options above if you have installed mysql and configured it in your ~/pasa.config.txt file
done
