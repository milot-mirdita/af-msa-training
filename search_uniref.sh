#!/bin/sh -ex

# SET=test
# SET=val
SET=train
INPUT=./data_caches/${SET}_clusterings/sequences_protein.fasta

result=$SCRATCH/af3/msa_unfilt/${SET}_protein
base=$SCRATCH/af3/msa_unfilt/${SET}_protein_search
mkdir -p "${result}"
mkdir -p "${base}"

export MMSEQS_IGNORE_INDEX=1
export MMSEQS_NUM_THREADS=64
# export MMSEQS_FORCE_MERGE=0

mmseqs=/storage/mmirdit/af3/mmseqs/bin/mmseqs
db=/fast/databases/colabfold_db_all/uniref30_2202_db

search_param="--num-iterations 3 -a -e 0.1 --max-seqs 10000 -s 8"
expand_param="--expansion-mode 0 -e inf --expand-filter-clusters 0 --max-seq-id 0.95"

if false; then
"${mmseqs}" createdb "${INPUT}" "$base/qdb"
"${mmseqs}" search "$base/qdb" "${db}" "$base/res" "$base/tmp" $search_param
"${mmseqs}" expandaln "$base/qdb" "${db}_seq" "$base/res" "${db}_aln" "$base/res_exp" $expand_param
"${mmseqs}" align "$base/qdb" "${db}_seq" "$base/res_exp" "$base/res_exp_align" -e 0.001 -c 0.5 --cov-mode 1
"${mmseqs}" filterdb "$base/res_exp_realign" "$base/res_exp_align_50k" --extract-lines 50000
fi
/storage/mmirdit/af3/mmseqs-git/build/src/mmseqs result2msa "$base/qdb" "${db}_seq" "$base/res_exp_align_50k" "$base/res_exp_align_50k_msa" --msa-format-mode 5
tr ':' '_' < "$base/qdb.lookup" > "$base/res_exp_align_50k_msa.lookup"
"${mmseqs}" unpackdb "$base/res_exp_align_50k_msa" "$SCRATCH/af3/msa_unfilt/${SET}_protein" --unpack-name-mode 1 --unpack-suffix .a3m

mkdir -p ./data_caches/${SET}_msa_unfilt/protein/
cp -r $SCRATCH/af3/msa_unfilt/${SET}_protein ./data_caches/${SET}_msa_unfilt/protein/
