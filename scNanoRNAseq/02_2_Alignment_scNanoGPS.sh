#!/bin/bash

#### 脚本说明
# 运行环境: conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
# 应用: 针对scNanoRNA-seq测序结果。从原始数据开始，经历NanoQC - Scanner - Assigner - Curator - Reporter

## 基本参数
toolPath="/data/med-wangcq/01CondaEnv/01Demo_Script/00Git_Clone/scNanoGPS/"
outdir="/scratch/2026-08-10/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/"

### Step1 - NanoQC
inPath="/scratch/2026-08-10/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/02Fastq/"
### Read length distribution
# python3 ${toolPath}/other_utils/read_length_profiler.py \
#         -i ${inPath} \
#         -d "${outdir}/03scNanoGPS" \
#         -f "${outdir}/03scNanoGPS/read_length.png" \
#         -o "${outdir}/03scNanoGPS/read_length.tsv.gz" \
#         --fig_w 12 \
#         --fig_h 7

### Step2 - Scanner (这个步骤跑得很慢，需要多设置线程数)
# python3 ${toolPath}/scanner.py \
#         -i ${inPath} \
#         -t 35 \
#         -o "${outdir}/03scNanoGPS/processed.fastq.gz" \
#         -d "${outdir}/03scNanoGPS" \
#         -b "${outdir}/03scNanoGPS/barcode_list.tsv.gz" \
#         --log "${outdir}/03scNanoGPS/scanner.log.txt" \
#         --a5 "AAGCAGTGGTATCAACGCAGAGTACAT" \
#         --a3 "CTACACGACGCTCTTCCGATCT" \
#         --pT "TTTTTTTTTTTT" \
#         --lCB 16 \
#         --lUMI 12

### Step3 - Assigner
# python3 ${toolPath}/assigner.py -t 35 \
#         -i ${outdir}/03scNanoGPS/barcode_list.tsv.gz \
#         -o ${outdir}/03scNanoGPS/CB_counting.tsv.gz \
#         -d ${outdir}/03scNanoGPS \
#         --tmp_dir ${outdir}/03scNanoGPS/tmp \
#         --log ${outdir}/03scNanoGPS/assigner.log.txt \
#         --lCB 16 \
#         --CB_no_ext 0.1 \
#         --CB_log10_dist_o ${outdir}/03scNanoGPS/CB_log10_dist.png \
#         --CB_mrg_thr 1 \
#         --CB_mrg_dist ${outdir}/03scNanoGPS/CB_merged_dist.tsv.gz \
#         --CB_mrg_o ${outdir}/03scNanoGPS/CB_merged_list.tsv.gz \
#         --min_cellno 1 \
#         --smooth_res 0.001 \
#         --min_read_no 500

### Step4 - Curator
Genome_Path="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/"
python3 ${toolPath}/curator.py -t 35 \
        --ref_genome "${Genome_Path}/Genome_Annotation_Reference/00Download/Ensembl/GRCh38/Homo_sapiens.GRCh38.dna.toplevel.fa.gz" \
        --idx_genome "${Genome_Path}/minimap2/GRCh38.mmi" \
        --fq_name "${outdir}/03scNanoGPS/processed.fastq.gz" \
        -b "${outdir}/03scNanoGPS/barcode_list.tsv.gz" \
        -d "${outdir}/03scNanoGPS" \
        --CB_count "${outdir}/03scNanoGPS/CB_counting.tsv.gz" \
        --CB_list "${outdir}/03scNanoGPS/CB_merged_list.tsv.gz" \
        --tmp_dir "${outdir}/03scNanoGPS/tmp" \
        --log "${outdir}/03scNanoGPS/assigner.log.txt" \
        --umi_ld 1 \
        --keep_meta 1 \
        --softclipping_thr 0.8 \
        --max_umi_duplicates 500

### Step5 - Reporter
