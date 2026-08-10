#bash脚本
# conda activate fastp_env
## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })
#echo ${SP[@]}

## 基本参数
OUTDIR="/scratch/2026-07-27/med-wangcq/SelfUse/Heart/01_GEO/GSE130036/"
INDIR="/scratch/2026-07-27/med-wangcq/SelfUse/Heart/01_GEO/GSE130036/02fastq/"
THREAD=30
JOBS=$((THREAD / 8))
ForWhippet="True"

## 处理参数
# 建立输出文件夹
OUTDIR1="${OUTDIR}/04Fastp/"
mkdir -p $OUTDIR1
cd $OUTDIR1
echo $OUTDIR1
if [ ForWhippet == "True" ]; then
    N_num=0
else
    N_num=5
fi
# 获取样本列表
find $INDIR -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | \
xargs -I {} -P ${JOBS} bash -c '
    i={};
    outdir1='${OUTDIR1}';
    indir='${INDIR}';
    N_num='${N_num}';
    echo $i
    mkdir -p "${outdir1}/${i}"
    fastp \
        -w 8 \
        -i ${indir}/${i}/${i}_1.fastq \
        -I ${indir}/${i}/${i}_2.fastq \
        -o ${outdir1}/${i}/${i}_R1.fastq \
        -O ${outdir1}/${i}/${i}_R2.fastq \
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
        --html "${outdir1}/${i}_fastp_report.html"
' _