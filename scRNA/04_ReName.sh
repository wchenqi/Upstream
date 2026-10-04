indir="/scratch/2025-01-13/med-wcq/Junqin_An/GSE159677/02Fastq/"
IDs=`ls $indir | grep "SR"`
outdir="/scratch/2025-01-13/med-wcq/Junqin_An/GSE159677/03Rename/"
for i in $IDs
do
outdir1=$outdir"/"$i"/"
mkdir -p $outdir1
cd $outdir1
echo $outdir1
#https://zhuanlan.zhihu.com/p/565855667
## 根据大小从小到大对文件排序：
file1=`ls -Slr $indir$i | awk 'NR==2 {print $NF}'`
file2=`ls -Slr $indir$i | awk 'NR==3 {print $NF}'`
file3=`ls -Slr $indir$i | awk 'NR==4 {print $NF}'`
echo $file1
echo $file2
echo $file3
cp $indir$i"/"$file1 $outdir1${i}_S1_L001_I1_001.fastq.gz
cp $indir$i"/"$file2 $outdir1${i}_S1_L001_R1_001.fastq.gz
cp $indir$i"/"$file3 $outdir1${i}_S1_L001_R2_001.fastq.gz
echo $i" rename DONE!!!"
done