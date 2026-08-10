#!/bin/bash

### 脚本说明
#1) conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
#2) 使用说明: 用于过滤低质量剪接事件,接在STAR等比对工具检测Junction(STAR SJ.out.tab)之后,下游对接rMATS/MISO/SUPPA2等可变剪接或定量分析

### 一次运行所有

### 整体分析包含四步
# Prepare —— 整理输入文件
# Junction Analysis —— 比对剪接位点信息
# Junction Filtering —— 剪接位点统计学特征计算
# Bam Filtering —— 回滤bam文件

### full
# 1) 输入文件要求: 位点排序和建立过索引的bam文件; .fasta(.fa/.fa.gz)参考基因组文件
bamdir="/scratch/2026-06-01/med-wangcq/Others/AnJQ/AnalysisData/Sam68OECM_scFASTseq/02Result/Get_bam/main/CM/"
fafile="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/Genome_Annotation_Reference/00Download/GENCODE/GRCm38.primary_assembly.genome.fa"
outdir="/scratch/2026-06-01/med-wangcq/Others/AnJQ/AnalysisData/Sam68OECM_scFASTseq/02Result/"
jobs=1

export bamdir fafile outdir

## 提前建立索引文件
if [ ! -f "${fafile}.fai" ]; then
    echo "FAI index not found for: ${fafile}. Building index..."    # 不存在fai文件,使用samtools自己建立
    samtools faidx "${fafile}"
    if [ $? -eq 0 ]; then
        echo "✅  FAI index built successfully: ${fafile}.fai"
    else
        echo "❌  Failed to build FAI index for: ${fafile}"
        exit 1
    fi
else
    echo "✅  FAI index exists: ${fafile}.fai"      # 存在fai文件
fi
## 并行处理
find $bamdir -mindepth 1 -maxdepth 1 -type f -name "*.bam" | xargs -I {} -P ${jobs} bash -c '
    i={}
    echo ${i}
    echo "Processing: $i"
    sp=$(basename "$i" .bam)
    echo "Sample name: $sp"
    outdir1="${outdir}/Portcullis/${sp}"
    echo "${outdir1}"
    mkdir -p "${outdir1}"

    portcullis full \
        -t 8 \
        -o "${outdir1}" \
        --orientation FR \
        --strandedness UNKNOWN \
        --canonical C,S \
        --min_cov 5 \
        --copy \
        --force \
        --save_bad \
        --bam_filter \
        "${fafile}" \
        "${i}"
    '

# Portcullis 完成后，删除它复制的副本（保留结果）
# rm -rf "${outdir1}/1-prep/portcullis.genome.fa"
# rm -f  "${outdir1}/1-prep/portcullis.genome.fa.fai"
