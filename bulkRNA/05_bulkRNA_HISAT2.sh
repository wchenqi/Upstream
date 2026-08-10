#!?bin/bash

#### 脚本说明
#1) 运行环境: mamba activate r452
#2) 应用: 对测序数据进行链特异性比对

# 定义索引、输入、输出路径
INDEX="/path/to/your/hisat2_index/genome"
INPUT_DIR="/path/to/cleaned_fastq"
OUTPUT_DIR="/path/to/output"

# 样本ID列表，与你的文件前缀对应
for SAMPLE in HCM269 HCM273 HCM282 HCM395 HCM405 HCM420 HCM493; do
    echo "Processing ${SAMPLE}"

    hisat2 -p 5 \
           -x ${INDEX} \
           -1 ${INPUT_DIR}/${SAMPLE}_1_val_1.fq.gz \
           -2 ${INPUT_DIR}/${SAMPLE}_2_val_2.fq.gz \
           --rna-strandness RF \
           -S ${OUTPUT_DIR}/${SAMPLE}.sam \
           2> ${OUTPUT_DIR}/${SAMPLE}.log

    # 将sam文件转换为排序后的bam文件
    samtools sort -@ 5 -o ${OUTPUT_DIR}/${SAMPLE}.sorted.bam ${OUTPUT_DIR}/${SAMPLE}.sam
    # 可选：建立索引以便快速查看
    samtools index ${OUTPUT_DIR}/${SAMPLE}.sorted.bam
done