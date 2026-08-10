#!/bin/bash

#### 脚本说明
# 运行环境: conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
# 应用: 针对scNanoRNA-seq测序结果。从原始数据开始，经历NanoQC - Scanner - Assigner - Curator - Reporter

## 基本参数
toolPath="/data/med-wangcq/01CondaEnv/01Demo_Script/00Git_Clone/scNanoGPS/"
outdir="/scratch/2026-07-27/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/"

### Step1 - NanoQC
inPath="/scratch/2026-07-27/med-wangcq/SelfUse/Heart/01_GEO/GSE288222/02Fastq/"
### Read length distribution
# python3 ${toolPath}/other_utils/read_length_profiler.py \
#         -i ${inPath} \
#         -d "${outdir}/03scNanoGPS" \
#         -f "${outdir}/03scNanoGPS/read_length.png" \
#         -o "${outdir}/03scNanoGPS/read_length.tsv.gz" \
#         --fig_w 12 \
#         --fig_h 7

python3 ${toolPath}/other_utils/prepare_read_qc.py -i "${inPath}" -d "${outdir}/03scNanoGPS" -l 100 --o1="${outdir}/03scNanoGPS/first_tail.fastq.gz" --o2="${outdir}/03scNanoGPS/last_tail.fastq.gz"

### Step2 - Scanner


### Step3 - Assigner


### Step4 - Curator


### Step5 - Reporter
