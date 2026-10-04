#!/bin/bash

### 脚本说明
## 工具在base环境

ref="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/CellRanger/scRNA_STseq/Download/refdata-gex-mm10-2020-A/"    # 参考注释文件路径, 见：/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/CellRanger/scRNA_STseq/Download/
indir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/02_fastq/01Test/"  # 输入包含fastq文件的总路径 indir/sampleid/fastq_file
outdir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/03_CellRanger/" # 输出文件路径
if [ ! -d $outdir ]; then
mkdir -p $outdir
fi
SP=`ls $indir`
for i in $SP
do
echo $i

## 这里添加判断
file=$(find "${indir}" -type f -name "${i}*" | head -n 1)

cellranger count \
    --id ${i} \
    --fastqs ${indir}/${i} \
    --sample ${i} \
    --expect-cells=10000 \
    --transcriptome ${ref} \
    --output-dir ${outdir}/${i} \
    --localcores 10 \
    --nosecondary

done

# 参考链接: https://www.10xgenomics.com/support/jp/software/cell-ranger/latest/analysis/running-pipelines/cr-gex-count
# --fastqs 交代测速数据路径（文件夹名）
# --sample 交代待比对样本名的前缀（因为该文件夹内可能有许多样本的测序数据）
# --transcriptome 交代参考基因组文件夹  /data/med-wangcq/01CondaEnv/00DataBase/02genome_annotation/CellRanger/scRNA_STseq/Download/
# --id 交代储存结果的文件夹，如果没有会自动创建
# --localcores 多线程
# --no-bam 不生成bam文件(视情况而定：如果进行RNA速率分析等，需要保留bam文件)
# --nosecondary 不进行后续分析
# --include-introns 默认True

##输出结果一般在 ${id} 的out文件夹