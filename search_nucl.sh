#!/bin/sh -ex

#SET=val
# SET=test
#SET=train
for SET in train; do
# for SET in val test train; do
    INPUT=./data_caches/${SET}_clusterings/sequences_nucleic_acid.fasta

    # MMSEQS=/storage/mmirdit/af3/mmseqs/bin/mmseqs
    MMSEQS=/storage/mmirdit/af3/mmseqs-git/build/src/mmseqs
    BASE=$SCRATCH/af3/msa/${SET}_nucleic_acid_search
    mkdir -p "${BASE}"
    # export MMSEQS_IGNORE_INDEX=1 
    # export MMSEQS_FORCE_MERGE=1
    # "${MMSEQS}" createdb "${INPUT}" "${BASE}/qdb"
    # "${MMSEQS}" search "${BASE}/qdb" /fast/mmirdit/af3/nucl_db "${BASE}/res" "${BASE}/tmp" -k 7 --spaced-kmer-mode 0 --search-type 3 --threads 128 --max-seqs 500000 -e 10000 --max-seq-len 65534 

    #mkdir -p ./data_caches/${SET}_msa/nucleic_acid_search
    #cp -r "${BASE}/qdb"* "${BASE}/res"* ./data_caches/${SET}_msa/nucleic_acid_search

    # mkdir -p ./data_caches/${SET}_msa/nucleic_acid
    # if [ ! -e "${BASE}/unaligned_msa.dbtype" ]; then
    #     MMSEQS_FORCE_MERGE=1 "${MMSEQS}" createseqfiledb /fast/mmirdit/af3/nucl_db "${BASE}/res" "${BASE}/unaligned_msa"
    # fi
    # ./run_nhmmer.sh "${BASE}" "./data_caches/${SET}_msa/nucleic_acid" /dev/shm
    # "${MMSEQS}" rmdb "${BASE}/unaligned_msa"
    N=10

    # Create the output directory if it doesn't exist
    mkdir -p ./data_caches/${SET}_msa/nucleic_acid

    # Calculate total lines and lines per split
    # TOTAL_LINES=$(wc -l < "${BASE}/res.index")
    # LINES_PER_SPLIT=$(( (TOTAL_LINES + N - 1) / N ))

    # # Split the res.index file into N parts with numeric suffixes
    # split -l "${LINES_PER_SPLIT}" -d -a 3 "${BASE}/res.index" "${BASE}/res.index.split_"

    for SPLIT_FILE in "${BASE}/res.index.split_"*; do
        # Generate a unique base directory for each split
        SPLIT_SUFFIX=$(basename "${SPLIT_FILE}" | sed 's/res.index.split_//')
        SPLIT_BASE="${BASE}/split_${SPLIT_SUFFIX}"
        mkdir -p "${SPLIT_BASE}"

        if [ ! -e "${SPLIT_BASE}/res.dbtype" ]; then
            "${MMSEQS}" createsubdb "${SPLIT_FILE}" "${BASE}/res" "${SPLIT_BASE}/res" --subdb-mode 1
        fi
        if [ ! -e "${SPLIT_BASE}/qdb.dbtype" ]; then
            "${MMSEQS}" createsubdb "${SPLIT_FILE}" "${BASE}/qdb" "${SPLIT_BASE}/qdb" --subdb-mode 1
        fi
        if [ ! -e "${SPLIT_BASE}/unaligned_msa.dbtype" ]; then
            MMSEQS_FORCE_MERGE=1 "${MMSEQS}" createseqfiledb /fast/mmirdit/af3/nucl_db "${SPLIT_BASE}/res" "${SPLIT_BASE}/unaligned_msa"
        fi
        ./run_nhmmer.sh "${SPLIT_BASE}" "./data_caches/${SET}_msa/nucleic_acid" /dev/shm

        "${MMSEQS}" rmdb "${SPLIT_BASE}/unaligned_msa"
        "${MMSEQS}" rmdb "${SPLIT_BASE}/res"
        "${MMSEQS}" rmdb "${SPLIT_BASE}/qdb"

        rm -rf -- "${SPLIT_BASE}"
        rm -f -- "${SPLIT_FILE}"
    done

done
