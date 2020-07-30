#!/bin/bash

# startBlast.sh starts the megablast tool 
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


if (($# == 0)); then
  echo "NO INPUT PARAMETERS!"; exit;
fi
# process options

fullfile=$1 #input file
BLASTN_EXE=$2
DB_BACTERIA=$3
DB_FUNGI=$4
DB_VIRUSES=$5
bflag=$6 #bacteria
fflag=$7 #fungi
vflag=$8 #viruses
outdir=$9

# 1) run BLAST on the fasta file in input.
# each directory has a unique ID
if [[ ! (-f $fullfile) ]]; then
 echo "Wrong filepath or input file not existent: $fullfile"; exit;
fi

# if no database is explicitely chosen, select all (equivalent to -bfv)
if [ $bflag = "false" ]  &&  [ $fflag = "false" ] && [ $vflag = "false" ]; then
        echo "No database specified. Assuming all (-bfv)"
	bflag=true;fflag=true;vflag=true;
fi

fname=$(basename "$fullfile")
dname=$(dirname "$fullfile")
name="${fname%.*}"
SEP="/"
ROOT_DIR=$dname
DIR_RESULTS="$outdir"

#
echo " Processing fasta $fname in dir $dname"

# make the results  directory 
if [ ! -d "$DIR_RESULTS" ]; then
mkdir $DIR_RESULTS
fi

# separate output in different folders
DIR_RESULTS=$DIR_RESULTS$SEP

# now proceed.
if [ $bflag = "true" ]; then
 DIR_RESULTS_B=$DIR_RESULTS$SEP
 DIR_RESULTS_B+="BACTERIA"
 # make the results  directory 
 if [ ! -d "$DIR_RESULTS_B" ]; then
  mkdir $DIR_RESULTS_B
 fi

 OUT_PATH_BLAST_B=$DIR_RESULTS_B$SEP$name
 OUT_PATH_BLAST_B+="_vs_bacteria.table"

 echo " INFO: processing bacteria database ..."
 $BLASTN_EXE -task megablast -query "$fullfile" -db $DB_BACTERIA -out "$OUT_PATH_BLAST_B" -outfmt "6 qseqid sseqid qlen staxids salltitles pident length mismatch gaps qstart qend sstart send evalue bitscore nident sstrand qcovs" &
# echo "   ... done. Output written in $OUT_PATH_BLAST_B"
fi

# now proceed.
if [ $fflag = "true" ]; then
 DIR_RESULTS_F=$DIR_RESULTS$SEP
 DIR_RESULTS_F+="FUNGI"

 # make the results  directory 
 if [ ! -d "$DIR_RESULTS_F" ]; then
 mkdir $DIR_RESULTS_F
 fi

 OUT_PATH_BLAST_F=$DIR_RESULTS_F$SEP$name
 OUT_PATH_BLAST_F+="_vs_fungi.table"

  echo " INFO: processing fungi database ..."
 $BLASTN_EXE -task megablast -query "$fullfile" -db $DB_FUNGI -out "$OUT_PATH_BLAST_F" -outfmt "6 qseqid sseqid qlen staxids salltitles pident length mismatch gaps qstart qend sstart send evalue bitscore nident sstrand qcovs" &
# echo "   ... done. Output written in $OUT_PATH_BLAST_F"
fi

# now proceed.
if [ $vflag = "true" ]; then
 DIR_RESULTS_V=$DIR_RESULTS$SEP
 DIR_RESULTS_V+="VIRUSES"

 # make the results  directory 
 if [ ! -d "$DIR_RESULTS_V" ]; then
 mkdir $DIR_RESULTS_V
 fi

OUT_PATH_BLAST_V=$DIR_RESULTS_V$SEP$name
OUT_PATH_BLAST_V+="_vs_viruses.table"

 echo " INFO: processing viruses database ..."
  $BLASTN_EXE -task megablast -query "$fullfile" -db $DB_VIRUSES -out "$OUT_PATH_BLAST_V" -outfmt "6 qseqid sseqid qlen staxids salltitles pident length mismatch gaps qstart qend sstart send evalue bitscore nident sstrand qcovs" &
#  echo "done. Output written in $OUT_PATH_BLAST_V"
fi

wait
 echo "   ... done. Output written in $DIR_RESULTS"


