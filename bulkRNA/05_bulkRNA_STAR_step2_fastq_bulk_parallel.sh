#!/usr/bash

#### 本脚本是为了实现基因组比对
# https://www.jianshu.com/p/e34ab865f055
# https://zhuanlan.zhihu.com/p/581922508
# STAR安装： https://zhuanlan.zhihu.com/p/362727395    https://github.com/alexdobin/STAR
# 参考基因组：https://zhuanlan.zhihu.com/p/383397412

module load java/10.0.2
source /data/med-wangcq/01CondaEnv/00DataBase/00Tools/STAR-2.7.11a/env.sh

#### 设置参数
OUTDIR="/scratch/2026-05-11/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_AngII_RNAseq/"
INDIR="/scratch/2026-05-11/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_AngII_RNAseq/02Clean_fastp/"
GENOME_DIR="/data/med-wangcq/01CondaEnv/00DataBase/02genome_annotation/STAR/Mus_musculus/GRCm38_mm10_Ensembl/"
# /data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/STAR/Homo_sapiens/GRCh38_hg38_NCBI/
THREADS=40
JOBS=$(( THREADS / 8 ))

#### 处理参数
sp=$(find "$INDIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
echo $sp
OUTDIR1="${OUTDIR}/03STAR"
mkdir -p $OUTDIR1
cd $OUTDIR1

# 输出记录软件版本和参考基因组版本的文件
RECORD="${OUTDIR1}/COfile.txt"
STAR_VERSION=$(STAR --version | head -n 1)
echo $STAR_VERSION
echo -e "@CO\tSTAR version=${STAR_VERSION}\n@CO\tGENOME PATH=${GENOME_DIR}" > "$RECORD"

# 导出变量供 xargs 使用
export INDIR OUTDIR1 GENOME_DIR RECORD

#### STARsolo比对：
printf "%s\n" ${sp} | xargs -I {} -P "$JOBS" bash -c '
     i={}
     echo "Processing $i"

     # indir='"$INDIR"'
     # outdir1='"$OUTDIR1"'
     # genome_dir='"$GENOME_DIR"'
     # record='$RECORD'

     fq1=$(find "$INDIR/$i" -maxdepth 1 -type f -name "*_R1.fastq" | head -1)
     fq2=$(find "$INDIR/$i" -maxdepth 1 -type f -name "*_R2.fastq" | head -1)

     echo "R1: ${fq1}"
     echo "R2: ${fq2}"
     
     [ -f "$fq1" ] && [ -f "$fq2" ] || exit 1

     STAR --runThreadN 5 \
          --genomeDir "$GENOME_DIR" \
          --readFilesIn "$fq1" "$fq2" \
          --outFileNamePrefix "${OUTDIR1}/${i}" \
          --outSAMtype BAM SortedByCoordinate \
          --quantMode GeneCounts \
          --twopassMode Basic \
          --alignEndsType Local \
          --alignSJDBoverhangMin 8 \
          --alignSJoverhangMin 8 \
          --alignIntronMin 20 \
          --alignIntronMax 1000000 \
          --alignMatesGapMax 1000000 \
          --outSAMstrandField intronMotif \
          --outSAMunmapped Within \
          --outSAMattributes NH HI AS NM MD XS \
          --outFilterMultimapNmax 20 \
          --outSAMmultNmax -1 \
          --outFilterMismatchNmax 3 \
          --outSAMheaderCommentFile "$RECORD" \
          2>&1 | tee "${OUTDIR1}/${i}_STAR.log"

     # ===== 立即验证 + 索引（合并在一起）=====
     BAM="${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam"
     
     if [ -f "$BAM" ]; then
          echo "BAM generated: $BAM"
          
          if samtools quickcheck "$BAM" 2>/dev/null; then
               echo "BAM OK, indexing..."
               samtools index -@ 4 "$BAM" && echo "Index done: ${BAM}.bai" || echo "Index failed"
          else
               echo "BAM CORRUPTED, removing: $BAM"
               rm -f "$BAM"
               echo "Please rerun $i manually"
          fi
     else
          echo "FAILED: BAM not found for $i"
     fi
     
     echo "=== Finished: $i ==="
' _

echo "All samples processed. Check logs in ${OUTDIR1}/*_STAR.log"

# for i in $sp
# do
#      echo $i
#      ## 输出测序深度文件：
#      inBAM=${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam
#      samtools index ${inBAM} ${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam.bai
# done
