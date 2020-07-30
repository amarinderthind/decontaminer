#!/bin/bash
#  fastq2fasta.sh  - see below for details 
# Copyright (C) 2015-2017,  M. Sangiovanni, ICAR-CNR, Napoli 
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.i
#  
# Author: Mara Sangiovanni. Contact:  mara.sangiovanni@icar.cnr.it

# 1) takes in input a sorted and merged (if paired end) fastQ file.
# 2) [OPTIONAL] filter out low-quality reads 
# 3) convert the fastaq file to fasta format removing quality information. 

if (($# == 0)); then
  echo "ERROR No input parameters! CONTACT THE DECONTAMINER TEAM";
fi

SEP="/"
# parameter to pass to the fastaq quality check
fullfile=$1 #input file
FASTX_EXE=$2 #samtools executable
outpath=$3 #output dir
flagQ=$4
q=$5 # percentage of nucleotide with quality q
p=$6 # quality of the nucleotide
Q=$7 # quality encoding

#echo "This is fastQ2fasta "
fname=$(basename "$fullfile")
dname=$(dirname "$fullfile")
name="${fname%.*}"

echo " INFO:  processing fastaQ  $fullfile "
#4)- optional step: filter reads by quality. Numeric input should be given for minimum read quality, minimum sequence quality and the encoding
# IF ENCODING IS NOT SET, DEFAULT VALUE IS 33 
OUT_PATH_QUALITY=$dname$SEP$name
OUT_PATH_QUALITY+="_Q.fastq"

if [ $flagQ = 1 ]; then
 echo " INFO: quality filtering the fastq files  with nucleotide quality: $q, percentage: $p, encoding: $Q ."
  $FASTX_EXE  -q "$q" -p "$p" -Q"$Q" -i $fullfile -o $OUT_PATH_QUALITY
  echo " done. Output files written in dir $OUT_PATH_QUALITY"
fi

#5) convert to fasta removing quality info
echo " INFO: converting to fasta format..."
OUT_PATH_FASTA=$outpath$SEP$name
OUT_PATH_FASTA+=".fasta"
if [[ $flagQ = 1 ]]; then
< $OUT_PATH_QUALITY awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > $OUT_PATH_FASTA
else
< $fullfile awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > $OUT_PATH_FASTA
fi
echo " ...done. Output file written in dir $DIR_FASTA"
