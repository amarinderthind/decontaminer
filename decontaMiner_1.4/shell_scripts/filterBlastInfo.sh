#!/bin/bash
#  filterBlastInfo.sh  - see below for details 
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
### START THE FILTERING OF THE MEGABLAST ALIGNMENT FILES CONTAINED IN THE INPUT DIRECTORY 
### UNMAPPED READS ARE FILTERED WITH THE FOLLOWING CRITERIA:
###
### 1) ALIGNMENT QUALITY: a read-organism alignment should satisfy the criteria
###    given in input. i.e. match lenght, number of allowed gap and mismatch.
### 2) ORGANISM QUALITY: a read should align only to a single organism. It is possible
###    to tune the stringency of this match by specifying either a match by genus name
###    (default, less stringent and MANDATORY for VIRUSES) or by species (more stringent
###    suggested for BACTERIA and FUNGI).
### -------
###
### INPUT PARAMS: 
###		1) -i :  inputDirectoryPath [mandatory]: path to the directory containing the 
### 		 	 output files of the megablast alignment step  
###		2) -s : pairing flag [optional with default]: either S or P, default P(aired)
###		3) -V : organism flag [optional with deafult] either V or O, default O(thers)
### 		4) QUALITY FILTERING CRITERIA [optional with default]: integers,
###       		4.1) -l  : MINIMUM MATCH LENGHT (default: query length)
###       		4.2) -g  : NUMBER OF ALLOWED GAPS   (default: zero)
###       		4.3) -m  : NUMBER OF ALLOWED MISMATCHS (deafult: zero)
### --------
### OUTPUT: several folders containg the following files (the name of the files will contain the original sample name)
###   		ALIGNED READS FILE: they satisfy criteria 1 (params 4.1,4.2,4.3)  AND 2 
###   		AMBIGUOUS FILE: they satisfy criteria 1 AND NOT criteria 2
###   		LOW QUALITY READS FILE: they do not satisfy criteria 1
### --------
 

############################################################################################
###############    CODE! DO NOT CHANGE BELOW THIS LINE #####################################
############################################################################################


### 1 - EVALUATE THE INPUT OPTIONS AND VALUES
echo
echo " -- FILTERING BLAST RESULTS  --"
echo
if (($# == 0)); then
  echo "No input parameters!";
  echo " filterBlastInfo.sh -i <inputDirectoryPath> [ filterBlastInfo.sh -h to print the help menu with all the optional parameters]"; exit;
fi
if (($# > 10)); then
  echo "Too many parameters";
  echo " filterBlastInfo.sh -i <inputDirectoryPath> [ filterBlastInfo.sh -h to print the help menu with all the optional parameters]"; exit;

fi

# parameter to pass to the the other scripts
fulldir='' #input file
g='' # number of allowed gaps
l='' # match length
m='' # encoding of the quality stirng. Default is e=33;
s='' # paired end/single end data
V='' # virus/other 
fhelp=false # print the help page

# FOR FURTHER EXTENSION gs='' # genus/species matching  either SP or GE.  Default GE.
while getopts ":hi:g:l:m:s:V:" flag; do
  if [[ ("${OPTARG}" == "-i") ||  ("${OPTARG}" == "-s") || ("${OPTARG}" == "-g") || ("${OPTARG}" == "-l") || ("${OPTARG}" == "-m")  || ("${OPTARG}" == "-V") ]]; then
           echo " Missing one or more input " ;exit; # input cannot be a flag! Raw but effective check
  fi
  case "${flag}" in
    i) fulldir="${OPTARG}" ;;
    g) g="${OPTARG}" ;;
    l) l="${OPTARG}" ;;
    m) m="${OPTARG}" ;;
    s) s="${OPTARG}" ;;
    V) V="${OPTARG}" ;;  
    h) fhelp=true ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
     ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# 1.1 PRINT THE HELP 
 if [ $fhelp = "true" ]; then
echo " USAGE: filterBlastInfo.sh [required parameters] [optional parameters] ";
 echo " REQUIRED PARAMETERS:";
 echo "  -i <inputDirectoryPath> . FULL PATH to the DIRECTORY containing the BLAST table files. ";
 echo "";
 echo " OPTIONAL PARAMETERS:";
 echo "  -s <pairing>. Specifies if the input data is SINGLE  or PAIRED end. Accepted values are: P (for paired end), S (for single end). Default: P.";
 echo "  -g <gap>.  Set the gap number threshold to filter out the BLAST alignments. Default: 0.";
 echo "  -m <mismatch>.  Set the mismatch number threshold to filter out the BLAST alignments. Default: 0.";
 echo "  -l <matchLength>.  Set the match length threshold to filter out the BLAST alignments. Leave it 0 to match on read length. Default: 0.";
 echo "  -V <virusesFlag>. Specifies if input data is from viruses. Accepted values are: V (for Viruses), O (for Other organism). Default: O.";
 echo "";
 echo " OTHER INFO:  " 
 echo "  -h prints this help";
 echo "";
 




exit;
 fi

# 1.2 FATAL ERRORS:
if [[ -z "$fulldir" ]]; then
        echo "Missing input directory";
        echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath> [ filterBlastInfo.sh -h to print the help menu with all the optional parameters] "; exit;
fi

if [[ ! (-d "$fulldir") ]]; then
 echo "ERROR: Wrong input filepath or directory name. ";
 echo "specified directory path  was: $fulldir"
 exit;
fi

# check if num of gap, mismatch and alignment length parameters are numeric
if [[ ! (-z "$g" ) &&  ! ("$g" =~ ^[0-9]+$) ]]; then
        echo "ERROR: number of allowed gap  -g should be numeric.";
        echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath>  [ filterBlastInfo.sh -h to print the help menu with all the optional parameters ] "; exit;
fi

if [[ ! (-z "$m" ) &&  ! ("$m" =~ ^[0-9]+$) ]]; then
        echo "ERROR: number of allowed mismatch -m should be numeric.";
        echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath>  [ filterBlastInfo.sh -h to print the help menu with all the optional parameters ] "; exit;
fi

if [[ ! (-z "$l" ) &&  ! ("$l" =~ ^[0-9]+$) ]]; then
        echo "ERROR: match length parameter -l should be numeric (set it to 0 to use the read length).";
        echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath>  [ filterBlastInfo.sh -h to print the help menu with all the optional parameters ] "; exit;
fi
# paired/single end flag
if [[ ( -z "$s" ) ]]; then
        echo "INFO:  paired/single end flag -s not specified. PAIRED END assumed  (default option).";
else
        if [[ ! ("$s" =~ [pPsS] ) ]]; then
                echo "ERROR: wrong value for paired/single end flag.";
                echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath>  [-s <paired/single end flag (P/S, default P)>] "; exit;
        fi
fi

# organism type flag
if [[ ( -z "$V" ) ]]; then
        echo "INFO:   organism type flag -V not specified. O(thers) assumed  (default option).";
else
if [[ ! ("$V" =~ [OoVv] ) ]]; then
               echo "ERROR: wrong value for  organism type flag";
               echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath>  [-V < organism type flag (V for Viruses, O for others, default O)>] "; exit;
       fi
fi

# FOR FURTHER EXTENSION # genus/species end flag
# FOR FURTHER EXTENSION if [[ ( -z "$gs" ) ]]; then
# FOR FURTHER EXTENSION        echo "INFO:  genus/species organism filtering -G not specified. G(enus) assumed  (default option).";
# FOR FURTHER EXTENSION else
# FOR FURTHER EXTENSION        if [[ ! ("$gs" =~ [gGsS] ) ]]; then
# FOR FURTHER EXTENSION                echo "ERROR: wrong value for genus/species organism filtering flag";
# FOR FURTHER EXTENSION                echo "Usage: filterBlastInfo.sh -i <inputDirectoryPath>  [-G <genus/species organism filtering flag (G/S, default G)>] "; exit;
# FOR FURTHER EXTENSION        fi
# FOR FURTHER EXTENSION fi
#### 2 SET THE FLAG AND OPTIONS AS SPECIFIED IN THE INPUT
echo 
echo "- PROCESSING DETAILS "

#2.1) SET THE QUALITY PARAMETERS 
mL=0
gN=0
mN=0
MLEN="L="
GAPN="G="
MISMN="M="

if [[ ! (-z "$m" ) ]]; then
 mN=$m;
fi

if [[ ! (-z "$g" ) ]]; then
 gN=$m;
fi

if [[ ! (-z "$l" ) ]]; then
 mL=$l;
fi
#
MLEN+=$mL
GAPN+=$gN
MISMN+=$mN

#### 2.2 PAIRED/SINGLE END FLAG
flagP=1; # paired end is the default
if [[ ! ( -z "$s" ) && ("$s" =~ [sS] ) ]]; then
   echo "INFO: processing SINGLE END data";
  flagP=0;
  else
    echo "INFO: processing PAIRED END data.";
fi

PAIR_FLAG=1;
if [[ ("$2" =~ [sS]) ]] ; then
 PAIR_FLAG=0;
fi



# At the moment the uniqueness of the alignment is checked by default against the GENUS
# and the number of the term in the NCBI description used for the matching is determined in the perl script (usually one term
# - the first, namely -for bacteria and fungi, and a variable approach based on the 'phage' or 'virus' words for viruses

#2.3) ORGANISM TYPE: VIRUS/OTHERS (at the moment Bacteria or Fungi)
# The default is others (OTHER_ORGANISM_TYPE_FLAG =1). For Viruses is 0
OTHER_ORGANISM_TYPE_FLAG=1
if [[ ! ( -z "$V" ) && ("$V" =~ [vV] ) ]]; then
   echo "INFO: processing VIRUS alignments";
   OTHER_ORGANISM_TYPE_FLAG=0; # heuristic approach
else
   echo "INFO: processing NON virus alignments"; # genus
fi

# code is left here for future extensions
#2.3) GENUS/SPECIES MATCHING
#consider genes mapping on the same organisms in a per genus (1) or per species (2) fashion. It should always be 2 for VIRUSES 
# corresponds to the number of terms to include in the name when matching for the unique organism
# FOR FURTHER EXTENSIONGE_SP_TERM_NUM=1
# FOR FURTHER EXTENSION if [[ ! ( -z "$gs" ) && ("$gs" =~ [sS] ) ]]; then
# FOR FURTHER EXTENSION   echo "INFO: filtering alignments by SPECIES";
# FOR FURTHER EXTENSION     GE_SP_TERM_NUM=2; # genus + species
# FOR FURTHER EXTENSION  else
# FOR FURTHER EXTENSION    echo "INFO: filtering alignments by GENUS."; # genus.
# FOR FURTHER EXTENSIONfi
# FOR FURTHER EXTENSIOGE_SP_TERM_NUM=1
############################################################################
SEP="/"
# THE EXECUTABLE DIR
SHELL_EXE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# decontaminer root dir
DECO_ROOT_DIR="$(dirname "$SHELL_EXE_DIR" )"


# INPUT PATH
ROOT_DIR=${fulldir%/}
SEP="/"
SEARCH_PATH=$ROOT_DIR$SEP
SEARCH_PATH+="*.table"

# OUTPUT PATH
OUTPUT_PATH=$ROOT_DIR$SEP
OUTPUT_PATH+="COLLECTED_INFO"
# TEMP SCRIPT
CURRENT_DIR=$(pwd)
TEMP_SCRIPT_ROOT=$CURRENT_DIR$SEP
TEMP_SCRIPT_ROOT+='TEMP'


if [ ! -d "$TEMP_SCRIPT_ROOT" ]; then
  mkdir $TEMP_SCRIPT_ROOT
fi

# script paths
CBI=$DECO_ROOT_DIR$SEP
if [ $flagP = 1 ]; then
        CBI+="perl_scripts/collectBlastInfo.pl"
else
        CBI+="perl_scripts/collectBlastInfo_UNP.pl"
fi

if [ ! -d "$OUTPUT_PATH" ]; then
  mkdir $OUTPUT_PATH
fi

for fullfile in $SEARCH_PATH; do
  fname=$(basename "$fullfile")
  dname=$(dirname "$fullfile")
  filename="${fname%.*}"
  

  TEMP_SCRIPT=$TEMP_SCRIPT_ROOT$SEP
  TEMP_SCRIPT_CBI=$TEMP_SCRIPT
  TEMP_SCRIPT_CBI+=$filename
  TEMP_SCRIPT_CBI+="_FBILauncher.sh"

  # create the script
  echo "Processing file $fullfile"

  SP=" "
  # 1) collect blast info:
  echo "#!/bin/bash" > "$TEMP_SCRIPT_CBI"
  EXECUTE_STRING=$CBI$SP$fullfile$SP$OUTPUT_PATH$SP$OTHER_ORGANISM_TYPE_FLAG$SP$MLEN$SP$GAPN$SP$MISMN
  echo $EXECUTE_STRING >> "$TEMP_SCRIPT_CBI"
  /bin/bash "$TEMP_SCRIPT_CBI"
done
