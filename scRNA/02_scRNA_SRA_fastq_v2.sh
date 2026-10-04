#!/bin/bash
set -euo pipefail

#### 脚本说明：
#1) 运行环境：conda activate /data/med-hancs/apps/anaconda3/2022.10/envs/Scanpy
#2) sra转fastq文件

#参考： 
# https://zhuanlan.zhihu.com/p/591140275
# https://zhuanlan.zhihu.com/p/536865827

outdir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/02_fastq/"
indir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/01_SRR/"
MapFile="/data/med-wangcq/Chenqi_W/02MI/Neutrophil/00DataInfo/GSM_SRR.csv"      ## 两列文件，无列名，第一列GSM/样本名，第二列SRR, 需要合并fastq文件的时候使用
JOBS=5
# IDs=`ls `
# for i in $IDs
# do
# echo $i
# outdir1="${outdir}/${i}"
# echo $outdir1
# mkdir -p $outdir1
# infile="${indir}/${i}/${i}.sra"
# echo $infile
# #fastq-dump --split-files $infile -O $outdir1 --gzip
# time (parallel-fastq-dump -t 40 -O $outdir1 --split-3 --gzip -s $infile)
# done

find "$indir" -maxdepth 2 -type f -name "*.sra" | xargs -I {} -P $JOBS bash -c '
     i="$1"
     echo "${i}"
     sp=$(basename "${i}" .sra)
     echo ${sp}
     outdir1="'"${outdir}"'/${sp}"
     # tmpdir="'"${outdir}"'/tmp/${sp}"
     mkdir -p "${outdir1}"
     # mkdir -p "${tmpdir}"
     parallel-fastq-dump -t 6 -O "${outdir1}" --split-files --gzip -s "${i}"
     #  --tmpdir "${tmpdir}"
     # 移除tmp文件夹
     # rm -rf "'"${outdir}"'/tmp/"
' _ {}

## 补充根据样本SRR对应关系合并fastq.gz文件
if [ -z "${MapFile:-}" ]; then
    echo "[ERROR] MapFile 变量未定义或为空"
    exit 1
fi

if [ ! -f "${MapFile:-}" ]; then
    echo "[ERROR] MapFile 文件不存在"
    exit 1
else
     ## 根据第一列拆分表格,以第一列为单位合并第二列的srr文件，输出fastq.gz结果按照第一列命名
     ## 替换文件中windows换行符
     sed -i "s/\r$//" "${MapFile}"
     ## 提取GSM名
     cut -d, -f1 "${MapFile}" | sort -u | while read -r gsm; do
          echo ">>> ${gsm}"
          ## 建立新文件夹
          outdir1="${outdir}/00MergeFq/${gsm}"
          if [ ! -d ${outdir1} ]; then
               mkdir -p "${outdir1}"
          fi
          ## 依据第一列对SRR文件进行拆分
          srrs=$(awk -F, -v g="${gsm}" '$1==g {print $2}' "${MapFile}")
          echo "Processing ${srrs}"
          ## 建立空数组存储Read1和Read2
          r1_merge="${outdir1}/${gsm}_S1_L001_R1_001.fastq.gz"
          r2_merge="${outdir1}/${gsm}_S1_L001_R2_001.fastq.gz"
          ## 清空输出
          > "$r1_merge"
          > "$r2_merge"
          ## 对GSM对应的SRR文件逐个循环
          for srr in $srrs; do
               mapfile -t files < <(find ${outdir}/${srr} \
                                        -type f \
                                        -name "${srr}*.fastq.gz" \
                                        -printf '%s\t%p\n' |
                                    sort -nr |
                                    head -n 2 |
                                    cut -f2-
                                    )
               echo "${files[@]}"
               if [[ ${#files[@]} -eq 2 ]]; then
                    read_length1=$(zcat "${files[0]}" | awk 'NR%4==2 {print length($0); exit}')
                    read_length2=$(zcat "${files[1]}" | awk 'NR%4==2 {print length($0); exit}')
                    echo "[$srr] $(basename "${files[0]}") : Read1 - ${read_length1} bp; Read2 - ${read_length2} bp"
                    # 根据 read 长度判断 R1/R2
                    if [[ ${read_length1} -ne ${read_length2} ]]; then
                         if [[ "$read_length1" -gt 30 ]]; then
                              r2_file="${files[0]}"
                              r1_file="${files[1]}"
                         else
                              r2_file="${files[1]}"
                              r1_file="${files[0]}"
                         fi
                    else
                         r1_file="${files[0]}"
                         r2_file="${files[1]}"
                    fi
                    echo "${srr} processing DONE"
               else
                    echo "[WARN] ${srr}: expected 2 files, got ${#files[@]}"
               fi
          done
          ## 检查输出结果
          if [[ -s $r1_merge ]];then
               zcat "$r1_merge" | head
          else
               rm -f $r1_merge
          fi
          if [[ -s $r2_merge ]];then
               zcat "$r2_merge" | head
          else
               rm -f $r2_merge
          fi
     done
fi
