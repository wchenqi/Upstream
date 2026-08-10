#!/bin/bash
set -euo pipefail

#参考： 
# https://zhuanlan.zhihu.com/p/591140275
# https://zhuanlan.zhihu.com/p/536865827

outdir="/scratch/2026-05-18/med-wangcq/SelfUse/Heart/GSE153801/GSE153800_RNAseq/01fastq/"
indir="/scratch/2026-05-18/med-wangcq/SelfUse/Heart/GSE153801/GSE153800_RNAseq/00RawData/"
JOBS=5
# IDs=`ls `
# for i in $IDs
# do
# echo $i
# outdir1="${outdir}/${i}"
# echo $outdir1
# mkdir -p $outdir1
# infile="${indir}/${i}/${i}.sra"
# echo $infile
# #fastq-dump --split-files $infile -O $outdir1 --gzip
# time (parallel-fastq-dump -t 40 -O $outdir1 --split-3 --gzip -s $infile)
# done

find "$indir" -maxdepth 2 -type f -name "*.sra" | xargs -I {} -P $JOBS bash -c '
     i="$1"
     echo "${i}"
     sp=$(basename "${i}" .sra)
     echo ${sp}
     outdir1="'"${outdir}"'/${sp}"
     tmpdir="'"${outdir}"'/tmp/${sp}"
     mkdir -p "${outdir1}"
     mkdir -p "${tmpdir}"
     parallel-fastq-dump -t 6 -O "${outdir1}" -T "${tmpdir}" --split-3 -s "${i}"

     # 移除tmp文件夹
     rm -rf "'"${outdir}"'/tmp/"
' _ {}
