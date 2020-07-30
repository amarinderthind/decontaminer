#!/bin/bash
# startSortMeRNA.sh  - simply starts the tool
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

SORTMERNA_EXEC=$2
SMR_DB=$3
outdir=$4

fname=$(basename "$1")
name="${fname%.*}"

SEP="/"
ALIGNED_OUT=$outdir$SEP$name
ALIGNED_OUT+="_RIBO_ALIGNED"
UNALIGNED_OUT=$outdir$SEP$name
UNALIGNED_OUT+="_RIBO_UNALIGNED"

echo " INFO: extracting ribosomal RNA..."


# calls sortMeRNA to extract ribosomal RNA
# SMR_DB: the ribosomal db and index
# FASTA_IN: the input FASTA to be compared vs the DB
# ALIGNED_OUT: the file of the found alignments, in blast (table) format
# UNALIGNED_OUT: the file of the unaligned reads, in fasta format
$SORTMERNA_EXEC --ref $SMR_DB --reads "$1" --blast "1 cigar qcov" --aligned "$ALIGNED_OUT" --fastx --other "$UNALIGNED_OUT" fasta --paired_out -e 0.0000000000000000000000000000001
echo " done. Output written in $UNALIGNED_OUT"
