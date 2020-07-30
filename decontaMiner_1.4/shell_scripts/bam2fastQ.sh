#!/bin/bash
# 
# bam2fastq.sh - see below for details 
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
# 
# 1) sort the unmapped BAM file using samtools. Output: one sorted BAM file
# 2) convert sorted BAM files to fastq using samtools. Output: a fastq files
# PLEASE DO NOTE : input and output paths are passed as input parameters the following order:
#                  1) input filepath, 2:samtools exe from ini file, 3: intermediate file dir, 4: output dir, 5) pairing flag
# USE WITH CAUTION; at the moment no check is made on the input values
# each file has a unique id!
# 
if (($# == 0)); then
  echo "$(tput setaf 1)ERROR!! Something went wrong: no  input parameters in bam2fastq.sh  CONTACT THE DECONTAMINER DEVELOPING TEAM ! $(tput sgr 0)";
fi

SEP="/"
fullfile=$1
SAMTOOLS_EXE=$2
INTER_DIR=$3
FASTQ_DIR=$4
flagP=$5


fname=$(basename "$fullfile")
#dname=$(dirname "$fullfile")
name="${fname%.*}"
#echo "    INFO: processing BAM  $name "

# make a directory for each step
DIR_SORT=$INTER_DIR$SEP
DIR_SORT+="SORTED"

if [ ! -d "$DIR_SORT" ]; then
mkdir $DIR_SORT
fi

# now proceed.
# 1) sort the unmapped bam
echo " INFO: sorting the bam file. Please wait, this might take some time..."
OUT_PATH_SORT=$DIR_SORT$SEP$name
OUT_PATH_SORT+=".qsort"

$SAMTOOLS_EXE sort -n -O 'bam' -T 'temp' -o "$OUT_PATH_SORT" "$fullfile"
echo "        done. Output file written in dir $OUT_PATH_SORT"

#2) convert to fastq
echo " INFO: converting to fastq ..."
IN_PATH_FASTQ=$OUT_PATH_SORT

OUT_PATH_SKIPPED=$DIR_SORT$SEP$name
OUT_PATH_SKIPPED+="_SKIPPED.fastq"

OUT_PATH_FASTQ=$FASTQ_DIR$SEP$name
OUT_PATH_FASTQ+=".fastq"

$SAMTOOLS_EXE fastq $IN_PATH_FASTQ -s $OUT_PATH_SKIPPED > $OUT_PATH_FASTQ
echo "        done. Output file written in dir $OUT_PATH_FASTQ"
echo "              Skipped reads (if present) written in dir $OUT_PATH_SKIPPED"

# NOW CHECK: if the pairing flag is single end (i.e flagP=0) then the skipped file MUST be empty
if [[  (-f "$OUT_PATH_SKIPPED") &&  (-s "$OUT_PATH_SKIPPED") && ($flagP = 0) ]]; then
 echo "$(tput setaf 3) WARNING!  Data declared as SINGLE END, but skipped file is not empty. ARE DATA MAYBE PAIRED END ? $(tput sgr 0) "
fi




