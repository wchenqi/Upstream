#!/usr/bash

#### 本脚本是为了实现基因组比对
# https://www.jianshu.com/p/e34ab865f055
# https://zhuanlan.zhihu.com/p/581922508
# STAR安装： https://zhuanlan.zhihu.com/p/362727395    https://github.com/alexdobin/STAR
# 参考基因组：https://zhuanlan.zhihu.com/p/383397412
### /work/med-wangcq/00DataBase/02genome_annotation/old/
## STAR需要的barcode whitelist：
#1) 10X：https://github.com/wenweixiong/MARVEL?tab=readme-ov-file
#2) scFAST-seq："/work/med-wangcq/00DataBase/00Tools/seeksoultools/lib/python3.10/site-packages/seeksoultools/utils/barcode/P3CBGB/P3CB.barcode.txt"

module load java/10.0.2
source /data/med-wangcq/01CondaEnv/00DataBase/00Tools/STAR-2.7.11a/env.sh

#### 设置参数
OUTDIR="/scratch/2026-05-11/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_AngII_RNAseq/"
indir="/scratch/2026-05-11/med-wangcq/Others/AnJQ/AnalysisData/Sam68KOWT_AngII_RNAseq/02Clean_fastp/"
GENOME_DIR="/data/med-wangcq/01CondaEnv/00DataBase/02genome_annotation/STAR/Mus_musculus/GRCm38_mm10_Ensembl/"
THREADS=40
# JOBS=$(( THREADS / 8 ))

#### 处理参数
sp=$(ls -l $indir | grep "^d" | awk '{print $NF}')
echo $sp
OUTDIR1="${OUTDIR}/03STAR"
mkdir -p $OUTDIR1


# 输出记录软件版本和参考基因组版本的文件
record="${OUTDIR1}/COfile.txt"
STAR_VERSION=$(STAR --version | head -n 1)
echo $STAR_VERSION
echo -e "@CO\tSTAR version=${STAR_VERSION}\n@CO\tGENOME PATH=${GENOME_DIR}" > $record
#### STARsolo比对：
for i in $sp
do
     echo $i
     # fq1=`ls $indir"/"$i | grep "_1.fastq$"`
     # fq2=`ls $indir"/"$i | grep "_2.fastq$"`
     # fq1_full=$indir"/"$i"/"$fq1
     # fq2_full=$indir"/"$i"/"$fq2
     fq1_full=$(find "$indir/$i" -maxdepth 2 -type f -name "${i}_R1.fastq")
     fq2_full=$(find "$indir/$i" -maxdepth 2 -type f -name "${i}_R2.fastq")
     echo $fq1_full
     echo $fq2_full
     
     # STAR比对命令
     ## 如果是gz文件, 使用 --readFilesCommand zcat 参数进行读取
     STAR --runThreadN 8 \
          --genomeDir $GENOME_DIR \
          --readFilesIn $fq1_full \
                        $fq2_full \
          --outFileNamePrefix "$OUTDIR1/$i" \
          --outSAMtype BAM SortedByCoordinate \
          --quantMode GeneCounts \
          --twopassMode Basic \
          --alignEndsType Local \
          --alignSJDBoverhangMin 8 \
          --alignSJoverhangMin 22 \
          --alignIntronMin 20 \
          --alignIntronMax 1000000 \
          --alignMatesGapMax 1000000 \
          --outSAMunmapped Within \
          --outSAMattributes NH HI AS NM MD XS \
          --outFilterMultimapNmax 20 \
          --outSAMmultNmax -1 \
          --outFilterMismatchNmax 3 \
          --outSAMheaderCommentFile $record
     echo "样本"$i"处理完成"

     ## 输出测序深度文件：
     inBAM=${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam
     samtools depth -a -q 10 $inBAM > ${OUTDIR1}/${i}.depth.txt
     samtools index ${inBAM} ${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam.bai

done


# for i in $sp
# do
#      echo $i
#      ## 输出测序深度文件：
#      inBAM=${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam
#      samtools index ${inBAM} ${OUTDIR1}/${i}Aligned.sortedByCoord.out.bam.bai
# done
