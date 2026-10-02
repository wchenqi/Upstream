#bash脚本
# conda activate fastp_env
## https://github.com/OpenGene/fastp
## https://www.jianshu.com/p/bfb573fcb3ec

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })
#echo ${SP[@]}
outdir1="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/03Fastp/pairedEnd_test/"
indir="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/00RawData/02_fastq/02_PairEnd/"
SP=($(ls -l $indir | grep "^d" | awk '{print $NF}'))
echo $SP

mkdir -p $outdir1
cd $outdir1
echo $outdir1

## 循环运行
# for sample_name in "${SP[@]}"        # Sham_4W_CTR4
for sample_name in SRR17578336 SRR17578338 SRR17578340 SRR17578342 SRR17578344 SRR17578346 SRR17578337 SRR17578339 SRR17578341 SRR17578343 SRR17578345 SRR17578347
do
    echo $sample_name       
    mkdir -p "${outdir1}/${sample_name}"
    fastp \
        -w 16 \
        -i ${indir}/${sample_name}/${sample_name}_1.fastq \
        -I ${indir}/${sample_name}/${sample_name}_2.fastq \
        -o ${outdir1}/${sample_name}/${sample_name}_1.fastq \
        -O ${outdir1}/${sample_name}/${sample_name}_2.fastq \
        --detect_adapter_for_pe \
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
        --trim_poly_g \
        --poly_g_min_len 10 \
        --trim_poly_x \
        --poly_x_min_len 10 \
        --html "${outdir1}/${sample_name}_report.html"
done
