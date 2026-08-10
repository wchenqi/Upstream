#!/usr/bash

#### 本脚本是为了实现基因组比对
# https://www.jianshu.com/p/e34ab865f055
# https://zhuanlan.zhihu.com/p/581922508
# STAR安装： https://zhuanlan.zhihu.com/p/362727395    https://github.com/alexdobin/STAR
# 参考基因组：https://zhuanlan.zhihu.com/p/383397412

module load java/10.0.2
source /data/med-wangcq/01CondaEnv/00DataBase/00Tools/STAR-2.7.11a/env.sh

#### 设置参数
OUTDIR="/scratch/2026-05-18/med-wangcq/Others/AnJQ/AnalysisData/Sam68OECM_scFASTseq/02Result/"
INDIR="/scratch/2026-05-18/med-wangcq/Others/AnJQ/AnalysisData/Sam68OECM_scFASTseq/02Result/Get_bam/"
GENOME_DIR="/data/med-wangcq/01CondaEnv/00DataBase/02genome_annotation/STAR/Mus_musculus/GRCm38_mm10_Ensembl/"
THREADS=40
JOBS=$(( THREADS / 8 ))

#### 处理参数
sp=$(find "$INDIR" -mindepth 1 -maxdepth 2 -type d -printf "%f\n")
echo $sp
OUTDIR1="${OUTDIR}/03STAR_tmp"
mkdir -p $OUTDIR1
cd $OUTDIR1

# 输出记录软件版本和参考基因组版本的文件
RECORD="${OUTDIR1}/COfile.txt"
STAR_VERSION=$(STAR --version | head -n 1)
echo $STAR_VERSION
echo -e "@CO\tSTAR version=${STAR_VERSION}\n@CO\tGENOME PATH=${GENOME_DIR}" > $RECORD

#### STARsolo比对：
printf "%s\n" $sp | xargs -I {} -P $JOBS bash -c '
     i={};
     indir='"$INDIR"';
     outdir1='"$OUTDIR1"';
     genome_dir='"$GENOME_DIR"';
     record='$RECORD';
     
     echo "Processing $i";
     fq1=$(find "$indir/$i" -maxdepth 1 -type f -name "*_R1.fastq");
     fq2=$(find "$indir/$i" -maxdepth 1 -type f -name "*_R2.fastq");
     
     [ -f "$fq1" ] && [ -f "$fq2" ] || exit 1;
     echo "Processing $i";

     ## 如果是gz文件, 使用 --readFilesCommand zcat 参数进行读取
     STAR --runThreadN 8 \
          --genomeDir "$genome_dir" \
          --readFilesIn "$fq1" "$fq2" \
          --outFileNamePrefix "$outdir1/$i" \
          --outSAMtype BAM SortedByCoordinate \
          --quantMode GeneCounts \
          --twopassMode Basic \
          --alignEndsType Local \
          --alignSJDBoverhangMin 8 \
          --alignSJoverhangMin 8 \
          --alignIntronMin 20 \
          --alignIntronMax 1000000 \
          --alignMatesGapMax 1000000 \
          --outSAMunmapped Within \
          --outSAMattributes NH HI AS NM MD XS \
          --outFilterMultimapNmax 20 \
          --outSAMmultNmax -1 \
          --outFilterMismatchNmax 3 \
          --outSAMheaderCommentFile "$record"
' _

## 建立索引文件,暂时不确定输出文件命名格式
find "$OUTDIR1" -maxdepth 1 -type f -name "*Aligned.sortedByCoord.out.bam" | \
xargs -I {} -P $JOBS bash -c '
     i={};
     echo "${i}";
     [ ! -f "${i}.bai" ] && samtools index -@ 4 "${i}"
' _

# for i in $sp
# do
#      echo $i
#      ## 输出测序深度文件：
#      inBAM=${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam
#      samtools index ${inBAM} ${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam.bai
# done
