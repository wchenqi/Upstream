#!/bin/bash

## 脚本说明：
# 应用场景: 本脚本用于将下载的SRR文件转换为fastq
# 版本更新:
# v3: 使用fasterq-dump替换parallel-fastq-dump, 固定输出顺序

#参考:
# https://zhuanlan.zhihu.com/p/591140275
# https://zhuanlan.zhihu.com/p/536865827

## 指定参数
indir="/scratch/2026-06-22/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/00RawData/"
outdir="/scratch/2026-06-22/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/"

## 得到路径下sra文件
infiles=($(find ${indir} -name "SRR*" -type f -exec basename -a {} +))
echo ${infiles}

# 建立输出文件夹
outdir1=$outdir"/02Fastq/"
echo $outdir1
mkdir -p $outdir1

## 循环处理
# for f in ${infiles[@]}
# do
# echo ${f}
# # 指定输入文件名
# infile=$indir"/"${f}
# echo $infile

# ## 拆分文件
# time (fasterq-dump $infile --threads 10 --outdir $outdir1)

# done

# 指定输入文件名
infile="/scratch/2026-06-22/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/00RawData/SRR32154427.sra"
echo $infile
fasterq-dump $infile --threads 10 --outdir $outdir1
