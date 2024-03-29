#!/bin/bash -l
#SBATCH -p batch --time 5-0:00:00 --ntasks 16 --nodes 1 --mem 48G --out logs/update.%a.log

module load funannotate

#PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)
#TRINITYHOMEPATH=$(dirname `which Trinity`)

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
MEM=64G
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi

INDIR=genomes
OUTDIR=annotate
SAMPFILE=samples.csv

N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`
if [ -z "$MAX" ]; then
    MAX=0
fi
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
export PASACONF=$HOME/pasa.config.txt
SBT=lib/sbt/AG-B5.sbt
#$(realpath lib/authors.sbt) # this can be changed
#
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN VERSION PHYLUM BIOSAMPLE BIOPROJECT LOCUSTAG
do
  #  defaults to using sqlite - if you used mysql in the 02_train_RNASeq.sh step then you would add '--pasa_db mysql' to the options
  BASE=$(echo -n ${SPECIES}_${STRAIN}.${VERSION} | perl -p -e 's/\s+/_/g')
  funannotate update --cpus $CPU -i $OUTDIR/$BASE --out $OUTDIR/$BASE --sbt $SBT --memory $MEM --pasa_db mysql
done
