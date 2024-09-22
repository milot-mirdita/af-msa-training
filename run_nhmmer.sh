#!/bin/bash -e

INPUT=$1
OUTPUT=$2
TMP_DIR=$3

open_sem() {
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for ((;i>0;i--)); do
        printf %s 000 >&3
    done
}

# run the given command asynchronously and pop/push tokens
run_with_lock() {
    local x
    # this read waits until there is something to read
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
        ( "$@"; )
        # push the return code of the command to the semaphore
        printf '%.3d' $? >&3
    )&
}

task() {
    echo ">query" > ${TMP_DIR}/${KEY}_query.fasta
    dd if=${INPUT}/qdb ibs=1 skip="${QOFF}" count="$((QLEN - 1))" status=none \
        | tr 'T' 'U' >> ${TMP_DIR}/${KEY}_query.fasta
    dd if=${INPUT}/unaligned_msa ibs=1 skip="${ROFF}" count="$((RLEN - 1))" status=none \
        | sed '/^>/!s/T/U/g' > ${TMP_DIR}/${KEY}_res.fasta
    EVAL=0.00005
    if [ $QLEN -lt 52 ]; then
        EVAL=0.02
    fi
    hmmbuild --rna -o /dev/null --cpu 0 -O ${TMP_DIR}/${KEY}_query.sto ${TMP_DIR}/${KEY}_query.hmm ${TMP_DIR}/${KEY}_query.fasta
    nhmmer -Z 754841 -o /dev/null -A ${TMP_DIR}/${KEY}_msa.sto --cpu 0 -E 0.001 --incE 0.001 --rna --watson --F3 ${EVAL} ${TMP_DIR}/${KEY}_query.hmm ${TMP_DIR}/${KEY}_res.fasta
    if [ -s "${TMP_DIR}/${KEY}_msa.sto" ]; then
        hmmalign --rna --outformat a2m --mapali ${TMP_DIR}/${KEY}_query.sto ${TMP_DIR}/${KEY}_query.hmm ${TMP_DIR}/${KEY}_msa.sto > ${OUTPUT}/${KEY}_msa.a2m
    fi
    rm -f -- ${TMP_DIR}/${KEY}_query.{fasta,sto,hmm} ${TMP_DIR}/${KEY}_res.fasta ${TMP_DIR}/${KEY}_msa.sto
}

N=64
open_sem $N
while read -r KEY QOFF QLEN ROFF RLEN; do
    run_with_lock task "${KEY}" "${QOFF}" "${QLEN}" "${ROFF}" "${RLEN}"
done < <(awk 'NR == FNR { f[$1] = $2"\t"$3; next; } $1 in f { print $0"\t"f[$1]; }' "${INPUT}/unaligned_msa.index" "${INPUT}/qdb.index")

wait
