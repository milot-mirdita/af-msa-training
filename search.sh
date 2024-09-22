#!/bin/sh -ex

#SET=val
SET=test
#SET=train
INPUT=./data_caches/${SET}_clusterings/sequences_protein.fasta

mkdir -p /mnt/scratch/mmirdit/af3/msa/${SET}_protein
MMSEQS_IGNORE_INDEX=1 colabfold_search ./data_caches/${SET}_clusterings/sequences_protein.fasta /fast/databases/colabfold_db_all/ /mnt/scratch/mmirdit/af3/msa/${SET}_protein --db1 uniref30_2202_db --db2 pdball_230102_db --db3 colabfold_envdb_202108_db --use-env 1 --use-templates 1 --filter 1 --mmseqs /storage/mmirdit/af3/mmseqs/bin/mmseqs --db-load-mode 0 --threads 128

mkdir -p ./data_caches/${SET}_msa/protein/
cp -r /mnt/scratch/mmirdit/af3/msa/${SET}_protein ./data_caches/${SET}_msa/protein/
