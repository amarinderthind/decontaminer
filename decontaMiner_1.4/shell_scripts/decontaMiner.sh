#!/bin/bash
# decontaMiner.sh - the main script of the decontaMiner pipeline
# ./decontaminer.sh -h to print the help menu
# see the user guide for details
#
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



 
#######################################################################################################
###                         CODE: DO NOT CHANGE AFTER THIS LINE!!!!
######################################################################################################

###
### 1 - EVALUATE THE INPUT OPTIONS AND VALUES
echo
echo " -- WELCOME TO THE DECONTAMINER PIPELINE --"
echo
if (($# == 0)); then
  echo "$(tput setaf 1)ERROR!! No input parameters!$(tput sgr 0)" 
  echo " decontaminer.sh -i <inputDirectoryPath> -o <outputDirectoryPath> -c <configurationFilePath [ decontaminer.sh -h to print the help menu with all the optional parameters]"; exit;
fi
if (($# > 28)); then
  echo "$(tput setaf 1)ERROR!! Too many parameters!$(tput sgr 0)" 
  echo " decontaminer.sh -i <inputDirectoryPath> -o <outputDirectoryPath> -c <configurationFilePath [ decontaminer.sh -h to print the help menu with all the optional parameters]"; exit;

fi

# parameter to pass to the the other scripts
fulldir='' #input file
format='' # format of the input file (bam, fasta, fastq)
outdir='' #output path
p='' # percentage of nucleotides with quality q
q='' # quality of the nucleotide
enc='' # encoding of the quality stirng. Default is e=33;
confpath='' #configure.txt. Path to the file.
s='' #paired end/single end data
Q='' #flag quality processing, either yes or no.  Default yes.
R='' #flag Rybosomal decont, either yes or no. Default yes
bflag=false #bacteria
fflag=false #fungi
vflag=false #viruses
fhelp=false # print the help page

while getopts ":hbfvo:i:F:e:p:q:s:c:Q:R:" flag; do
  if [[ ("${OPTARG}" == "-i") || ("${OPTARG}" == "-f") || ("${OPTARG}" == "-o") || ("${OPTARG}" == "-s") || ("${OPTARG}" == "-p") || ("${OPTARG}" == "-q") || ("${OPTARG}" == "-e")  || ("${OPTARG}" == "-c") || ("${OPTARG}" == "-Q") || ("${OPTARG}" == "-R") ]]; then
           echo "$(tput setaf 1)ERROR!! Missing one or more input$(tput sgr 0) " ;exit; # input cannot be a flag! Raw but effective check
 fi
  case "${flag}" in
    i) fulldir="${OPTARG}" ;;
    o) outdir="${OPTARG}" ;;
    F) format="${OPTARG}" ;;
    p) p="${OPTARG}" ;;
    q) q="${OPTARG}" ;;
    e) enc="${OPTARG}" ;;    
    c) confpath="${OPTARG}" ;;
    s) s="${OPTARG}" ;;
    Q) Q="${OPTARG}" ;;
    R) R="${OPTARG}" ;;
    b) bflag=true ;;
    f) fflag=true ;;
    v) vflag=true ;;
    h) fhelp=true ;;
    \?)
      echo "$(tput setaf 1)ERROR! Invalid option: -$OPTARG $(tput sgr 0)" >&2
      exit 1
      ;;
    :)
      echo "$(tput setaf 1) ERROR! Option -$OPTARG requires an argument. $(tput sgr 0)" >&2
      exit 1
      ;;
  esac
done

# 1.1 PRINT THE HELP 
 if [ $fhelp = "true" ]; then
 echo " USAGE: decontaMiner.sh [required parameters] [optional parameters] [organism flags]";
 echo " REQUIRED PARAMETERS:";
 echo "  -i <inputDirectoryPath> . FULL PATH to the DIRECTORY containing the unmapped read files.";
 echo "  -o <outputDirectoryPath>. FULL PATH name of the (not-existing) OUTPUT DIRECTORY in which the generated files will be stored. ";
 echo "  -c <configurationFilePath>". FULL PATH to the configuration FILE. ;
 echo "";
 echo " OPTIONAL PARAMETERS:";
 echo "  -F <fileFormat>. Format of the input files. Accepted formats are: bam, fastq, fasta. Default: bam.";
 echo "  -s <pairing>. Specifies if the input data is SINGLE  or PAIRED end. Accepted values are: P (for paired end), S (for single end). Default: P.";   
 echo "  -Q <qualityFiltering>. Specifies if the reads are quality filtered when converting fastq to fasta. Accepted values: y[es]/n[o]. Default: yes. (See -e, -p and -q flags for quality options).";
 echo "  -e <qualityEncoding>. FastQ quality encoding. Default: 33 (Sanger).";
 echo "  -q <readQuality>. Quality threshold. Default: 20.";
 echo "  -p <qualityPercentage>. Percentage of bases above the quality threshold. Default: 100.";
 echo "  -R <ribosomalMitochondrialFiltering>. Specifies if the reads are searched against the ribosomal and mitochondrial human databases. Accepted values: y[es]/n[o]. Default: yes.";
 echo "";
 echo " ORGANISM FLAGS: ";
 echo "  -b -f -v. Bacteria, fungi, viruses db flags. Any combination of the three is possible, example: -bv align against bacteria and viruses. DEFAULT -bfv (align against all the three databases).";    
 echo "";
 echo " OTHER INFO:  " 
 echo "  -h prints this help";
 echo "";
 exit;
 fi

# 1.2 FATAL ERRORS:
if [[ -z "$fulldir" ]]; then
        echo "$(tput setaf 1)ERROR! Missing input directory $(tput sgr 0)";
        echo "Usage: decontaminer.sh -i <inputDirectoryPath> [ decontaminer.sh -h to print the help menu with all the optional parameters] "; exit;
fi

if [[ ! (-d "$fulldir") ]]; then
 echo "$(tput setaf 1)ERROR! Wrong input path or directory name $(tput sgr 0) "; 
 echo "specified directory path  was: $fulldir"
 exit;
fi

if [[ -z "$outdir" ]]; then
        echo "$(tput setaf 1)ERROR! Missing output directory $(tput sgr 0)";
        echo "Usage: decontaminer.sh -i <inputDirectoryPath> [ decontaminer.sh -h to print the help menu with all the optional parameters] "; exit;
fi

if [[ (-d "$outdir") ]]; then
 echo "$(tput setaf 1)ERROR! Output directory name already exists. Please choose a different name $(tput sgr 0)";
 echo "specified directory path was: $outdir"
 exit;
fi

# check the output directory. The user must specify an existing directory path followed by the name of a new, not existing folder
outdir_root=$(dirname "$outdir")

if [[ ! (-d "$outdir_root") ]]; then
 echo "$(tput setaf 1)ERROR! Wrong Output directory path $(tput sgr 0)";
 echo "specified directory path was: $outdir_root"
 exit;
fi

# configuration file
if [[ ! (-z "$confpath") && ! (-f "$confpath") ]]; then
 echo "$(tput setaf 1) ERROR! Wrong configuration file path or file not existent!! $(tput sgr 0)"; 
 echo "specified was: $confpath"
 exit;
fi

### NOW CHECK ALL THE OTHER PARAMETERS

if [[  (-z "$format" ) ]]; then
        echo "INFO: input file format (-f) not specified. BAM assumed";
else
        F_L="$(echo $format | tr '[A-Z]' '[a-z]')"
        if [[  ! ( "$F_L" == "bam" ) &&  ! ( "$F_L" == "BAM" ) && ! ( "$F_L" == "fasta" ) && ! ( "$F_L" == "FASTA" )  && ! ( "$F_L" == "fastq" ) && ! ( "$F_L" == "FASTQ" )  ]]; then
                echo "$(tput setaf 1)ERROR: wrong input file format (-f). Accepted values:  BAM/FASTQ/FASTA$(tput sgr 0)";
                echo "Usage: decontaminer.sh -i <inputDirectoryPath>  [decontaminer.sh -h to print the help menu with all the optional parameters ] "; exit;

        fi
fi

if [[ ! (-z "$p") &&  ! ("$p" =~ ^[0-9]+$) ]]; then
        echo "$(tput setaf 1)ERROR: percentage threshold parameter -p should be numeric.$(tput sgr 0)";
        echo "Usage: decontaminer.sh -i <inputDirectoryPath>  [decontaminer.sh -h to print the help menu with all the optional parameters  ] "; exit;
fi

if [[ ! (-z "$q" ) &&  ! ("$q" =~ ^[0-9]+$) ]]; then
        echo "$(tput setaf 1)ERROR quality threshold parameter -q should be numeric.$(tput sgr 0)";
        echo "Usage: decontaminer.sh -i <<inputDirectoryPath>  [decontaminer.sh -h to print the help menu with all the optional parameters ] "; exit;
fi


if [[ ! (-z "$enc" ) &&  ! ("$enc" =~ ^[0-9]+$) ]]; then
        echo "$(tput setaf 1)ERROR: quality encoding parameter -e should be numeric.$(tput sgr 0)";
        echo "Usage: decontaminer.sh -i <inputDirectoryPath>  [ decontaminer.sh -h to print the help menu with all the optional parameters ] "; exit;
fi

if [[ ( -z "$s" ) ]]; then
	echo "INFO: paired/single end flag -s not specified. PAIRED END assumed  (default option).";
else 
        if [[ ! ("$s" =~ [pPsS] ) ]]; then
        	echo "$(tput setaf 1)ERROR: wrong value for paired/single end flag.$(tput sgr 0)";
        	echo "Usage: decontaminer.sh -i <inputDirectoryPath>  [-s <paired/single end flag (P/S, default P)>] "; exit;
	fi
fi

if [[  (-z "$Q" ) ]]; then
        echo "INFO: quality filtering flag -Q not specified. Quality filtering is ACTIVE (default option).";
else
	Q_L="$(echo $Q | tr '[A-Z]' '[a-z]')"  
	if [[ ! ( "$Q_L" == "n" ) &&  ! ( "$Q_L" == "y" ) && ! ( "$Q_L" == "yes" ) && ! ( "$Q_L" == "no" )  ]]; then
	        echo "$(tput setaf 1)ERROR: wrong quality filtering flag (-Q). Accepted values: Y(es) /N(o) $(tput sgr 0)";
        	echo "Usage: decontaminer.sh -i <inputDirectoryPath>  [decontaminer.sh -h to print the help menu with all the optional parameters ] "; exit;

	fi
fi

if [[  (-z "$R" ) ]]; then
        echo "INFO: ribosomal filtering flag -R not specified. Human ribosomal filtering is ACTIVE (default option).";
else
        R_L="$(echo $R | tr '[A-Z]' '[a-z]')"
        if [[  ! ( "$R_L" == "y" ) &&  ! ( "$R_L" == "n" ) && ! ( "$R_L" == "yes" ) && ! ( "$R_L" == "no" )  ]]; then
                echo "$(tput setaf 1)ERROR: wrong ribosomal filtering flag (-R). Accepted values: Y(es) /N(o) $(tput sgr 0)";
                echo "Usage: decontaminer.sh -i <inputDirectoryPath>  [decontaminer.sh -h to print the help menu with all the optional parameters ] "; exit;

        fi
fi
#### 1.3 SET THE FLAG AND OPTIONS AS SPECIFIED IN THE INPUT
echo 
echo "- PROCESSING DETAILS "


### 1.3.1 input format 
inputFormat="BAM";
if [[ ! ( -z "$format" ) ]]; then
                inputFormat=$format;
fi
echo "INFO: processing input in "$inputFormat" format";


#### 1.3.2 PAIRED/SINGLE END FLAG
flagP=1; # paired end is the default
if [[ ! ( -z "$s" ) && ("$s" =~ [sS] ) ]]; then
   echo "INFO: processing SINGLE END data";
  flagP=0;
  else
    echo "INFO: processing PAIRED END data.";
fi

#### 1.3.3 QUALITY FILTERING FLAG AND PARAMETERS
flagQ=1;

if [[ ! ( -z "$Q" ) ]]; then
	if [[ ( "$Q" == "no" ) || ( "$Q" =~ [nN] ) ]]; then
 		flagQ=0; # no quality filtering
 		echo "INFO: quality filtering is not active ";
	else
 		echo "INFO: quality filtering is ACTIVE";
	fi
fi
#### 1.3.4 QUALITY ENCODING AND PARAMETERS
Q_enc=33;
p_thre=100;
q_thre=20;

if [ $flagQ = 1 ]; then

	if [[ ! ( -z "$enc" ) ]]; then
        	Q_enc=$enc;
                echo "   INFO: quality encoding: "$Q_enc;
	else
		echo "   INFO: quality encoding (-e ) not specified. Default:  33 ";       
	fi

	if [[ ! ( -z "$p" )  ]];then
        	p_thre=$p;
		echo "   INFO: percentage threshold: "$p_thre; 
	else 
	 	echo "   INFO: percentage threshold (-p)  not specified. Default: 100  "; 
        fi
        
	if [[ ! ( -z "$q" ) ]];then
		q_thre=$q;
		echo "   INFO: quality value threshold: "$q_thre; 
        else
        	echo "   INFO: quality value threshold (-q)  not specified. Default: 20 ";
        fi
fi


#### 1.3.5  RIBOSOMAL DECONTAMINATION
flagR=1;
if [[ ( "$R" == "no" ) || ( "$R" =~ [nN] ) ]]; then
 flagR=0; # no quality filtering
 echo "INFO: ribosomal filtering is not active ";
fi

#### 1.3.6  BLAST DATABASES
# if no database is explicitely chosen, select all (equivalent to -bfv)
if [ $bflag = "false" ]  &&  [ $fflag = "false" ] && [ $vflag = "false" ]; then
        echo "INFO: no option was specified for contaminating organisms. Assuming all (BACTERIA/FUNGI/VIRUSES, -bfv)"
        bflag=true;fflag=true;vflag=true;
else 
 if [ $bflag = "true" ]; then
	echo "INFO: searching contamination from BACTERIA. ";
 fi 
 if [ $fflag = "true" ]; then
        echo "INFO: searching contamination from FUNGI. "
 fi 
 if [ $vflag = "true" ]; then
        echo "INFO: searching contamination from VIRUSES. "
 fi 

fi

#################################
### 2.  PROCESS THE INI FILE
################################
echo
echo "- LOADING AND CHECKING THE CONFIGURATION FILE : "
### 2.1 LOAD THE INFO
SEP="/"
# THE EXECUTABLE DIR
SHELL_EXE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# decontaminer root dir
DECO_ROOT_DIR="$(dirname "$SHELL_EXE_DIR" )"

INI_FILE=''
if [[ ! (-z "$confpath") ]]; then
	INI_FILE=$confpath
else
	# the default configuration file
	DEFAULT_FILE=$DECO_ROOT_DIR$SEP"config_files/configure.txt"
	if [[ ! (-f "$DEFAULT_FILE") ]]; then
		echo "$(tput setaf 1) ERROR: a configuration file is not specified in input AND the default file does not exist at $DEFAULT_FILE $(tput sgr 0)"
 		echo " Please specify a configuration file with the -c flag OR restore the default configuration file "
                exit;
	else
        INI_FILE=$DEFAULT_FILE
	fi
fi

echo "INFO: configuration file is: "$INI_FILE

INI_PARSER=$SHELL_EXE_DIR$SEP"bashIniParser"
source $INI_PARSER
cfg_parser "$INI_FILE"
# 2.2 LOAD THE SECTIONS AND VERIFY THE PRESENCE AND CORRECTNESS OF THE SPECIFIED VALUES

#### 2.2.1 External softwares. Except from Blast that must always be present, 
####       the other executables are checked only if the input type is the right one and the flags are set
echo
echo " EXTERNAL SOFTWARE"
cfg_section_ext_soft

if [[  ( $inputFormat = "BAM") ||  ($inputFormat = "bam") ]]; then
	if [[ ! ( -z "$SAMTOOLS_EXEC" )  ]];then
      	  if [[ ! ( -x "$SAMTOOLS_EXEC" )  ]];then       
                	echo "$(tput setaf 1)  ERROR: the SAMTOOLS_EXEC executable does not exist. Please check the configuration file.  $(tput sgr 0)";
        	        exit;
		else 
			echo "  INFO: samtools executable is located at "$SAMTOOLS_EXEC
		fi
        	else
                	echo " $(tput setaf 1) ERROR: the SAMTOOLS_EXEC variable is missing or empty. Please check the configuration file. $(tput sgr 0) ";
			exit;
	fi
fi
if [ $flagQ = 1 ]; then
	if [[ ! ( -z "$FASTX_EXEC" )  ]];then
        	if [[ ! ( -x "$FASTX_EXEC" )  ]];then
                	echo " $(tput setaf 1) ERROR: the FASTX_EXEC executable does not exist. Please check the configuration file. $(tput sgr 0)";
			exit;
        	else
                	echo "  INFO: fastx executable is located at "$FASTX_EXEC
        	fi
        	else
                	echo " $(tput setaf 1) ERROR: the FASTX_EXEC variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
			exit;
	fi
fi

if [ $flagR = 1 ]; then
	if [[ ! ( -z "$SORTMERNA_EXEC" )  ]];then
        	if [[ ! ( -x "$SORTMERNA_EXEC" )  ]];then
                	echo " $(tput setaf 1)  ERROR: the SORTMERNA_EXEC executable does not exist. Please check the configuration file. $(tput sgr 0)";
			exit;
        	else
                	echo "  INFO: sortmerna executable is located at "$SORTMERNA_EXEC
        	fi
        	else
                	echo " $(tput setaf 1)  ERROR: the SORTMERNA_EXEC variable is missing or empty. Please check the configuration file. $(tput sgr 0) ";
			exit;
	fi
fi

if [[ ! ( -z "$BLASTN_EXEC" )  ]];then
        if [[ ! ( -x "$BLASTN_EXEC" )  ]];then
                echo " $(tput setaf 1)  ERROR: the BLASTN_EXEC path does not exist. Please check the configuration file. $(tput sgr 0)";
		exit;
        else
                echo "  INFO: blastn executable is located at "$BLASTN_EXEC
        fi
        else
                echo " $(tput setaf 1)  ERROR: the BLASTN_EXEC variable is missing or empty. Please check the configuration file. $(tput sgr 0) ";
		exit;
fi

#### 2.2.2 Contaminating organisms
cfg_section_cont_db

echo
echo " HUMAN RIBOSOMAL/MITOCHONDRIAL DNA"
if [ $flagR = 1 ]; then
        
	if [[ ! ( -z "$RIBO_DB" )  ]];then
        	if [[ ! ( -d "$RIBO_DB" )  ]];then
                	echo "  $(tput setaf 1) ERROR: the RIBO_DB path does not exist. Please check the configuration file. $(tput sgr 0)";
                	exit;
        	else
			if [[ ! ( -z "$RIBO_NAME" )  ]];then
				RIBO_FASTA=$RIBO_DB$SEP$RIBO_NAME".fasta";
				RIBO_IDX=$RIBO_DB$SEP$RIBO_NAME".idx"	
				# check for the sequences file	
			 	if [[ ! ( -f "$RIBO_FASTA" )  ]];then
					echo " $(tput setaf 1)  ERROR: the ribosomal fasta file does not exist. Please check RIBO_DB and RIBO_NAME in the configuration file. $(tput sgr 0)";
                                	exit;	
				else
					# check for the indexes
					RIBO_IDX_S=$RIBO_IDX"*"
                                        for f in $RIBO_IDX_S; do
						if [[ -e "$f" ]];then
							echo "  INFO: the ribosomal database "$RIBO_NAME" (fasta + indexes) is located at "$RIBO_DB
                                                else
							echo "$(tput setaf 1)  ERROR: the ribosomal index files do not exist. Please check RIBO_DB and RIBO_NAME in the configuration file. $(tput sgr 0)"
                                                	exit;
                                                fi
						break;
                                        done
				fi
			else
				echo "$(tput setaf 1)  ERROR: the RIBO_NAME variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                		exit;
			fi
        	fi
        else
                echo "$(tput setaf 1)  ERROR: the RIBO_DB variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                exit;
	fi
fi
	
echo
echo " CONTAMINATING ORGANISMS DATABASES"
if [ $bflag = "true" ]; then
	if [[ ! ( -z "$BACTERIA_DB" )  ]];then
        	if [[ ! ( -d "$BACTERIA_DB" )  ]];then
                	echo "$(tput setaf 1)  ERROR: the BACTERIA_DB path does not exist. Please check the configuration file. $(tput sgr 0)";
                	exit;
        	else
			if [[ ! ( -z "$BACTERIA_NAME" )  ]];then
                                 BACTERIA_IDX=$BACTERIA_DB$SEP$BACTERIA_NAME"*";
                                 
                                 # check for the indexes
                                 for f in $BACTERIA_IDX; do
                                 	if [[ -e "$f" ]];then
                                        	echo "  INFO: the bacteria database named "$BACTERIA_NAME" is located at "$BACTERIA_DB
                                        else    
                                                echo "$(tput setaf 1)  ERROR: the bacteria index and data files do not exist. Please check BACTERIA_DB and BACTERIA_NAME in the configuration file. $(tput sgr 0)"
                                                exit;
                                        fi
                                        break;
                                 done
                         else    
                                 echo "$(tput setaf 1)  ERROR: the BACTERIA_NAME variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                                 exit;
                         fi	
        	fi
        else
                echo "$(tput setaf 1)  ERROR: the BACTERIA_DB variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                exit;
	fi
fi

if [ $fflag = "true" ]; then
	if [[ ! ( -z "$FUNGI_DB" )  ]];then
        	if [[ ! ( -d "$FUNGI_DB" )  ]];then
                	echo "$(tput setaf 1)  ERROR: the FUNGI_DB path does not exist. Please check the configuration file. $(tput sgr 0)";
                	exit;
        	else

 			if [[ ! ( -z "$FUNGI_NAME" )  ]];then
                                 FUNGI_IDX=$FUNGI_DB$SEP$FUNGI_NAME"*";

                                 # check for the indexes
                                 for f in $FUNGI_IDX; do
                                        if [[ -e "$f" ]];then
                                                echo "  INFO: the fungi database named "$FUNGI_NAME" is located at "$FUNGI_DB
                                        else
                                                echo "$(tput setaf 1)  ERROR: the fungi index and data files do not exist. Please check FUNGI_DB and FUNGI_NAME in the configuration file. $(tput sgr 0)"
                                                exit;
                                        fi
                                        break;
                                 done
                         else
                                 echo "$(tput setaf 1)  ERROR: the FUNGI_NAME variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                                 exit;
                         fi
        	fi
        else
                echo "$(tput setaf 1)  ERROR: the FUNGI_DB variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                exit;
	fi
fi

if [ $vflag = "true" ]; then
	if [[ ! ( -z "$VIRUSES_DB" )  ]];then
        	if [[ ! ( -d "$VIRUSES_DB" )  ]];then
                	echo "$(tput setaf 1)  ERROR: the VIRUSES_DB path does not exist. Please check the configuration file. $(tput sgr 0)";
                	exit;
        	else

			if [[ ! ( -z "$VIRUSES_NAME" )  ]];then
                                 VIRUSES_IDX=$VIRUSES_DB$SEP$VIRUSES_NAME"*";

                                 # check for the indexes
                                 for f in $VIRUSES_IDX; do
                                        if [[ -e "$f" ]];then
                                                echo "  INFO: the viruses database named "$VIRUSES_NAME" is located at "$VIRUSES_DB
                                        else
                                                echo "$(tput setaf 1)  ERROR: the viruses index and data files do not exist. Please check VIRUSES_DB and VIRUSES_NAME in the configuration file. $(tput sgr 0)"
                                                exit;
                                        fi
                                        break;
                                 done
                         else
                                 echo "$(tput setaf 1)  ERROR: the VIRUSES_NAME variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                                 exit;
                         fi
        	fi
        else
                echo "$(tput setaf 1)  ERROR: the VIRUSES_DB variable is missing or empty. Please check the configuration file. $(tput sgr 0)";
                exit;
	fi
fi

#### 3. NOW SET THE PARAMETERS AND START THE PIPELINE ####
echo
echo "- PROCESSING STARTED   " 
B2F_param=" "$flagP" "
# fastq2fasta
F2F_param=" "
if [ $flagQ = 1 ]; then
  F2F_param+=$flagQ" "$q_thre" "$p_thre" "$Q_enc" "
else
  F2F_param+=$flagQ" "
fi

#startSortMeRNA param

SMR_param=" "$RIBO_FASTA","$RIBO_IDX" "
# startBlast param
SB_param=" "$bflag" "$fflag" "$vflag" "

# the extension of the files is depending on the input format
SEARCH_ROOT=$fulldir$SEP
SEARCH_PATTERN="*."
SEARCH_PATTERN+=$inputFormat;
SEARCH_PATH=$SEARCH_ROOT$SEARCH_PATTERN
# 3.1  output paths 

# 3.1.1 temp exe dir
CURRENT_DIR=$(pwd);
TEMP_SCRIPT_ROOT=$CURRENT_DIR$SEP
TEMP_SCRIPT_ROOT+="TEMP";
echo "INFO: executable files will be stored in the temporary directory: "$TEMP_SCRIPT_ROOT

#  output results dir. Results are stored into the input dir
# in several different FOLDERS
# 3.1.2
OUTPUT_DIR=$outdir
mkdir $outdir

RESULTS_PATH=$OUTPUT_DIR$SEP
RESULTS_PATH+="RESULTS"
echo "INFO: results will be stored in the output directory: "$RESULTS_PATH 

# script paths
B2F=$SHELL_EXE_DIR$SEP"bam2fastQ.sh"
F2F=$SHELL_EXE_DIR$SEP"fastq2fasta.sh"
SMR=$SHELL_EXE_DIR$SEP"startSortMeRNA.sh"
SB=$SHELL_EXE_DIR$SEP"startBlast.sh"


if [ ! -d "$TEMP_SCRIPT_ROOT" ]; then
  mkdir $TEMP_SCRIPT_ROOT
fi

DIR_INTER=$OUTPUT_DIR$SEP
DIR_INTER+="INTERMEDIATE_FILES"
echo "INFO: intermediate files results will be stored in the output directory: "$DIR_INTER 

if [ ! -d "$DIR_INTER" ]; then
  mkdir $DIR_INTER
fi


DIR_FASTA_OUT=$DIR_INTER$SEP
DIR_FASTA_OUT+="FASTA_FILES"
DIR_FASTQ=$DIR_INTER
DIR_FASTQ+=$SEP"FASTQ_FILES"
# FASTA and FASTQ out dir are created only if the ibnput is not in fasta format
if [[ ! ( $inputFormat = "FASTA") && ! ($inputFormat = "fasta") ]]; then
 echo "INFO: fasta files will be stored in the output directory: "$DIR_FASTA_OUT

 if [ ! -d "$DIR_FASTA_OUT" ]; then
   mkdir $DIR_FASTA_OUT
 fi

 echo "INFO: fastq files will be stored in the output directory: "$DIR_FASTQ
 if [ ! -d "$DIR_FASTQ" ]; then
   mkdir $DIR_FASTQ
 fi
fi

# FASTQ out dir is created only when the input is bam
if [[  ( $inputFormat = "BAM") || ($inputFormat = "bam") ]]; then
 DIR_FASTQ=$DIR_INTER
 DIR_FASTQ+=$SEP"FASTQ_FILES"
 echo "INFO: fastq files will be stored in the output directory: "$DIR_FASTQ
 if [ ! -d "$DIR_FASTQ" ]; then
   mkdir $DIR_FASTQ
 fi
fi

### MAIN LOOP
## to avoid exact matching of the files extension 
shopt -s nocaseglob
# check if there are files in the dir with the specific format
for i in $SEARCH_PATH; do
	if [ -f "$i" ]; then break; 
			else
			  echo "$(tput setaf 1)ERROR!! no files with $inputFormat format in the input path!$(tput sgr 0)"  
			  exit;
	fi
done

for fullfile in $SEARCH_PATH; do
  fname=$(basename "$fullfile")
  dname=$(dirname "$fullfile")
  filename="${fname%.*}"
  
# echo "INFO: processing the file $dname$SEP$fname"

# 3.2  create the script 
  TEMP_SCRIPT=$TEMP_SCRIPT_ROOT$SEP$filename
  TEMP_SCRIPT+="_1.sh"
  echo "#!/bin/bash" > $TEMP_SCRIPT

# 3.2.1) conversion to fastq: launch bam2fastq 
# convert to fastq only if the input format is BAM
 if [[ ($inputFormat = "BAM") || ($inputFormat = "bam") ]]; then  
   echo "#!/bin/bash" > $TEMP_SCRIPT
   EXECUTE_STRING="source "
   EXECUTE_STRING+=$B2F
   EXECUTE_STRING+=" "
   EXECUTE_STRING+=$dname$SEP$fname
   EXECUTE_STRING+=" "
   EXECUTE_STRING+=$SAMTOOLS_EXEC
   EXECUTE_STRING+=" "
   EXECUTE_STRING+=$DIR_INTER
   EXECUTE_STRING+=" "
   EXECUTE_STRING+=$DIR_FASTQ
   EXECUTE_STRING+=" "
   EXECUTE_STRING+=$B2F_param
   echo "$EXECUTE_STRING" >> $TEMP_SCRIPT
  fi

  # 3.2 2) conversion: launch fastq2fasta
  # conversion from fastq to fasta is performed only if the input files are in BAM or in FASTQ format
 if  [[ ! ($inputFormat = "FASTA") && ! ( $inputFormat = "fasta") ]]; then
    FASTQ_FILE=""
	
    if [[ ($inputFormat = "BAM") || ($inputFormat = "bam") ]]; then
      # take the input from the previouus step
      FASTQ_FILE=$DIR_FASTQ$SEP$filename
      FASTQ_FILE+=".fastq"
    else
     # take the files specified by the user
      FASTQ_FILE=$dname$SEP$fname
    fi

    EXECUTE_STRING="source "
    EXECUTE_STRING+=$F2F
    EXECUTE_STRING+=" "
    EXECUTE_STRING+=$FASTQ_FILE
    EXECUTE_STRING+=" "
    EXECUTE_STRING+=$FASTX_EXEC
    EXECUTE_STRING+=" "
    EXECUTE_STRING+=$DIR_FASTA_OUT
    EXECUTE_STRING+=$F2F_param

     echo "$EXECUTE_STRING" >> $TEMP_SCRIPT
  fi
  
 # 3.2.3) 
  # set the file depending from the input format
  FASTA_FILE=""
  if [[  ($inputFormat = "FASTA") || ($inputFormat = "fasta") ]]; then
     FASTA_FILE=$fullfile
  else
   #  DIRS FROM PREVIOUS STEP
   DIR_FASTA=$DIR_FASTA_OUT
   FASTA_FILE=$DIR_FASTA$SEP$filename
   FASTA_FILE+=".fasta"
  fi


  # if ribosomal decont is on, create out dir
  if [ $flagR = 1 ]; then
  DIR_RIBO=$DIR_INTER$SEP
      DIR_RIBO+="RIBO"
      if [ ! -d "$DIR_RIBO" ]; then
        mkdir $DIR_RIBO
      fi
  fi
  #2) ribosomal decontamination: launch sortMeRNa
    if [ $flagR = 1 ]; then
      EXECUTE_STRING="source "
      EXECUTE_STRING+=$SMR
      EXECUTE_STRING+=" "
      EXECUTE_STRING+=$FASTA_FILE
      EXECUTE_STRING+=" "
      EXECUTE_STRING+=$SORTMERNA_EXEC
      EXECUTE_STRING+=$SMR_param
      EXECUTE_STRING+=$DIR_RIBO
      echo "$EXECUTE_STRING" >> $TEMP_SCRIPT
     fi

  #3) bacteria/fungi/viruses decontamination: launch startBlast
  if [ $flagR = 1 ]; then
    # input file is the unaligned output from ribo
    SB_INPUT=$DIR_RIBO$SEP$filename
    SB_INPUT+="_RIBO_UNALIGNED.fasta"
  else
    #input file is the output file from bam2fasta
    SB_INPUT=$FASTA_FILE
  fi
  # launch startBlast
  EXECUTE_STRING="/bin/bash "
  EXECUTE_STRING+=$SB
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$SB_INPUT
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$BLASTN_EXEC
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$BACTERIA_DB$SEP$BACTERIA_NAME
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$FUNGI_DB$SEP$FUNGI_NAME
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$VIRUSES_DB$SEP$VIRUSES_NAME
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$SB_param
  EXECUTE_STRING+=" "
  EXECUTE_STRING+=$RESULTS_PATH
  echo "$EXECUTE_STRING" >> $TEMP_SCRIPT
  # submit job 
  /bin/bash $TEMP_SCRIPT
done
## restores the flag
shopt -u nocaseglob


