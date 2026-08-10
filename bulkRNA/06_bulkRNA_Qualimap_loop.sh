#!/bin/bash

### 脚本说明
#1) conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
#2) 工具接在比对后, 包含多个模块, 主要用于检测比对后的数据特征, 这里调用:
#       rnaseq模块检查read在基因组功能区域中分布(可以查看正反链占比)
#       multi-bamqc检查测序数据比对质量

## 注意: 查看覆盖度,比对率,链特异性[RNAseq-额外junction分析; ChIP-seq 指纹图和富集区域]

export JAVA_OPTS="-Djava.awt.headless=true"   # 设置 headless 运行模式,跳过x11显示器存入内存
## 参考基因组数据：
# /data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/Genome_Annotation_Reference/00Download/

## 基本参数
OUTDIR="/scratch/2026-06-29/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_TAC_Day3_4W_RNAseq/04Qualimap/"
INDIR="/scratch/2026-06-29/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_TAC_Day3_4W_RNAseq/03STAR/"
GTF="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/Genome_Annotation_Reference/00Download/Ensembl/Mus_musculus.GRCm38.102.gtf"
bamqc_file="/data/med-wangcq/Chenqi_W/03Splicing/02Sam68_KO/Sam68KOWT_TAC_Day3_4W_RNAseq/01DataInfo/Bamfiles/Qualimap_bamfile.xls"
JOBS=6
rm_pattern="Aligned.sortedByCoord.out.bam"

bamfiles=$(find "${INDIR}" -type f -name "*.bam")
echo $bamfiles

## 循环处理
for path in $bamfiles
do
    echo $path
    sp=$(basename ${path} ${rm_pattern})
    echo ${sp}
    ## 运行
    qualimap rnaseq \
            -bam ${path} \
            -gtf ${GTF} \
            -pe \
            -outdir ${OUTDIR} \
            -outfile ${sp}"_report_rnaseq.pdf" \
            -outformat PDF \
            -a proportional \
            --java-mem-size=16G

    ## 单样本循环
    # qualimap bamqc \
    #     -bam ${path} \
    #     -gff ${GTF} \
    #     -outdir ${OUTDIR} \
    #     -outfile ${sp}"_report_bamqc.pdf" \
    #     -outformat PDF \
    #     --java-mem-size=16G \
    #     --paint-chromosome-limits
done

# 不指定链方向-p strand-specific-reverse, 可以输出正反链的占比


# 用 multi-bamqc 汇总多个样本的质控结果，生成(比对率，覆盖度，重复率)比对报告
qualimap multi-bamqc \
        --data ${bamqc_file} \
        -outdir ${OUTDIR} \
        -outfile "Multi-bamqc_report.pdf" \
        -outformat PDF \
        --run-bamqc \
        -gff ${GTF} \
        -nr 1000 \
        -hm 50 \
        -nw 400 \
        --java-mem-size=16G \
        --paint-chromosome-limits

# 参数解释
# --data 两列到三列的tab分隔表格文件; 第一列样本名, 第二列bam文件路径或者是bamqc输出路径; 第三列分组信息,画热图的时候标记样本分组
# -hm 限制最大样本量