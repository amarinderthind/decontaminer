#!/usr/bin/perl -w
#  extractBarPlotInfo.pl - Ectract percentage matrix (organism vs sample)from result files (see below for details)
# 
#  Copyright (C) 2015-2017,  M. Sangiovanni, ICAR-CNR, Napoli 
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
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use File::Basename;
use File::Spec;

sub usage
{
  print "\n";
  print "ERROR!!!!!!! MISSING INPUT PARAMETERS !!!!! \n";
  print "USAGE: ./extractBarPlotInfo.pl path_dir_in flag_phil count_thre\n";
}

sub usagect
{
    print "\n";
    print "ERROR!!!!!!! WRONG INPUT PARAMETER !!!!! \n";
    print "count_thres must be numeric ! \n";
}	
# 
sub read_file {

  my ($file_path_in,$hash_counts, $hash_bacteria_names)=@_;

  #apre il file di input
  open(FILE_IN, $file_path_in) or die "Can't open input file: $!";;
    
  my $num_counts=0;
   
   #skip header line
  my $line = <FILE_IN>;
    
  while ( $line = <FILE_IN>) {
   
  #elimina la newline e tutti gli spazi inutili
  $line =~ s/\s+$//;
      
  # estrae i diversi componenti della riga
  my($name,$count) = split(/\t/,$line);
 
  # calculate total counts
      $num_counts=$num_counts + $count;
    
  #1) estrae le info su tutte le query con almeno un allineamento nel blast
      ${$hash_counts}{$name}=$count;
      
  #2) conserva i nomi dei batteri
      ${$hash_bacteria_names}{$name}="";

    
  }#endwhile


# Chiude i files.
  close FILE_IN;
    
  return $num_counts;
}

#####################################################################################################################################
####  MAIN 
#####################################################################################################################################
# controllo i parametri in input

if (@ARGV <3)
{
  # mancano i parametri di input!!!!!!!!
  usage();  # Call subroutine usage()
  exit();   # When usage() has completed execution,
            # exit the program.
}

# la directory passata in input
my $dir = $ARGV[0];
my $desc_phil='';

my $term_num = $ARGV[1];

if ($term_num == 0) {
 $desc_phil="all";
}

if ($term_num == 1) {
 $desc_phil="ge";
}

if ($term_num == 2) {
 $desc_phil="sp";
}

my $count_thre=0;

if ($ARGV[2] >= 0 ) {
    $count_thre = $ARGV[2];
} else {
    usagect();
    exit();
}


my  $fext="subject_summary_". $desc_phil . "_CT_" .$count_thre . ".txt" ;

# apre la dir ed estrae tutti i nomi dei file ge(nus) o sp(ecies) contenuti
opendir(DIR, $dir) or die "Can't open $dir: $!";
my @files = grep {/$fext/ } readdir(DIR);

closedir(DIR);

# estrae info
my %hash_names=(); # tutti i bacteria coinvolti.
my %hash_info_percs=(); #hash di array con le perc per ogni sample
my %hash_info_totals=();

foreach my $filein (@files) {
    my $filename_root="";
 
    my $path_file_in=File::Spec->catfile( $dir, $filein);
    my $compl_filename_in  = basename($filein);
    
    my ($filename_in, $suffix_in)=split(/\./,$compl_filename_in);
   
 # remove the final part of the name (i.e. the RIBO_UNALIGNED_vs_bacteria_subject_summary_sp)
    my $num_suff=7; # accounts for "vs_bacteria_subject_summary_sp_CT_100"
             
    if ($filename_in =~ "RIBO_UNALIGNED"){
       $num_suff=$num_suff+2; # if ribo step present
    }
    
    my @fn_parts=split(/_/,$filename_in);
                                   
    my $numpa=(scalar(@fn_parts)) - $num_suff; #
    
    $filename_root=$fn_parts[0];
    for (my $ni=1; $ni <$numpa; $ni++){
      $filename_root=$filename_root . "_" . $fn_parts[$ni];
    }

    # 1) read the file and stores all names and counts. Calculate total counts.
   
    my %hash_counts=();
    $hash_info_percs{$filename_root}=\%hash_counts;
    
    my $total_count= read_file($path_file_in,  $hash_info_percs{$filename_root},\%hash_names);
    
    $hash_info_totals{$filename_root}=$total_count;
    #print "\n total reads count for sample " . $filename_root . " is : " . $total_count;
    
}# end of file processing

# writes output files
my $out_name= "barPlotInfo_" . $desc_phil . "_CT_" .$count_thre .".txt";
my $out_name_stats="barPlotInfo_STAT_" . $desc_phil . "_CT_" .$count_thre . ".txt";
my $path_file_out = File::Spec->catfile( $dir,$out_name);
my $path_file_out_stats = File::Spec->catfile( $dir,$out_name_stats);
open my $fh_out, '>', "$path_file_out" or die "Can't write new file: $!";
open my $fh_out_stats, '>', "$path_file_out_stats" or die "Can't write new file: $!";

####### TEMPORARY SOLUTION!!! TO BE PASSED IN INPUT IN FURTHER VERSIONS OF THER CODE.
# $TOTAL MAPP_READS_THRESHOLD: defines a lower threshold number for the TOTAL reads mapping to contamining organisms. 
# A file is processed only if the total number of reads is higher than the threshold.
# $SINGLE_MAPP_READS_THRESHOLD: defines a lower threshold number for the  reads mapping to a SINGLE contamining organisms. 
# Prints in output only those organisms on which the number of aligned reads is greater/equal to that threshold
### all data
# thresholds for bacteria
my $TOTAL_MAPP_READS_THRESHOLD=1;


#print "Total reads threshold: $TOTAL_MAPP_READS_THRESHOLD; Single organism read threshold $SINGLE_MAPP_READS_THRESHOLD ";

my @to_be_printed=();
printf $fh_out_stats "SAMPLE NAME\tTOTAL READS\tNUMBER OF MATCHING ORGANISMS\n";

# extract only the files over the threshold
my @fn= sort(keys %hash_info_percs);

foreach my $fname (@fn){
    my $tot_counts=$hash_info_totals{$fname};
   
    if ($tot_counts >= $TOTAL_MAPP_READS_THRESHOLD){
        # print the file name
        printf $fh_out "\t$fname";
	push(@to_be_printed,$fname);
    

    my %hash_counts=%{$hash_info_percs{$fname}};

    my $tot_bnames= scalar (keys %hash_counts);
     # saves the totals into a file
     printf $fh_out_stats "$fname\t$tot_counts\t$tot_bnames\n";
    }
}

close $fh_out_stats;

#extracts only the organisms with reads
my %hash_bnames_to_be_printed=();
my @bnames_arr=sort(keys %hash_names);

my $num_files=scalar(@to_be_printed);

if ($num_files > 0){
foreach my $fname (@to_be_printed){
    my %hash_counts=%{$hash_info_percs{$fname}};
    foreach my $bname (keys %hash_counts){
        # the number of reads mapping on this organism
        my $bact_count=$hash_counts{$bname};
        if ($bact_count >= $count_thre){
                $hash_bnames_to_be_printed{$bname}="";
        } 
                
    }
}



# now prints only the samples and organisms that were filtered out
my %tot_perc=(); # the percentage of readsa above threshold
foreach my $bname (sort(keys %hash_bnames_to_be_printed)){
    printf $fh_out "\n$bname";

    foreach my $fname (@to_be_printed){
        
        my %hash_counts=%{$hash_info_percs{$fname}};
        
        my $bact_count=0;
        my $perc=0;
        if (exists ($hash_counts{$bname}) ){
           $bact_count=$hash_counts{$bname};
           $perc=( $bact_count/ ($hash_info_totals{$fname})) * 100;
	# stores the total percentage of reads for a sample
	    if (exists ($tot_perc{$fname}) ){
		$tot_perc{$fname}=$tot_perc{$fname}+$bact_count;
	    } else {
		$tot_perc{$fname}=$bact_count;
		}
        }
        printf $fh_out "\t".$perc;
    }
 
}

my @others=();
my $othersPresent=0;
my $othersString="\nOthers";
foreach my $fname (@to_be_printed){
   my $tot_reads=$hash_info_totals{$fname};
   my $disp_reads=$tot_perc{$fname};
   my $rem_reads=($tot_reads - $disp_reads);
   printf "\n Processing sample  $fname, with total read counts: $tot_reads,  valid reads: $disp_reads, others reads:  $rem_reads";
   my $oth_perc=0;
   if ($rem_reads > 0){
     $othersPresent=1;
     $oth_perc=( $rem_reads/ $tot_reads) * 100;  
     print " ( $oth_perc  % )";
   }
   $othersString=$othersString."\t$oth_perc";
}

# now prints the total percentage for organisms under threshold
if ($othersPresent==1){
	printf $fh_out $othersString;
}	

close $fh_out;
print "\n... finished. \nOutput files written in the directory: "  . $dir;
} else { 

print "\n WARNING: No output was written Input files do not contain non-zero matches"
}# end if num files > 0

print "\n";
exit;
