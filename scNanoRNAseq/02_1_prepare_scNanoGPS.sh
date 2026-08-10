#!/bin/bash

#### 脚本说明
# 1) 运行环境: mamba activate r452
# 2) 应用: scNanoGPS 上游准备文件
source "/work/med-hancs/miniforge3/etc/profile.d/conda.sh"

## minimap2 - 建立参考基因索引文件
conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
# 基本参数
ref="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/Genome_Annotation_Reference/00Download/Ensembl/"
outdir="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/minimap2/"
minimap2 -x map-ont -d ${outdir}/GRCh38.mmi ${ref}/GRCh38/Homo_sapiens.GRCh38.dna.toplevel.fa.gz
minimap2 -x map-ont -d ${outdir}/GRCm38.mmi ${ref}/GRCm38/Mus_musculus.GRCm38.dna.toplevel.fa.gz
minimap2 -x map-ont -d ${outdir}/GRCm39.mmi ${ref}/GRCm39/Mus_musculus.GRCm39.dna.toplevel.fa.gz

### ANNOVAR - 变异位点注释
conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/GWAS
## 输出路径
outdir="/data/med-wangcq/01CondaEnv/00DataBase/00Tools/annovar/humandb/"
annotate_variation.pl -buildver hg38 -downdb -webfrom annovar refGene ${outdir}/hg38/
annotate_variation.pl -buildver hg38 -downdb cytoBand ${outdir}/hg38/
annotate_variation.pl -buildver hg38 -downdb -webfrom annovar gnomad30_genome ${outdir}/hg38/
annotate_variation.pl -buildver hg38 -downdb -webfrom annovar avsnp150 ${outdir}/hg38/
annotate_variation.pl -buildver hg38 -downdb -webfrom annovar dbnsfp42c ${outdir}/hg38/

annotate_variation.pl -buildver hg19 -downdb -webfrom annovar refGene ${outdir}/hg19/
annotate_variation.pl -buildver hg19 -downdb cytoBand ${outdir}/hg19/
annotate_variation.pl -buildver hg19 -downdb -webfrom annovar gnomad30_genome ${outdir}/hg19/
annotate_variation.pl -buildver hg19 -downdb -webfrom annovar avsnp150 ${outdir}/hg19/
annotate_variation.pl -buildver hg19 -downdb -webfrom annovar dbnsfp42c ${outdir}/hg19/
