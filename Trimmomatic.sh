#make list
for i in `less ../DNA_sample.list`; 
do ls ./${i}/*_1.fq.gz |cut -f 3 -d'/' > ${i}_fq ;
sed -i 's/1\.fq\.gz//g' ${i}_fq ;
done

#cp ./trimmomatic/0.36/adapters/TruSeq3-PE-2.fa ./
for i in `less DNA_sample.list`; do \
#DNA_sample.list
read_path=.//WholeGenomeSequence/Rawdata/${i}
R_prefix=`less ./Rawdata/${i}_fq`
input1=${R_prefix}1.fq.gz
input2=${R_prefix}2.fq.gz
Tri_wd=./Install/Trimmomatic/Trimmomatic-0.39/
echo "inputfile Forward R1: $input1 and Reverse R2 $input2"
#trimmomatic
java -jar ${Tri_wd}/trimmomatic-0.39.jar PE -threads 8 -phred33 ${read_path}/$input1 ${read_path}/$input2 ${read_path}/paired_$input1 ${read_path}/unpaired_$input1 ${read_path}/paired_$input2 ${read_path}/unpaired_$input2 ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done

#END#
