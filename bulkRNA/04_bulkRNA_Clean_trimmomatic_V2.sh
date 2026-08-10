#bash脚本
#conda activate bulkRNA
#### 本脚本用于对fastQC数据Clean:
### 去除低质量序列和接头
#1）Trimmomatic 用于去除 Illumina平台的FASTQ序列中的Adapter，根据碱基质量值修整FASTQ序列文件
#接头文件所在路径：/work/med-wangcq/00DataBase/00Tools/Trimmomatic-0.39/adapters/
#支持单末端（SE），双末端（PE）测序数据
#支持多线程，gzip，bzip2压缩的FASTQ文件
#支持phred-33 和 phred-64 格式互相转化，目前多数Illumina测序数据为phred-33格式
#https://blog.csdn.net/mai_curious/article/details/126520533
#https://zhuanlan.zhihu.com/p/91691632
#https://www.jianshu.com/p/2ff43245ebd5 数据污染处理

module load java/10.0.2
#### 读入参数：
#Sample="Qin_Cre_GN_S6,Qin_Cre_WAT_S8,Qin_KO_GN_S7,Qin_KO_WAT_S9"
#SP=(${Sample//,/ })  
#echo ${SP[@]}
adaptor_file="/work/med-wangcq/00DataBase/00Tools/Trimmomatic-0.39/adapters/TruSeq3-PE-2.fa"
outdir1="/scratch/2024-12-25/med-wcq/ZhiYang.L/GSE236586/01RNA_seq/05FastQC/"
indir="/scratch/2024-12-25/med-wcq/ZhiYang.L/GSE236586/01RNA_seq/03Clean_fastp/"
SP=`ls -l $indir |grep "^d" |awk '{print $NF}'`
echo $SP

mkdir -p $outdir1
cd $outdir1

echo $outdir1
#adaptor_file="/work/med-wangcq/00DataBase/00Tools/Trimmomatic-0.39/adapters/NexteraPE-PE.fa"
trimmomatic="/work/med-wangcq/00DataBase/00Tools/Trimmomatic-0.39/trimmomatic-0.39.jar"
#for sample_name in ${SP[@]}
for sample_name in $SP
do
    echo $sample_name
    #mkdir -p ${outdir1}/${sample_name}
    mkdir -p ${outdir1}/paired_fastq/${sample_name}
    mkdir -p ${outdir1}/unpaired_fastq/${sample_name}
    cd ${outdir1}
    echo ${indir}/${sample_name}/${sample_name}_1.fq.gz
#-summary ${outdir1}/${sample_name}/PR1.summary \
    java -jar $trimmomatic \
            ILLUMINACLIP:${adaptor_file}:2:30:10 \
            PE -phred33 \
            ${indir}/${sample_name}/${sample_name}_1.fq.gz \
            ${indir}/${sample_name}/${sample_name}_2.fq.gz \
            paired_fastq/${sample_name}/${sample_name}_R1.fastq unpaired_fastq/${sample_name}/${sample_name}_R1.fastq \
            paired_fastq/${sample_name}/${sample_name}_R2.fastq unpaired_fastq/${sample_name}/${sample_name}_R2.fastq \
            SLIDINGWINDOW:3:28 \
            HEADCROP:19 \
            MINLEN:40 \
            TOPHRED33 \
            LEADING:28 \
            TRAILING:28
done

###https://blog.csdn.net/I_LiYY/article/details/105533946#:~:text=%E4%BA%94%E3%80%81%E8%BD%AF%E4%BB%B6%E4%BD%BF%E7%94%A8%201%201%E3%80%81%E4%BF%AE%E5%89%AA%E6%AD%A5%E9%AA%A4%E8%AF%B4%E6%98%8E%20Trimmomatic%20%E4%B8%BAillumina%E5%AF%B9%E7%AB%AF%E5%92%8C%E5%8D%95%E7%AB%AF%E6%95%B0%E6%8D%AE%E6%89%A7%E8%A1%8C%E5%90%84%E7%A7%8D%E6%9C%89%E7%94%A8%E7%9A%84%E4%BF%AE%E5%89%AA%E4%BB%BB%E5%8A%A1%E3%80%82%20%E4%BF%AE%E5%89%AA%E6%AD%A5%E9%AA%A4%E5%8F%8A%E5%85%B6%E7%9B%B8%E5%85%B3%E5%8F%82%E6%95%B0%E7%9A%84%E9%80%89%E6%8B%A9%E5%9C%A8%E5%91%BD%E4%BB%A4%E8%A1%8C%E4%B8%AD%E6%8F%90%E4%BE%9B%E3%80%82%20%E6%AD%A3%E7%A1%AE%E7%9A%84%E4%BF%AE%E5%89%AA%E6%AD%A5%E9%AA%A4%3A%20...,1%29%20ILUMINACLIP%3A%3CfastaWithAdaptersEtc%3E%3A%3Cseed%20mismatches%3E%3A%3Cpalindrome%20clip%20threshold%3E%3A%3Csimple%20clip%20threshold%3E%3A%3CminAdapterLength%3E%3A%3CkeepBothReads%3E%20
#正确的修剪步骤:
#1)ILLUMINACLIP: 切除read中的接头以及Illumina特异序列；
#2)SLIDINGWINDOW: 划窗修剪方法。它从5'端开始扫描，当窗口内的平均质量低于阈值时，它会剔除该窗口内的所有碱基；
#3)MAXINFO: 自适应质量微调器，它平衡读取长度和错误率，最大化每条read的价值；
#4)LEADING: 切除read起始端低于阈值的碱基；
#5)TRAILING: 切除read末端低于阈值的碱基；
#6)CROP: 切除read末端指定数量的碱基；
#7)HEADCROP: 切除read起始端指定数量的碱基；
#8)MINLEN: 丢弃低于指定长度的read；
#9)AVGQUAL: 丢弃平均质量低于指定质量的read；
#10)TOPHRED33: 转换质量分数为Phred-33；
#11)TOPHRED64: 转换质量分数为Phred-64。



#TOPHRED33: ASCII值小于等于58（相应的质量得分小于等于25）对应的字符只有在Phred+33的编码中被使用，
#TOPHRED64: 所有Phred+64所使用的字符的ASCII值都大于等于59。
#在通常情况下，ASCII值大于等于74的字符只出现在Phred+64中

### 双端测序：
## PE模式中，输入文件有两个，输出文件有四个
## ILLUMINACLIP:${adaptor_file}:2:30:10 \
    #java -jar $trimmomatic \
    #       PE -phred33 \
    #       -summary ${outdir1}/${sample_name}/PR1.summary \
    #       ${inputData_dir}${sample_name}_ERCC-Mix1_Build37-ErccTranscripts-chr22.read1.fastq \
    #       ${inputData_dir}${sample_name}_ERCC-Mix1_Build37-ErccTranscripts-chr22.read2.fastq \
    #       paired_fastq/${sample_name}_R1.fastq unpaired_fastq/${sample_name}_R1.fastq \
    #       paired_fastq/${sample_name}_R2.fastq unpaired_fastq/${sample_name}_R2.fastq \
    #       ILLUMINACLIP:${adaptor_file}:2:30:10 \   
                # 从reads中剪切adapter和其他Illumina特定序列
                # 2:30:10即表示，在比对接头序列时允许有两个位置的碱基发生错配，
                # 双端测序的两条reads与接头序列匹配率超过30%的话，就会被切除掉，
                # 单条reads如果与接头序列的匹配率超过10%，也会被切除掉。
    #       SLIDINGWINDOW:4:28 \
    #       HEADCROP:19 \
    #       MINLEN:28 \
                # 如果reads低于指定长度，则删除
    #       TOPHRED33 \
    #       LEADING:3  \
    #       TRAILING:3   # 执行4bp滑动窗口修剪，一旦窗口内的平均质量低于阈值15，则切割


### 单端测序：
    #java -jar $trimmomatic \
    #    SE -phred33 \
    #    -summary ${outdir1}/${sample_name}/PR1.summary \
    #    ${indir}/${sample_name}/${sample_name}.fastq.gz \
    #    ${outdir1}/${sample_name}/${sample_name}.fastq \
    #    SLIDINGWINDOW:4:28 \
    #    HEADCROP:19 \
    #    MINLEN:28 \
    #    TOPHRED33 \
    #    LEADING:3  \
    #    TRAILING:3
        #AVGQUAL:25 \

#### adapter信息：
#https://support-docs.illumina.com/SHARE/AdapterSequences/Content/SHARE/FrontPages/AdapterSeq.htm
#https://zhuanlan.zhihu.com/p/349339551
## Nextera CTGTCTCTTATACACATCT
## 