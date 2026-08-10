#bash脚本
# conda activate fastp_env
## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })
#echo ${SP[@]}
outdir1="/scratch/2026-05-11/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_TAC_Day3_4W_RNAseq/02Clean_fastp/"
indir="/scratch/2026-05-11/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_TAC_Day3_4W_RNAseq/00RawData/"
SP=($(ls -l $indir | grep "^d" | awk '{print $NF}'))
echo $SP

mkdir -p $outdir1
cd $outdir1
echo $outdir1

## 循环运行
# for sample_name in "${SP[@]}"        # Sham_4W_CTR4
for sample_name in Sham_4W_KO1 Sham_4W_KO3 TAC_4W_CTR2 TAC_4W_CTR5 TAC_4W_KO3 TAC_4W_KO6 TAC_D3_CTR3 TAC_D3_KO1 TAC_D3_KO4 Sham_4W_KO4 TAC_4W_CTR3 TAC_4W_KO1 TAC_4W_KO4 TAC_D3_CTR1 TAC_D3_CTR4 TAC_D3_KO2 TAC_D3_KO5 Sham_4W_KO2 TAC_4W_CTR1 TAC_4W_CTR4 TAC_4W_KO2 TAC_4W_KO5 TAC_D3_CTR2 TAC_D3_CTR5 TAC_D3_KO3
do
    echo $sample_name       
    mkdir -p ${outdir1}/${sample_name}
    fastp \
        -w 16 \
        -i ${indir}/${sample_name}/${sample_name}_1.fq.gz \
        -I ${indir}/${sample_name}/${sample_name}_2.fq.gz \
        -o ${outdir1}/${sample_name}/${sample_name}_R1.fastq \
        -O ${outdir1}/${sample_name}/${sample_name}_R2.fastq \
        --detect_adapter_for_pe \
        --trim_front1 15 \
        --trim_tail1 0 \
        --trim_front2 15 \
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
        --trim_poly_g \
        --poly_g_min_len 10 \
        --trim_poly_x \
        --poly_x_min_len 10 \
        --html "${outdir1}/${sample_name}_fastp_report.html"
done
