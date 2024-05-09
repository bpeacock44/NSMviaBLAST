#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input_file output_dir"
    exit 1
fi

input_file="$1"
output_dir="$2"

if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

output_file="${output_dir}/uniq.$(basename "$input_file")"

usearch -fastx_uniques "$input_file" -fastqout "$output_file" -sizeout
