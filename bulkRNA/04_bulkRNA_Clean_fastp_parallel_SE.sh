#!/bin/bash

#### 脚本说明
## conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/fastp_env
## 用于单端数据修剪

## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })
#echo ${SP[@]}

## 基本参数
export OUTDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/03Fastp/"
export INDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/00RawData/02_fastq/02_PairEnd/"
export SUFFIX=".fastq"
export THREAD=30
export JOBS=$((THREAD / 8))
export ForWhippet="True"

## 处理参数
# 建立输出文件夹
mkdir -p $OUTDIR
echo "输出路径 $OUTDIR"

if [ "${ForWhippet}" = "True" ]; then
    export N_num=0
else
    export N_num=5
fi

# 获取样本列表
find $INDIR -mindepth 1 -type f -name "*${SUFFIX}" | \
grep -v "_1${SUFFIX}" |\
grep -v "_2${SUFFIX}" |\
xargs -P ${JOBS} -n 1 bash -c '
    fq1="$1"
    echo "处理文件: ${fq1}"

    # 提取文件名
    filename=$(basename "$fq1")

    # 提取样本名（去掉目录和后缀），例如 SRR123
    sp=$(basename "$fq1" "${SUFFIX}")

    # 建立子文件夹 'singleEnd'
    OUTDIR_SE="${OUTDIR}/singleEnd/"
    echo "输出路径 ${OUTDIR_SE}"
    if [ ! -d "${OUTDIR_SE}" ]; then
        mkdir -p ${OUTDIR_SE}/report
    fi

    # 提取样本名（去掉目录和后缀），例如 SRR123
    sp=$(basename "$fq1" "${SUFFIX}")

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
        --n_base_limit $N_num \
        --adapter_sequence AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC \
        --trim_poly_g \
        --poly_g_min_len 10 \
        --trim_poly_x \
        --poly_x_min_len 10 \
        --html "${OUTDIR_SE}/report/${sp}_fastp_report.html"
    fi
' _
