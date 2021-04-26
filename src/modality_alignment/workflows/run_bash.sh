#!/bin/bash

# Run this prior to executing this script:
# bin/project_build -q 'modality_alignment|utils'

# get the root of the directory
REPO_ROOT=$(git rev-parse --show-toplevel)

# ensure that the command below is run from the root of the repository
cd "$REPO_ROOT"

TARGET=target/docker/modality_alignment
OUTPUT=output_bash/modality_alignment

mkdir -p $OUTPUT/datasets
mkdir -p $OUTPUT/methods
mkdir -p $OUTPUT/metrics

# generate datasets
if [ ! -f "$OUTPUT/datasets/citeseq_cbmc.h5ad" ]; then
  wget 'https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE100866&format=file&file=GSE100866%5FCBMC%5F8K%5F13AB%5F10X%2DRNA%5Fumi%2Ecsv%2Egz' -O "$OUTPUT/datasets/citeseq_cbmc_input1.csv.gz"
  wget 'https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE100866&format=file&file=GSE100866%5FCBMC%5F8K%5F13AB%5F10X%2DADT%5Fumi%2Ecsv%2Egz' -O "$OUTPUT/datasets/citeseq_cbmc_input2.csv.gz"
  "$TARGET/datasets/scprep_csv/scprep_csv" \
    --input1 "$OUTPUT/datasets/citeseq_cbmc_input1.csv.gz" \
    --input2 "$OUTPUT/datasets/citeseq_cbmc_input2.csv.gz" \
    --output "$OUTPUT/datasets/citeseq_cbmc.h5ad"
fi

# run all methods on all datasets
for meth in `ls "$TARGET/methods"`; do
  for dat in `ls "$OUTPUT/datasets"`; do
    dat_id="${dat%.*}"
    input_h5ad="$OUTPUT/datasets/$dat_id.h5ad"
    output_h5ad="$OUTPUT/methods/${dat_id}_$meth.h5ad"
    if [ ! -f "$output_h5ad" ]; then
      echo "> $TARGET/methods/$meth/$meth -i $input_h5ad -o $output_h5ad"
      "$TARGET/methods/$meth/$meth" -i "$input_h5ad" -o "$output_h5ad"
    fi
  done
done

# run all metrics on all outputs
for met in `ls "$TARGET/metrics"`; do
  for outp in `ls "$OUTPUT/methods"`; do
    out_id="${outp%.*}"
    input_h5ad="$OUTPUT/methods/$out_id.h5ad"
    output_h5ad="$OUTPUT/metrics/${out_id}_$met.h5ad"
    if [ ! -f "$output_h5ad" ]; then
      echo "> $TARGET/metrics/$met/$met" -i "$input_h5ad" -o "$output_h5ad"
      "$TARGET/metrics/$met/$met" -i "$input_h5ad" -o "$output_h5ad"
    fi
  done
done

# concatenate all scores into one tsv
INPUTS=$(ls -1 "$OUTPUT/metrics" | sed "s#.*#-i '$OUTPUT/metrics/&'#" | tr '\n' ' ')
eval "$TARGET/../utils/extract_scores/extract_scores" $INPUTS -o "$OUTPUT/scores.tsv"
