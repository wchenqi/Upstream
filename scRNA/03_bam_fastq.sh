#!/bin/bash

### 脚本说明
## 运行环境: base
## 应用: bam文件转换fastq文件,对接后续CellRanger

export ref="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/CellRanger/scRNA_STseq/Download/refdata-gex-mm10-2020-A/"    # 参考注释文件路径, 见：/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/CellRanger/scRNA_STseq/Download/
export indir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/02_fastq/01Test/"  # 输入包含fastq文件的总路径 indir/sampleid/fastq_file
export outdir="/scratch/2026-09-28/med-wangcq/01SelfUse/01Neutrophil/00Data/00RestData/02_fastq/00MergeFq/" # 输出文件路径
export JOBS=5

## 这里添加判断
find "${indir}" -type f -name "*.bam" | xargs -I {} -P $JOBS bash -c '
    i="$1"
    echo "${i}"
    ## 检查输出文件是否已经建立，如果建立需要删除
    sp=$(basename "${i}" .bam)
    echo ${sp}
    if [ -d "${outdir}/${sp}" ]; then
        rm -rf "${outdir}/${sp}"
    fi
    # 处理bam文件
    bamtofastq --nthreads=6 "${i}" "${outdir}/${sp}"
    # 路径下所有fastq文件转移到${outdir}/${sp}
    fq_file=($(find "${outdir}/${sp}" -type f -name "*.fastq.gz"))
    echo ${fq_file[@]}
    for fl in "${fq_file[@]}"; do
        echo ${fl}
        filename=$(basename "${fl}")
        echo ${filename}
        newname=$(echo $filename | sed "s/bamtofastq/${sp}/g")
        echo ${newname}
        ## 转移文件+重命名文件
        mv "${fl}" "${outdir}/${sp}/${newname}"
    done
    find "${outdir}/${sp}" -mindepth 1 -type d -empty -delete        # 移除空文件夹
    ## 检查路径下文件名
    echo "--- files in ${outdir}/${sp} ---"
    ls ${outdir}/${sp}
' _ {}