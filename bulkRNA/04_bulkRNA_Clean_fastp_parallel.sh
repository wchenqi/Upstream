#!/bin/bash

#### 脚本说明
## conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/fastp_env
## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })
#echo ${SP[@]}

## 基本参数
OUTDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/03Fastp/"
INDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/00RawData/02_fastq/"
suffix=".fastq"
THREAD=30
JOBS=$((THREAD / 8))
ForWhippet="True"

## 处理参数
# 建立输出文件夹
mkdir -p $OUTDIR
echo "输出路径 $OUTDIR"

if [ "${ForWhippet}" = "True" ]; then
    N_num=0
else
    N_num=5
fi

# 导出变量供 xargs 内的 bash 使用
export OUTDIR INDIR N_num

# 获取样本列表
find $INDIR -mindepth 1 -type f -name "*${suffix}" | \
grep -v "_2${suffix}" | \
xargs -P ${JOBS} -n 1 bash -c '
    # 这里是压缩文件${suffix}, 包含单端双端测序结果
    fq1="$1"
    echo "处理文件: ${fq1}"
    
    # 外部变量传参
    outdir='${OUTDIR}';
    indir='${INDIR}';
    N_num='${N_num}';

    # 提取文件名
    filename=$(basename "$fq1")
    
    # 如果文件后缀包含"_1", 作为双端数据处理
    if [[ ${filename} == *_1${suffix} ]]; then 
        
        # 构建fq2路径
        fq2=${fq1/_1${suffix}/_2${suffix}}
        echo "配对样本: ${fq2}"

        # 提取样本名（去掉目录和后缀），例如 SRR123
        sp=$(basename "$fq1" "_1${suffix}")

        # 快速检查 R2 是否存在，不存在则跳过
        if [ ! -f "${fq2}" ]; then
            echo "警告: 找不到 ${fq2}, 跳过 ${sp}"
            continue
        else
            # 如果fq2文件存在, 建立子文件夹 'pairedEnd'
            outdir_PE="${outdir}/pairedEnd/"
            echo "输出路径 ${outdir_PE}"
            if [ ! -d "${outdir_PE}" ]; then
                mkdir -p ${outdir_PE}
            fi
        fi

        # 运行 fastp
        fastp \
            -w 8 \
            -i ${fq1} \
            -I ${fq2} \
            -o ${outdir_PE}/${sp}_1${suffix} \
            -O ${outdir_PE}/${sp}_2${suffix} \
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
            --n_base_limit $N_num \
            --detect_adapter_for_pe \
            --trim_poly_g \
            --poly_g_min_len 10 \
            --trim_poly_x \
            --poly_x_min_len 10 \
            --html "${outdir_PE}/${sp}_fastp_report.html"
    else
        # 如果fq2文件存在, 建立子文件夹 'singleEnd'
        outdir_SE="${outdir}/singleEnd/"
        echo "输出路径 ${outdir_SE}"
        if [ ! -d "${outdir_SE}" ]; then
            mkdir -p ${outdir_SE}
        fi

        # 提取样本名（去掉目录和后缀），例如 SRR123
        sp=$(basename "$fq1" "${suffix}")

        # 运行 fastp
        fastp \
            -w 8 \
            -i ${fq1} \
            -o ${outdir_SE}/${sp}${suffix} \
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
            --html "${outdir_SE}/${sp}_fastp_report.html"
    fi
' _
