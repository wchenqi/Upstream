#!/bin/bash

### 脚本说明
#1) 运行环境: conda activate /work/med-hancs/miniforge3/envs/seeksoultools
#2) 针对SeekOne@DD 全序列产品的序列比对和表达定量
### 运行备注
# 需要使用较新版本pysam, 否则会报错

outdir="/scratch/2026-08-19/med-wangcq/Others/AnJQ_source/AnalysisData/Sam68OECM_scFASTseq/02Result/00UpStream/"
GenomePath="/data/med-wangcq/01CondaEnv/02Git_repo/01DataBase/Genome_Annotation_Reference/00Download/scFASTseq/Fast/"
ref="mm10"
inPath="/scratch/2026-08-19/med-wangcq/Others/AnJQ_source/AnalysisData/Sam68OECM_scFASTseq/00RawData/WangCQ_data_260525/data/raw_fastq/"

set -u

# 建立输出文件夹
mkdir -p "${outdir}"

for sp in P6GFP_01 P6GFP_02 P6GFP_03 P6Sam68_01 P6Sam68_02 P6Sam68_03
do	
	echo "正在处理样本: ${sp}"
	fq1_files=$(find ${inPath} -type f -name "*${sp}*R1_001.fastq.gz" | sort)
	fq2_files=$(find ${inPath} -type f -name "*${sp}*R2_001.fastq.gz" | sort)
	echo ${fq1_files}
	echo ${fq2_files}
	# --- 2. 检查是否真的找到了文件 ---
	if [ -z "$fq1_files" ] || [ -z "$fq2_files" ]; then
		echo "⚠️ 警告：找不到样本 ${sp} 的完整 R1/R2 FASTQ 文件，已跳过！"
		continue
	fi
	# --- 3. 将查找到的文件路径转换为 Bash 数组 ---
	# 使用 readarray 将多行文件路径安全地读入数组 (Bash 4.0+ 支持)
	readarray -t fq1_array <<< "$fq1_files"
	readarray -t fq2_array <<< "$fq2_files"
	# 兼容 Bash < 4.0 和 >= 4.0
	# OLD_IFS="$IFS"
	# IFS=$'\n'
	# fq1_array=($fq1_files)
	# fq2_array=($fq2_files)
	# IFS="$OLD_IFS"
	
	# 检查 R1 和 R2 的文件数量是否匹配
	if [ ${#fq1_array[@]} -ne ${#fq2_array[@]} ]; then
		echo "❌ 错误：样本 ${sp} 的 R1 和 R2 文件数量不一致 (R1: ${#fq1_array[@]}, R2: ${#fq2_array[@]})，请检查！"
		continue
	fi

	echo "检测到该样本有 ${#fq1_array[@]} 条 Lane 的数据。"

	# --- 4. 动态构建 seeksoultools 的命令参数 ---
	# 使用 sed 和 join 将数组转为: --fq1 file1 --fq1 file2 的格式
	# 注意这里的 printf 格式: "%s" 代替空格，防止路径名中有空格导致报错
	fq1_args=$(printf "--fq1 %s " "${fq1_array[@]}")
	fq2_args=$(printf "--fq2 %s " "${fq2_array[@]}")

	# 工具会自动建立样本名命名的文件名
	seeksoultools fast run \
		$(printf -- "--fq1 %s " "${fq1_array[@]}") \
		$(printf -- "--fq2 %s " "${fq2_array[@]}") \
		--samplename "${sp}" \
		--genomeDir "${GenomePath}/${ref}/star/" \
		--gtf "${GenomePath}/${ref}/genes/genes.gtf" \
		--rRNAgenomeDir "${GenomePath}/${ref}_rRNA/star/" \
		--rRNAgtf "${GenomePath}/${ref}_rRNA/genes/delete_rRNA.gtf" \
		--chemistry DD-Q \
		--include-introns \
		--core 5 \
		--outdir "${outdir}"
done