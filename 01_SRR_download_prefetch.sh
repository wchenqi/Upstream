#!/bin/bash

## 脚本说明
#1) 运行环境: base
#2) 应用场景: SRR数据下载
## 更新记录
# A. 输入accession id支持 
#       项目级别: PRJNA / SRP / ERP / DRP; 
#       实验级别: SRX / ERX / DRX; 
#       样本级别: SRS / ERS / DRS / SAMN; 
#       运行级别: SRR / ERR / DRR
# B. 脚本并行运行

# ===================================== 配置区 =========================================
JOBS=4
API_BASE="https://www.ebi.ac.uk/ena/portal/api/filereport"
INFILE="/data/med-wangcq/Chenqi_W/03Splicing/03PublicData/GSE205438/01Data/SRR_Acc_List_scRNA.txt"
# "/data/med-wangcq/Chenqi_W/03Splicing/03PublicData/GSE153801/00Data/GSE153800_RNAseq/SRR_Acc_List.txt"  # 一行一个id
FIELDS="run_accession,sample_accession,secondary_sample_accession,sample_alias,fastq_ftp,submitted_ftp,library_layout,library_strategy,instrument_platform"
OUTDIR="/scratch/2026-08-19/med-wangcq/SelfUse/Heart/01_GEO/GSE205438/01scRNA/01SRA/"
MAX_SIZE=500G
# 设置重试次数
MAX_RETRY=5
RETRY_DELAY=10

OUTFILE="${OUTDIR}/DataInfo_ENA.tsv"
TMPFILE="${OUTDIR}/tmp.tsv"

# ================================================= 
# 第一步：创建输出路径
mkdir -p "$OUTDIR" || { echo "ERROR: 无法创建输出目录 $OUTDIR"; exit 1; }
# 第二步: 使用 Project ID 下载数据信息
echo "Scratching DataInfo"
## ========= 互斥逻辑 =========
if [[ -f "$INFILE" ]]; then
    echo "[INFO] Use INFILE: $INFILE"
    # grep -v '^#' "$INFILE" | mapfile -t acc_list     # 提取非注释行，消除末尾的\t赋值到变量acc_list
    sed 's/[[:space:]]*$//' "$INFILE" | grep -v '^#' > "${TMPFILE}"
    mapfile -t acc_list < "${TMPFILE}"
else
    echo "[ERROR] INFILE are invalid"
    exit 1
fi

## ========= 清空输出 =========
> "$OUTFILE"
> "$TMPFILE"

## ========= 主循环 =========
for acc in "${acc_list[@]}"; do
    echo "[INFO] Fetching metadata for: $acc"

    curl -s "${API_BASE}?accession=${acc}&result=read_run&fields=${FIELDS}&format=tsv&download=true" > "$TMPFILE"
    
    ## 检测文件存在且非空的时候继续运行
    [[ ! -s "$TMPFILE" ]] && continue

    ## 第一次写 header，后续只追加数据
    if [[ ! -s "$OUTFILE" ]]; then
        # 正式输出文件不存在或者内容为空的时候直接写入含标题的所有内容
        cat "$TMPFILE" > "$OUTFILE"
    else
        # 如果文件存在且非空,从第二行开始输出
        tail -n +2 "$TMPFILE" >> "$OUTFILE"
    fi
done

## 跳过第一行去重
{ head -n 1 "$OUTFILE"
  tail -n +2 "$OUTFILE" | sort -u
} > "${OUTFILE}.tmp" && mv "${OUTFILE}.tmp" "$OUTFILE"

echo "[DONE] Output written to:"
echo "$OUTFILE"

# 如果ENA数据库中没有找到信息,就使用原提供表格
if [ ! -s $OUTFILE ]; then
    cp "$INFILE" "$OUTFILE"
fi

# 第三步：并行执行下载
# 记住后面的占位符_不能省略
echo "Start parallel downloading $JOBS"
awk -F '\t' '{print $1}' "$OUTFILE" | xargs -n 1 -P "$JOBS" \
                    bash -c '
                        sra_id="$1";
                        outdir='"${OUTDIR}"';
                        maxsize='"${MAX_SIZE}"';
                        prefetch -f yes --resume yes -p --max-size "$maxsize" -O "$outdir" "$sra_id" || exit 1
                    ' _

### 查看已下载和未下载文件数
## 获取已成功下载文件名
find "${OUTDIR}" -name "*.sra" -type f -exec dirname {} \; | sort -u | xargs -n1 basename > "${OUTDIR}/SRR_download.txt"
echo "输出未成功下载文件："
comm -23 "${TMPFILE}" "${OUTDIR}/SRR_download.txt"
# 1 仅在文件1存在的行
# 2 仅在文件2存在的行
# 3 在文件1和文件2共同存在的行
# -12 排除12,输出仅在文件1和文件2共同存在的行
# -13 排除13,输出仅在文件2存在的行
# -23 排除23,输出仅在文件1存在的行
