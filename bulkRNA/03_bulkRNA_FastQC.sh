#!/bin/bash

### 脚本运行说明:
## /data/med-hancs/apps/anaconda3/2022.10/envs/BasicR
## /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
## 本脚本实现单样本质控和汇总质控结果

## https://zhuanlan.zhihu.com/p/641393108
## 污染文件存在"/work/med-wangcq/00DataBase/02genome_annotation/Contaminant/contaminant_list.txt"
module load java/10.0.2

source "/work/med-hancs/miniforge3/etc/profile.d/conda.sh"
conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/BasicR

outdir="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/02FastQC/"
indir="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/00RawData/02_fastq/"
suffix=".fastq"

mkdir -p $outdir
cd $outdir
echo "Output directory: $outdir"

## 双端数据处理
find ${indir} -type f -name "*${suffix}" | \
grep -v "_2${suffix}" | \
while read fq1; do
    # 避免循环继承
    fq2=""
    
    if [[ "$fq1" == *_1"${suffix}" ]]; then
        # 自动推导出对应的 R2 文件名
        fq2=${fq1/_1"${suffix}"/_2"${suffix}"}
    fi        
    # 如果 $fq2 变量已定义 且 R2 文件存在，则运行
    if [ -n "$fq2" ] && [ -f "$fq2" ]; then
    # if [ -n "$fq2" -a -f "$fq2" ]; then   ## 这里使用 -a 合并条件(-o 或者)
        echo "双端测序：$fq1 和 $fq2 均存在"
        sample=$(basename "$fq1" _1"${suffix}")
        echo "找到 ${fq2}, 正在处理双端测序数据: $sample"
        fastqc -o ${outdir} --extract --format fastq --quiet "$fq1" "$fq2"
    else
        echo "警告：找不到 ${fq2}, 作为单端数据处理"
        fastqc -o ${outdir} --extract --format fastq --quiet "$fq1"
    fi
done

# 主要是包括前面的各种选项和最后面的可以加入N个文件
# -o --outdir FastQC生成的报告文件的储存路径，生成的报告的文件名是根据输入来定的,注意是不能自动新建目录的。输出的结果是.zip文件，默认自动解压缩，命令里加上--noextract则不解压缩
# --extract 生成的报告默认会打包成1个压缩文件，使用这个参数是让程序不打包
# -t --threads 选择程序运行的线程数，每个线程会占用250MB内存，越多越快咯
# -c --contaminants 污染物选项，输入的是一个文件，格式是Name [Tab] Sequence，里面是可能的污染序列，如果有这个选项，FastQC会在计算时候评估污染的情况，并在统计的时候进行分析，一般用不到
# -a --adapters 也是输入一个文件，文件的格式Name [Tab] Sequence，储存的是测序的adpater序列信息，如果不输入，目前版本的FastQC就按照通用引物来评估序列时候有adapter的残留
# -q --quiet 安静运行模式，一般不选这个选项的时候，程序会实时报告运行的状况。
# -f --format 测序文件类型：bam,sam,bam_mapped,sam_mapped,fastq

# ========== MultiQC ==========
conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy

mkdir -p ${outdir}/00multiqc_report
multiqc $outdir -o ${outdir}/00multiqc_report
