#!/usr/bin/perl -w
#  mineMicrobialData.pl - parse the result files toextract only organisms having count > threshold
#  
#  Copyright (C) 2015-2017,  M. Sangiovanni, ICAR-CNR, Napoli 
# 
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  use strict;
  use File::Basename;
  use File::Spec;
  no warnings 'uninitialized';
	
sub usage
{
  print "\n";
  print "ERROR!!!!!!! MISSING INPUT PARAMETERS !!!!! \n";
  print "USAGE: ./mineMicrobialData.pl  path_file_in term_num count_thre (>0).  \n";
}


sub usagethr
{
    print "\n";
    print "ERROR!!!!!!! WRONG INPUT PARAMETER !!!!! \n";
    print " The match count threshold must be >= than 0  \n";
}
# 
sub extract_info {

  my ($file_path_in,$term_num, $hash_out)=@_;

  #apre il file di input
  open(SUBJ_FILE, $file_path_in) or die "Can't open input file: $!";;
    
  my $num_lines=0;
  my $flh=1;
  while (my $line = <SUBJ_FILE>) {
    if ($flh==1){
        $flh =0; #skip first line!
    } else {
          
       $num_lines++;
 
       #elimina la newline e tutti gli spazi inutili
       $line =~ s/\s+$//;
       my $ssname='';    
       # estrae i diversi componenti della riga
       my($desc,$count) = split(/\t/,$line);

       if ($term_num == 0) {# viruses!
        	$ssname=$desc;
       } else { #bacteria and fungi
          # extract the first two words of each description. They corrispond to genus and species 
          # a third term is also considered to check for "sp" string into the name
          my ($term1 ,$term2, $term3, @other)=split(/\s+/,$desc);
          #print "\n $desc e $count; $term1 e $term2";
         
          if ($term_num == 2){ # two terms, genus and species
              $ssname=$term1 . " " . $term2;
	      if (lc($term2) =~ /sp\./){ # accounts for species nomenclature
                     $ssname=$ssname . " " . $term3;
              }
          } else { # one term, only genus
                $ssname=$term1;     
          }
      } #endelse bacteria

  if (!(exists ${$hash_out}{$ssname})){
       ${$hash_out}{$ssname}=$count;
  } else{        
      ${$hash_out}{$ssname}=${$hash_out}{$ssname}+$count;
      }
    }#endif first line

 }#endwhile


# Chiude i files.
  close SUBJ_FILE;
    
  return $num_lines;
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

my $term_num = $ARGV[1];

my $desc_phil='';
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
    usagethr();
    exit();
}

my $path_file_in=$ARGV[0];
#name is the same but with appended "_summary" and the flag used
my $path_file_out=$path_file_in;
my $namestr="subject_summary_" . $desc_phil . "_CT_" .$count_thre;
$path_file_out =~ s/subject_counts/$namestr/;

# estrae info
my  %hash_out=(); # tutti i subjects coinvolti

#print "\nProcessing file $path_file_in ...\n";
my $num_lines=&extract_info($path_file_in,$term_num, \%hash_out);
#printf  "...done !\n ";
# writes output files
# overall stats
#printf  "\n-Writing overall statistics file ";
open my $fh_out, '>', "$path_file_out" or die "Can't write new file: $!";
printf $fh_out "Species name\tCount";
#alph order: my @sk = sort {lc $a cmp lc $b} (keys(%hash_out));
my @sk = sort {$hash_out{$b} <=> $hash_out{$a}} (keys(%hash_out));
for my $sname (@sk){
    my $count=$hash_out{$sname};
  # if the count (ie the number of reads) is greather than the threshold -> process the genus and species
    if ($count >= $count_thre){
    printf $fh_out "\n$sname\t$count";
    }
}

close $fh_out;
#print "... finished. \nOutput file written.";
#print "\n";
exit;
