#!/usr/bash

#### 本脚本是为了实现基因组比对
# https://www.jianshu.com/p/e34ab865f055
# https://zhuanlan.zhihu.com/p/581922508
# STAR安装： https://zhuanlan.zhihu.com/p/362727395    https://github.com/alexdobin/STAR
# 参考基因组：https://zhuanlan.zhihu.com/p/383397412

module load java/10.0.2
source /data/med-wangcq/01CondaEnv/00DataBase/00Tools/STAR-2.7.11a/env.sh

#### 设置参数
export OUTDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/"
export INDIR="/scratch/2026-08-19/med-wangcq/Others/Hancs/GSE193516/03Fastp/"
export GENOME_DIR="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/STAR/Mus_musculus/GRCm38_mm10_Ensembl/"
export THREADS=40
export SUFFIX=".fastq"
export JOBS=$(( THREADS / 8 ))

#### 处理参数
## 建立输出文件夹
OUTDIR1="${OUTDIR}/03STAR"
mkdir -p $OUTDIR1
cd $OUTDIR1

# 输出记录软件版本和参考基因组版本的文件
RECORD="${OUTDIR1}/COfile.txt"
STAR_VERSION=$(STAR --version | head -n 1)
echo $STAR_VERSION
echo -e "@CO\tSTAR version=${STAR_VERSION}\n@CO\tGENOME PATH=${GENOME_DIR}" > "$RECORD"

## 提取fastq文件路径
#1) 如果一个run一个文件夹
# sp=$(find "$INDIR" -mindepth 1 -maxdepth 2 -type d -printf "%f\n")
# echo $sp

#2) 如果全部都在一个文件夹
find $INDIR -mindepth 1 -type f -name "*${SUFFIX}" | \
grep -v "_2${SUFFIX}" | \
xargs -P ${JOBS} -n 1 bash -c '
     #### STARsolo比对：
     ## 如果是gz文件, 使用 --readFilesCommand zcat 参数进行读取
     fq1="$1"
     filename=$(basename ${fq1})
     echo "Processing $fq1"

     ## 传参
     # SUFFIX='"SUFFIX"'
     # OUTDIR1='"$OUTDIR1"'
     # GENOME_DIR='"$GENOME_DIR"'
     # RECORD='$RECORD'

     # 判断单端双端测序数据
     if [[ "${filename}" == *_1${SUFFIX} ]]; then
          # 双端
          fq2="${fq1/_1${SUFFIX}/_2${SUFFIX}}"
          [ ! -f "$fq2" ] && exit 1
          sample=$(basename "${fq1}" "_1${SUFFIX}")
          outdir="${OUTDIR1}/PE"
          read_files="$fq1 $fq2"
     else
          # 单端
          sample=$(basename "${fq1}" "${SUFFIX}")
          sample=${sample%.gz}  # 去掉 .gz 后缀
          outdir="${OUTDIR1}/SE"
          read_files="$fq1"
     fi
     ## 这里直接建立输出文件夹
     mkdir -p "$outdir"

     # 检测压缩文件
     read_cmd=""
     [[ "${fq1}" == *.gz ]] && read_cmd="zcat"         # 这里&&和if; then命令格式一样

     # 一行执行（使用条件扩展）
     STAR --runThreadN 5 \
          --genomeDir "$GENOME_DIR" \
          --readFilesIn $read_files \
          ${read_cmd:+--readFilesCommand $read_cmd} \
          --outFileNamePrefix "${outdir}/${sample}" \
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
          --outSAMheaderCommentFile "$RECORD" \
          2>&1 | tee "${outdir}/${sample}_STAR.log"

     # ===== 立即验证 + 索引（合并在一起）=====
     BAM="${outdir}/${sample}Aligned.sortedByCoord.out.bam"
     
     if [ -f "$BAM" ]; then
          echo "BAM generated: $BAM"
          
          if samtools quickcheck "$BAM" 2>/dev/null; then
               echo "BAM OK, indexing..."
               samtools index -@ 4 "$BAM" && echo "Index done: ${BAM}.bai" || echo "Index failed"
          else
               echo "BAM CORRUPTED, removing: $BAM"
               rm -f "$BAM"
               echo "Please rerun $sp manually"
          fi
     else
          echo "FAILED: BAM not found for $sp"
     fi
     
     echo "=== Finished: $sp ==="
' _

echo "All samples processed. Check Results in ${OUTDIR1}"

# for i in $sp
# do
#      echo $i
#      ## 输出测序深度文件：
#      inBAM=${OUTDIR1}/${sp}Aligned.sortedByCoord.out.bam
#      samtools index ${inBAM} ${OUTDIR1}/${sp}Aligned.sortedByCoord.out.bam.bai
# done
