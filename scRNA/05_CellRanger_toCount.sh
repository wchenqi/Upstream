#!/bin/bash

### 脚本说明
## 工具在base环境

export ref="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/CellRanger/scRNA_STseq/Download/refdata-gex-mm10-2020-A/"    # 参考注释文件路径, 见：/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/CellRanger/scRNA_STseq/Download/
export indir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/03_MergeFq/"  # 输入包含fastq文件的总路径 indir/sampleid/fastq_file
export outdir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/04_CellRanger/" # 输出文件路径
JOBS=5

## 建立输出文件夹
if [ ! -d ${outdir} ]; then
mkdir -p ${outdir}
fi

## 跳转运行路径
cd ${outdir}

## 获取路径下样本名
find $indir -mindepth 1 -maxdepth 1 -type d | xargs -I {} -P $JOBS bash -c '
    i="$1"
    echo "${i}"
    sp=$(basename "$i")
    echo ${sp}


    ## 执行运行
    cellranger count \
        --id ${sp} \
        --fastqs ${indir}/${sp} \
        --sample ${sp} \
        --expect-cells=10000 \
        --transcriptome ${ref} \
        --output-dir ${outdir}/${sp} \
        --localcores 6 \
        --nosecondary

' _ {}

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