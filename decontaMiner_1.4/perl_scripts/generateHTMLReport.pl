#!/usr/bin/perl -w
# generateHTMLReport.pl - parse the result files and build the HTML reports
# 
# Copyright (C) 2015-2017,  M. Sangiovanni, ICAR-CNR, Napoli 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use File::Basename;
use File::Spec;

sub usage
{
  print "\n";
  print "ERROR!!!!!!! MISSING INPUT PARAMETERS !!!!! \n";
  print "USAGE: ./generateHTMLReport.pl path_dir_in path_deco genusFlag thresholdValue \n";
}


sub usagect
{
    print "\n";
    print "ERROR!!!!!!! WRONG INPUT PARAMETER !!!!! \n";
    print "count_thres must be numeric ! \n";
} 
# 

# read the HTML template
sub read_template{
 
  my ($file_path_in)=@_;

  local $/ = undef;
  open FILE, "$file_path_in" or die "Couldn't open file: $!";
  my $string = <FILE>;
  close FILE;
  return $string;
}

sub read_overall_stats{

my  ($stats_filein, $sample_name, $hash_overall_stats)=@_;

 #apre il file di input

  open(FILE_IN, $stats_filein) or die "Can't open input file: $!";;

  my %hash_stats=();
  ${$hash_overall_stats}{$sample_name} =\%hash_stats;

  while (my $line = <FILE_IN>) {
   
  #elimina la newline e tutti gli spazi inutili
  $line =~ s/\s+$//;
      
  # estrae i diversi componenti della riga
  my ($key_stat,$value_stat) = split(/\t/,$line);
  ${$hash_overall_stats}{$sample_name}{$key_stat}=$value_stat;
  }#endwhile


# Chiude i files.
  close FILE_IN;
}

sub read_barplot {

 my ($path_file_in, $bp_sample_names, $bp_organism_names, $bp_data_matrix) = @_;

  #apre il file di input
  open(FILE_IN, $path_file_in) or die "Can't open input file: $!";;

  #get the header line (i.e. the sample names);
  my $line = <FILE_IN>;
  #elimina la newline e tutti gli spazi inutili
  $line =~ s/\s+$//;

  my @names= split(/\t/,$line);
  # remove the first empty element
  @names = grep { $_ ne '' } @names;
  push (@{$bp_sample_names},@names);

  my $idx_org=0;
  ## ora le linee
  while ( $line = <FILE_IN>) {
   
  #elimina la newline e tutti gli spazi inutili
  $line =~ s/\s+$//;
      
  # estrae i diversi componenti della riga
  my ($orgname,@values) = split(/\t/,$line);
  # organism' name
  push(@{$bp_organism_names},$orgname);

  # organism contam. values
  my $idx_sample=0;
  for my $val (@values){

    ${$bp_data_matrix}[$idx_org][$idx_sample]=$val;   
    $idx_sample++;
  }
  $idx_org++;

  }#endwhile
}

sub read_barplot_stats{
  my ($path_file_in_stats,$bp_stats,$bp_count_stats)=@_;

  #apre il file di input
  open(FILE_IN, $path_file_in_stats) or die "Can't open input file: $!";;


#skip header line
  my $line = <FILE_IN>;
    
  while ( $line = <FILE_IN>) {
   
  #elimina la newline e tutti gli spazi inutili
  $line =~ s/\s+$//;
      
  # estrae i diversi componenti della riga
  my($sample_name,$total_reads_count,$total_organism_count) = split(/\t/,$line);
    
  #1) estrae le info su tutte le query con almeno un allineamento nel blast
      ${$bp_stats}{$sample_name}=$total_reads_count;
      ${$bp_count_stats}{$sample_name}=$total_organism_count;

    
  }#endwhile


}

sub read_counts_file {

  my ($file_path_in,$hash_counts)=@_;

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
    
  #1) estrae le info su tutte le query con almeno un allineamento nel blast
      ${$hash_counts}{$name}=$count;
    
  }#endwhile


# Chiude i files.
  close FILE_IN;
    
  return $num_counts;
}

# for rounding without installing Math
sub stround
{
  my ($n, $places) = @_;
  my $abs = abs $n;
  my $val = substr($abs + ('0.' . '0' x $places . '5'),
                   0,
                   length(int($abs)) +
                     (($places > 0) ? $places + 1 : 0)
                  );
  ($n < 0) ? "-" . $val : $val;
}
#####################################################################################################################################
####  MAIN 
#####################################################################################################################################
# controllo i parametri in input

if (@ARGV <4)
{
  # mancano i parametri di input!!!!!!!!
  usage();  # Call subroutine usage()
  exit();   # When usage() has completed execution,
            # exit the program.
}

# la directory passata in input
my $dir_in = $ARGV[0];
my $templates_dir = $ARGV[1];
my $html_out_dir = $ARGV[2];
my $term_num = $ARGV[3]; # 0 for viruses, 1 (genus) or 2 (species) for bacteria and fungi
my $count_thre = $ARGV[4];

#### il path dei file da elaborare 
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

#####  THE FILE PATHS 
#1) the template dir
my $index_template_path= File::Spec->catfile($templates_dir,"index.html"); 
my $singlesample_template_path= File::Spec->catfile($templates_dir,"singlesample.html"); 

#####  LOCATE THE INPUT DATA  #################################################################

##### 1 -  Extract info from the input path
my @dir_parts=split(/\//,$dir_in);
my $num_parts= scalar(@dir_parts);

# 1.1 - the directory structure is like that: {path_input}/RESULTS/{organism_type}/COLLECTED_INFO/VALID
my $j=($num_parts - 3); # the {organism_type} index in the array

# 1.2 - the per sample statistics filepath
my $path_stats = join('/', @dir_parts[0..($j+1)]);

# 1.3  the organism type
my $organism_type=$dir_parts[$j];

# 1.4 - the overall statistics files
my $stats_fext= "_vs_". lc($organism_type) ."_stats.txt";
opendir(DIR, $path_stats) or die "Can't open $path_stats: $!";
my @allstats_files = grep {/$stats_fext/ } readdir(DIR);

closedir(DIR);

# 1.5 - total number of processed samples and first error check
my $tot_samples_num=scalar(@allstats_files);
if ( $tot_samples_num == 0) {
  printf "\n ERROR !! NO FILES IN THE DIRECTORY: "  . $path_stats;
  exit;
}

# 1.6 - the per species stats files
my  $fext="subject_summary_". $desc_phil . "_CT_" .$count_thre . ".txt" ;


opendir(DIR, $dir_in) or die "Can't open $path_stats: !";
my @files = grep {/$fext/ } readdir(DIR);
closedir(DIR);
# second error check
my $tot_spec=scalar(@files);
if ( $tot_spec == 0) {
  printf "\n ERROR !! NO FILES IN THE INPUT DIRECTORY: "  . $dir_in;
  exit;
}

# 1.7 the barplot files
my $in_name= "barPlotInfo_" . $desc_phil . "_CT_" .$count_thre .".txt";
my $in_name_stats="barPlotInfo_STAT_" . $desc_phil . "_CT_" .$count_thre . ".txt";
my $path_file_in = File::Spec->catfile($dir_in,$in_name);
my $path_file_in_stats = File::Spec->catfile($dir_in,$in_name_stats);

##### 2 - LOAD THE DATA  ########################################################################

# 2.1 - overall statistics files
my %hash_overall_stats=();
foreach my $stats_filein (@allstats_files) {
    my $filename_root="";
 
    my $stats_complete_filepath=File::Spec->catfile($path_stats, $stats_filein);
    my $compl_filename_in  = basename($stats_filein);
    
    # 2.1.1 - recovers the sample name
    my ($filename_in, $suffix_in)=split(/\./,$compl_filename_in);
   
    # remove the final part of the name (i.e. the RIBO_UNALIGNED_vs_bacteria_subject_summary_sp)
    my $num_suff=3; # accounts for "vs_fungi_stats"
             
    if ($filename_in =~ "RIBO_UNALIGNED"){
       $num_suff=$num_suff+2; # if ribo step present
    }
    
    my @fn_parts=split(/_/,$filename_in);
                                   
    my $numpa=(scalar(@fn_parts)) - $num_suff; #
    
    $filename_root=$fn_parts[0];
    for (my $ni=1; $ni <$numpa; $ni++){
      $filename_root=$filename_root . "_" . $fn_parts[$ni];
    }

    # 2.1.2 - load the data into the hash 
    &read_overall_stats($stats_complete_filepath,$filename_root,\%hash_overall_stats);
}

# 2.1.3 the total number of processed samples (i.e. files)
my @stats_keys= keys(%hash_overall_stats);
my $tot_samples=scalar(keys(%hash_overall_stats));
# 2.1.4 filtering parameters
my $first_element_name=$stats_keys[0];
my %first_element=%{$hash_overall_stats{$first_element_name}};

my $mlen=$first_element{'MLEN'};
my $gapn=$first_element{'GAPN'};
my $mismn=$first_element{'MISMN'};

# 2.2 - the barplot files and stats
my @bp_sample_names=();
my @bp_organism_names=();
my @bp_data_matrix=();

#  2.2.1 - The barplot load the data into the structures 
&read_barplot($path_file_in,\@bp_sample_names,\@bp_organism_names,\@bp_data_matrix);

my %bp_stats=();
my %bp_count_stats=();
&read_barplot_stats($path_file_in_stats,\%bp_stats,\%bp_count_stats);

my @bp_stats_sample_names=sort(keys(%bp_stats));

my $num_ST=scalar(@bp_stats_sample_names);
my $num_BP=scalar(@bp_sample_names);

if (!( $num_ST == $num_BP )){
  printf "\n ERROR !! THE NUMBER OF FILES IN THE barPlotInfo file (".$num_BP.") IS DIFFERENT FROM THE ONE IN barPlotInfo_STAT_ file!!! (".$num_ST.",)";
  exit;
} 


# 2.3 - the single sample count files 

my %hash_info_percs=(); #hash con le perc per ogni sample

foreach my $filein (@files) {
    my $filename_root="";
 
    my $path_file_in=File::Spec->catfile( $dir_in, $filein);
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

    # load only not empty files (i.e. the ones contained in the barplot ) 
    if (exists($bp_stats{$filename_root})) {
      # 1) read the file and stores all names and counts. Calculate total counts.
     
      my %hash_counts=();
      $hash_info_percs{$filename_root}=\%hash_counts;
      
      &read_counts_file($path_file_in, $hash_info_percs{$filename_root});
      
    
    }
}# end of file processing

##### 3 - PROCESS THE DATA AND CREATE THE DATA STRINGS 

# 3.1 the css and js paths
my $css_path= File::Spec->catfile($templates_dir, "css");
my $js_path= File::Spec->catfile($templates_dir, "js");

# the gruping type

my $grouping_type='';

# 3.2.1 set the grouping type.
if ($term_num == 0) {
 $grouping_type="GENUS";
}

if ($term_num == 1) {
 $grouping_type="GENUS";
}

if ($term_num == 2) {
 $grouping_type="SPECIES";
}


# 3.2THE OVERVIEW DATA

# recover from percentages the read counts
# i.e. $new_data= (($data_matrix{i}{j} * num_reads_i)/100) 
my @bm_data_matrix=();

my $num_org=scalar(@bp_organism_names);

for (my $idx_sample=0; $idx_sample < $num_BP ; $idx_sample++){
  
  my $this_sample=$bp_sample_names[$idx_sample];
  my $num_reads_sample=$bp_stats{$this_sample};
  for (my $idx_org=0; $idx_org < $num_org; $idx_org++){
    $bm_data_matrix[$idx_org][$idx_sample] = &stround( ((($bp_data_matrix[$idx_org][$idx_sample]) * $num_reads_sample) /100), 0);

 }
}


# the sample names
my $xaxis = "[\'" . join("\',\'", @bp_sample_names) . "\']";

# sample_num  convenience array
my @id_columns=0..($num_BP-1);

my $overviewData="[";


# for genus statistics - and always for viruses - the info don't need to be grouped (in the overview balls map)
if (($term_num == 0) || ($term_num == 1)) {
  # for each organism
  for (my $idx_org=0; $idx_org < $num_org; $idx_org++){
    # for each sample
    $overviewData=$overviewData . "{\"nsamples\": [";
    my $total_reads=0;
      for (my $idx_sample=0; $idx_sample < $num_BP ; $idx_sample++){
        $overviewData=$overviewData . "[" ;
        $overviewData=$overviewData . ($id_columns[$idx_sample]) . "," . ($bm_data_matrix[$idx_org][$idx_sample]) . "," . $idx_org;;
        $overviewData=$overviewData . "]," ;
        $total_reads=$total_reads + ($bm_data_matrix[$idx_org][$idx_sample]);
      }#endfor

      $overviewData=$overviewData . "],\"total\":". $total_reads . ", \"name\":" . "\"". $bp_organism_names[$idx_org] . "\"". ", \"labname\":" . "\"". $bp_organism_names[$idx_org] . "\""."},";
  }#endfor
} else {

    # for species grouping 
    my %tot_genus=(); 
    my %genus_index=();
     # calculate the total across the samples for each genus
    for (my $idx_sample=0; $idx_sample < $num_BP ; $idx_sample++){
        my %tot_genus_per_sample=();
        $tot_genus{$idx_sample}=\%tot_genus_per_sample;

        for (my $idx_org=0; $idx_org < $num_org; $idx_org++){
        # extract the first term (the genus)
        my ($genus_term, $rest)=  split(/\s/,$bp_organism_names[$idx_org]);
        
          if (exists($tot_genus{$idx_sample}{$genus_term})){
              $tot_genus{$idx_sample}{$genus_term}= ($tot_genus{$idx_sample}{$genus_term}) + ($bm_data_matrix[$idx_org][$idx_sample]); 
          }
          else{
                $tot_genus{$idx_sample}{$genus_term}= $bm_data_matrix[$idx_org][$idx_sample]; 
                $genus_index{$idx_org}=$genus_term;
          }
        }
    }
    # now build the strings
      # for each organism
      my $capital='';
      my $org_name='';
      my $line_num=0; # added to the data to use in js tooltip 
      for (my $idx_org=0; $idx_org < $num_org; $idx_org++){

        my $total_reads=0;
        
        # new genus
        if (exists($genus_index{$idx_org})){
          $org_name= $genus_index{$idx_org};
          $capital=substr($org_name,0,1);
          $overviewData=$overviewData . "{\"nsamples\": [";
          for (my $idx_sample=0; $idx_sample < $num_BP ; $idx_sample++){
              # get the info for the sample and organism
              my $count_per_genus_and_sample=$tot_genus{$idx_sample}{$org_name};
              $overviewData=$overviewData . "[" ;
              $overviewData=$overviewData . ($id_columns[$idx_sample]) . "," . $count_per_genus_and_sample . "," . $line_num;
              $overviewData=$overviewData . "]," ;
              $total_reads=$total_reads + $count_per_genus_and_sample;
            }#endfor
            $overviewData=$overviewData . "],\"total\":". $total_reads . ", \"name\":" . "\"". $org_name . "\"". ", \"labname\":" . "\"". $org_name . "\""."},";
            $line_num=$line_num+1;
        }#endif

        $total_reads=0;
        # now process the normal line 
        $overviewData=$overviewData . "{\"nsamples\": [";
        for (my $idx_sample=0; $idx_sample < $num_BP ; $idx_sample++){
          $overviewData=$overviewData . "[" ;
          $overviewData=$overviewData . ($id_columns[$idx_sample]) . "," . ($bm_data_matrix[$idx_org][$idx_sample]) . ',' . $line_num;
          $overviewData=$overviewData . "]," ;
          $total_reads=$total_reads + ($bm_data_matrix[$idx_org][$idx_sample]);
        }#endfor
        # change the genus name using the foirst capital letter
        my $final_name=$bp_organism_names[$idx_org];
        my $short_name= $capital . ".";
        $final_name =~ s/$org_name/$short_name/;
              
        #$overviewData=$overviewData . "],\"total\":". $total_reads . ", \"name\":" . "\"". $final_name . "\"". "},";  
        $overviewData=$overviewData . "],\"total\":". $total_reads . ", \"name\":" . "\"". $bp_organism_names[$idx_org]. "\"".  ", \"labname\":" . "\"". $final_name . "\"".   "},";  

        $line_num=$line_num+1;
    }#endfor 
}#endelse

$overviewData=$overviewData . "];";

# 3.2.3 the HEATMAP DATA 

my $heatmapRows= "[\"" . join("\",\"", @bp_organism_names) . "\"]";
my $heatmapCols= "[\"" . join("\",\"", @bp_sample_names) . "\"]";

my $heatMapData="[";



for (my $idx_org=0; $idx_org < (scalar(@bp_organism_names)); $idx_org++){
  
  for (my $idx_sample=0; $idx_sample < (scalar(@bp_sample_names)); $idx_sample++){
    $heatMapData= $heatMapData. "{";
    $heatMapData= $heatMapData . "row:" . ($idx_org +1 ). ",";
    $heatMapData= $heatMapData . "col:" .  ($idx_sample + 1). ",";
    $heatMapData= $heatMapData . "value:" . &stround( $bp_data_matrix[$idx_org][$idx_sample], 2);
    $heatMapData= $heatMapData . "}";
    $heatMapData= $heatMapData . ",";
  }
} 

$heatMapData= $heatMapData . "]";

##### 4 - LOAD THE INDEX TEMPLATE AND SUBSTITUTE THE STRINGS

#4.1 THE INDEX PAGE AND THE PAGE NAMES
my $index_tmpl_string=&read_template($index_template_path);
my $out_name_index= "index_" . $desc_phil . "_CT_" .$count_thre .".html";
# create the directory for the sample pages
my $samples_dirname="SAMPLES_HTML_PAGES_" . $desc_phil . "_CT_" .$count_thre;
my $path_file_out_dir = File::Spec->catfile($html_out_dir,$samples_dirname);

my $samples_dirname_withsep=File::Spec->catfile($path_file_out_dir,'');


# 4.2 the js and css paths, the sample page name, the grouping type
$index_tmpl_string =~ s/_HTML_DECO_PATH_CSS_/$css_path/g;
$index_tmpl_string =~ s/_HTML_DECO_PATH_JS_/$js_path/g;
$index_tmpl_string =~ s/_GROUPING_TYPE_/$grouping_type/;
$index_tmpl_string =~ s/_GROUP_SYMB_/$desc_phil/;
$index_tmpl_string =~ s/_MC_THRESH_/$count_thre/;
$index_tmpl_string =~ s/_SAMPLE_DIR_/$samples_dirname_withsep/;

# 4.3 the stats and info
$index_tmpl_string =~ s/_ORGANISM_TYPE_/$organism_type/;
$index_tmpl_string =~ s/_TOT_PROC_SAMPLES_/$tot_samples/;
$index_tmpl_string =~ s/_TOT_CONT_SAMPLES_/$num_BP/;

$index_tmpl_string =~ s/_MATCH_LEN_/$mlen/;
$index_tmpl_string =~ s/_GAP_NUM_/$gapn/;
$index_tmpl_string =~ s/_MISM_NUM_/$mismn/;
$index_tmpl_string =~ s/_MC_THRESH_/$count_thre/;

# 4.4 THE OVERVIEW DATA

$index_tmpl_string =~ s/_OVERVIEW_XAXIS_/$xaxis/;
$index_tmpl_string =~ s/_OVERVIEW_DATA_/$overviewData/;

# 4.5 THE HEATMAP DATA

$index_tmpl_string =~ s/_HEATMAP_DATA_/$heatMapData/;
$index_tmpl_string =~ s/_HEATMAP_ROWS_/$heatmapRows/;
$index_tmpl_string =~ s/_HEATMAP_COLS_/$heatmapCols/;


##### 5 - WRITE THE INDEX OUTPUT FILE

my $path_file_out_index = File::Spec->catfile($html_out_dir,$out_name_index);

open my $fh_out, '>', "$path_file_out_index" or die "Can't write new file: $!";
print $fh_out $index_tmpl_string;
close $fh_out;

# 6 READ THE TEMPLATE OF THE SUBSAMPLE PAGES AND SUBSTITUTE THE STRINGS

my $sample_tmpl_string=&read_template($singlesample_template_path);

# generates a page for each sample
for my $sample_name (@bp_sample_names) {
 #printf("\n mah $sample_name");
  # copy the template  
  my $new_sample_tmpl_string=$sample_tmpl_string;

  #  statistics
  my %sample_info=%{$hash_overall_stats{$sample_name}};
  
  my $tot_ali=$sample_info{'TOTAL_ALIGNMENTS'};
  my $low_ali=$sample_info{'LOW_QUALITY_ALIGNMENTS'};
  my $hi_ali=$sample_info{'HI_QUALITY_ALIGNMENTS'};
  my $ambig_ali=$sample_info{'AMBIG_ALIGNMENTS'};
  my $valid_ali=$sample_info{'VALID_ALIGNMENTS'};
  my $tot_re=$sample_info{'TOTAL_READS'};
  my $hi_re=$sample_info{'HI_QUALITY_READS'};
  my $valid_re=$sample_info{'VALID_READS'};
  my $tot_org=$sample_info{'TOTAL_BLASTED_ORGANISMS'};
  my $hi_org=$sample_info{'HI_QUALITY_BLASTED_ORGANISMS'};
  my $valid_org=$sample_info{'VALID_BLASTED_ORGANISMS'};
  my $valid_org_MC=$bp_count_stats{$sample_name};


  # 6.2 substitute the strings 
  # the main page address
  $new_sample_tmpl_string =~ s/_MAIN_PAGE_PATH_/$path_file_out_index/;
  $new_sample_tmpl_string =~ s/_HTML_DECO_PATH_CSS_/$css_path/g;
  $new_sample_tmpl_string =~ s/_HTML_DECO_PATH_JS_/$js_path/g;
  $new_sample_tmpl_string =~ s/_SAMPLE_NAME_/$sample_name/;
  # table data
  $new_sample_tmpl_string =~ s/_TOTAL_AL_/$tot_ali/;
  $new_sample_tmpl_string =~ s/_LOW_QUALITY_AL_/$low_ali/;
  $new_sample_tmpl_string =~ s/_HI_QUALITY_AL_/$hi_ali/;
  $new_sample_tmpl_string =~ s/_AMBIGUOUS_AL_/$ambig_ali/;
  $new_sample_tmpl_string =~ s/_VALID_AL_/$valid_ali/;
  $new_sample_tmpl_string =~ s/_TOTAL_RE_/$tot_re/;
  $new_sample_tmpl_string =~ s/_HI_QUALITY_RE_/$hi_re/;
  $new_sample_tmpl_string =~ s/_VALID_RE_/$valid_re/;
  $new_sample_tmpl_string =~ s/_TOTAL_OR_/$tot_org/;
  $new_sample_tmpl_string =~ s/_HI_QUALITY_OR_/$hi_org/;
  $new_sample_tmpl_string =~ s/_VALID_OR_/$valid_org/;
  $new_sample_tmpl_string =~ s/_VALID_OR_MC_/$valid_org_MC/;
  


  my %single_sample_counts=%{$hash_info_percs{$sample_name}};
  my $pie_chart_data= " \"name\": \"flare\",\"description\": \"flare\", \"children\": [ ";


  # for genus statistics - and always for viruses - the info don't need to be grouped
  if (($term_num == 0) || ($term_num == 1)) {
   for my $org_name (keys(%single_sample_counts)){
   my $org_count=$single_sample_counts{$org_name};
    $pie_chart_data=$pie_chart_data . "{\"name\" : \" " . $org_name . "\", \"description\": " . "\" Match Counts (MC): " . "\", \"size\": " . $org_count . " },";     
    }#endfor
  } else{

    my $prev_genus=" ";

    for my $org_name (sort(keys(%single_sample_counts))){
      my $org_count=$single_sample_counts{$org_name};
      my $capital=substr($org_name,0,1);
      # extract the first term (the genus)
      my ($genus_term, @rest)=  split(/\s/,$org_name);
      my $rest_string=join(" ",@rest);
      if ($genus_term eq $prev_genus){
        # insert a new child
        $pie_chart_data=$pie_chart_data . "{\"name\" : \" " . $capital . ". ". $rest_string . "\", \"description\": " . "\" Match Counts (MC): " . "\", \"size\": " . $org_count . " },"; 
      } else {
        if (!($prev_genus eq " ")){
          # closes the previous child
          $pie_chart_data=$pie_chart_data . "]},";
        }
        #create the genus and the child
        $pie_chart_data=$pie_chart_data . "{\"name\" : \" " . $genus_term . "\", \"description\": " . "\" Total Match Counts (MC)" . "\", "; 
        $pie_chart_data=$pie_chart_data . "\"children\": [";
        $pie_chart_data=$pie_chart_data . "{\"name\" : \" " . $capital . ". " . $rest_string . "\", \"description\": " . "\" Match Counts (MC): " . "\", \"size\": " . $org_count . " },";     
        #saves the current genus
        $prev_genus=$genus_term;
      }
      # closes the last child
      #$pie_chart_data=$pie_chart_data . "]";
      #
  

      #$pie_chart_data=$pie_chart_data . "\"children \": [";
      #$pie_chart_data=$pie_chart_data . "{\"name\": " . $org_name . ", \"description\": " . "\"MC on this organism " .  $org_count . "\", ";
      #$pie_chart_data=$pie_chart_data . "\"size\": " . $org_count . "}, ";
    }#endfor
    $pie_chart_data=$pie_chart_data . "]},";

  }#endelse
  $pie_chart_data=$pie_chart_data . "]";

  $new_sample_tmpl_string =~ s/_PIE_CHART_DATA_/$pie_chart_data/;

  my $out_name_sample=$sample_name."_" . $desc_phil . "_CT_" .$count_thre . ".html";
  my $path_file_out_sample = File::Spec->catfile($path_file_out_dir,$out_name_sample);
  open my $fh_out, '>', "$path_file_out_sample" or die "Can't write new file: $!";
  print $fh_out $new_sample_tmpl_string;
  close $fh_out;
}


exit;
