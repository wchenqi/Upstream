#!/bin/bash

#### 脚本说明
## conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/fastp_env
## 自动分辨单端双端数据, 分开处理

## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2

## 基本参数
export OUTDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/03Fastp/"
export INDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/00RawData/02_fastq/"
export SUFFIX=".fastq"
export THREAD=30
export JOBS=$((THREAD / 8))
export ForWhippet="True"

## 处理参数
mkdir -p $OUTDIR
echo "输出路径 $OUTDIR"

if [ "${ForWhippet}" = "True" ]; then
    export N_num=0
else
    export N_num=5
fi

# 获取样本列表：排除 _2.fastq，保留单端和所有 _1.fastq
find $INDIR -mindepth 1 -type f -name "*${SUFFIX}" | \
grep -v "_2${SUFFIX}$" | \
xargs -P ${JOBS} -n 1 bash -c '
    fq1="$1"
    echo "处理文件: ${fq1}"

    filename=$(basename "$fq1")
    
    # 如果文件后缀包含"_1", 作为双端数据处理
    if [[ ${filename} == *_1${SUFFIX} ]]; then 
        
        # 构建fq2路径
        fq2=${fq1/_1${SUFFIX}/_2${SUFFIX}}
        echo "配对样本: ${fq2}"

        # 提取样本名（去掉目录和后缀），例如 SRR17578336
        sp=$(basename "$fq1" "_1${SUFFIX}")
        echo "样本名: ${sp}"

        # 快速检查 R2 是否存在，不存在则跳过
        if [ ! -f "${fq2}" ]; then
            echo "警告: 找不到 ${fq2}, 跳过 ${sp}"
            exit 0
        fi

        # 建立子文件夹
        OUTDIR_PE="${OUTDIR}/pairedEnd/"
        echo "输出路径 ${OUTDIR_PE}"
        mkdir -p "${OUTDIR_PE}/report/"

        # 运行 fastp
        fastp \
            -w 8 \
            -i ${fq1} \
            -I ${fq2} \
            -o ${OUTDIR_PE}/${sp}_1${SUFFIX} \
            -O ${OUTDIR_PE}/${sp}_2${SUFFIX} \
            --trim_front1 7 \
            --trim_tail1 0 \
            --trim_front2 7 \
            --trim_tail2 0 \
            --overrepresentation_analysis \
            --qualified_quality_phred 30 \
            --unqualified_percent_limit 40 \
            --length_required 30 \
            --complexity_threshold 30 \
            --cut_window_size 4 \
            --cut_mean_quality 30 \
            --cut_front \
            --n_base_limit ${N_num} \
            --detect_adapter_for_pe \
            --trim_poly_g \
            --poly_g_min_len 10 \
            --trim_poly_x \
            --poly_x_min_len 10 \
            --html "${OUTDIR_PE}/report/${sp}.html"
    else
        # 单端数据处理
        OUTDIR_SE="${OUTDIR}/singleEnd/"
        echo "输出路径 ${OUTDIR_SE}"
        mkdir -p "${OUTDIR_SE}/report/"

        # 提取样本名
        sp=$(basename "$fq1" "${SUFFIX}")
        echo "样本名: ${sp}"

        # 运行 fastp
        fastp \
            -w 8 \
            -i ${fq1} \
            -o ${OUTDIR_SE}/${sp}${SUFFIX} \
            --trim_front1 7 \
            --trim_tail1 0 \
            --overrepresentation_analysis \
            --qualified_quality_phred 30 \
            --unqualified_percent_limit 40 \
            --length_required 30 \
            --complexity_threshold 30 \
            --cut_window_size 4 \
            --cut_mean_quality 30 \
            --cut_front \
            --n_base_limit ${N_num} \
            --adapter_sequence AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC \
            --trim_poly_g \
            --poly_g_min_len 10 \
            --trim_poly_x \
            --poly_x_min_len 10 \
            --html "${OUTDIR_SE}/report/${sp}.html"
    fi
' _