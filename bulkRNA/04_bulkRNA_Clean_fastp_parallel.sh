#!/bin/bash

#### 脚本说明
# conda activate fastp_env
## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })
#echo ${SP[@]}

## 基本参数
OUTDIR="/scratch/2026-08-03/med-wangcq/SelfUse/Heart/01_GEO/GSE95143/01Result/01RNAseq/02Fastp/"
INDIR="/scratch/2026-08-03/med-wangcq/SelfUse/Heart/01_GEO/GSE95143/00Data/RNAseq/02Fastq/"
THREAD=30
JOBS=$((THREAD / 8))
ForWhippet="True"

## 处理参数
# 建立输出文件夹
mkdir -p $OUTDIR
cd $OUTDIR
echo "输出路径 $OUTDIR"

if [ "${ForWhippet}" = "True" ]; then
    N_num=0
else
    N_num=5
fi

# 导出变量供 xargs 内的 bash 使用
export OUTDIR INDIR N_num

# 获取样本列表
find $INDIR -mindepth 1 -maxdepth 1 -type f -name "*_1.fastq.gz" | \
xargs -I {} -P ${JOBS} bash -c '
    # 这里是压缩文件_1.fastq.gz
    fq1="$1";
    echo "处理文件: ${fq1}"
    
    # 提取样本名（去掉目录和后缀），例如 SRR123
    sp=$(basename "$fq1" "_1.fastq.gz")
    # sp=${fq1%_1.fastq.gz}
    # echo ${sp}

    # fq2路径
    fq2=${fq1/_1.fastq.gz/_2.fastq.gz}
    echo "配对样本: ${fq2}"

    # 快速检查 R2 是否存在，不存在则跳过
    if [ ! -f "${fq2}" ]; then
        echo "警告: 找不到 ${fq2}, 跳过 ${sp}"
        continue
    fi

    # 外部变量传参
    outdir='${OUTDIR}';
    indir='${INDIR}';
    N_num='${N_num}';

    # 运行 fastp
    fastp \
        -w 8 \
        -i ${fq1} \
        -I ${fq2} \
        -o ${outdir}/${sp}_1.fastq.gz \
        -O ${outdir}/${sp}_2.fastq.gz \
        --trim_front1 6 \
        --trim_tail1 0 \
        --trim_front2 6 \
        --trim_tail2 0 \
        --dedup \
        --overrepresentation_analysis \
        --qualified_quality_phred 28 \
        --unqualified_percent_limit 40 \
        --length_required 30 \
        --complexity_threshold 30 \
        --cut_window_size 4 \
        --cut_mean_quality 30 \
        --cut_front \
        --n_base_limit $N_num \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --poly_g_min_len 10 \
        --trim_poly_x \
        --poly_x_min_len 10 \
        --html "${outdir}/${sp}_fastp_report.html"
' _ {}
