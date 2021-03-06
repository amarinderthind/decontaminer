#!/usr/bin/perl -w
# collectBlastInfo_UNP.pl - FILTERS MEGABLAST ALIGNMENTS for UNAPAIRED READS (see below for details)
# 
#  Copyright (C) 2015-2017,  M. Sangiovanni, ICAR-CNR, Napoli 
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# FILTER ALIGNMENTS APPLYING THE FOLLOWING CRITERIA:
# 1) alignment should match the filtering parameters given in input (i.e. lenght of alignment, number of
# allowed gap and mismatch). See below.
# 2) all reads should match only one organism
# --------
# INPUT: 
#    MEGABLAST ALIGNMENTS FILE: the complete path to the table file generated by megablast
#    [optional] FILTERING CRITERIA: integers, name=value pairs: 
#    	1.1) L=XXX - MINIMUM ALIGNMENT LENGHT (default: query length)
#    	1.2) G=YYY - NUMBER OF ALLOWED GAPS   (default: zero)
#    	1.3) M=ZZZ - NUMBER OF ALLOWED MISMATCHS (deafult: zero)
# --------
# OUTPUT: a directory called "input_file_name"_results containing the following files
#   ALIGNED READS FILE: they satisfy criteria 1 (.1,.2,.3)  AND 2 
#   AMBIGUOUS FILE: they satisfy criteria 1 AND NOT criteria 2
#   LOW QUALITY READS FILE: they do not satisfy criteria 1
# --------
use strict;
use File::Basename;
use File::Spec;	

sub usage
{
  print "\n";
  print "USAGE: ./collectBlastInfo.pl  path_file_in path_file_out organism_type (0 for virus, 1 for bacteria and fungi) [optional match params] \n";
  print "[match params: L=minimum_alignment_length G=allowed_gaps_num M=allowed_mismatch_num] \n";
}


sub verify_optional{

my (@ARGV, $mlen, $gapn, $mismn)=@_;
 
if (@ARGV > 2){
	my $np=scalar(@ARGV);
	for (my $i=1;$i < $np; $i++ ){
	  my $ip=$ARGV[$i];
	  my ($name,$value)=split(/=/,$ip);
	  
	  if (lc $name eq lc 'L' ){
		  if ($value=m/^-?\d+$/){ 
		    $mlen=scalar($value);
	  	} else{
	  			printf "\n WARNING!! Wrong alignment lenght!! Using default value";
	  	}	    
	  }
	  if (lc $name eq lc 'G' ){
	    if ($value=m/^-?\d+$/){ 
		    $gapn=scalar($value);
	  	} else{
	  			printf "\n WARNING!! Wrong gaps number. Using default value";
	  	}	 
	  }
	  if (lc $name eq lc 'M' ){
	   if ($value=m/^-?\d+$/){ 
		    $mismn=scalar($value);
	  	} else{
	  			printf "\n WARNING!! Wrong mismatch number. Using default value";
	  	}	
	  }
	}
}

}
# 
sub alignmentFiltering {

  my ($file_path_in,$hash_subject_summary,$hash_query_summary, $hash_filtered_alignments, $hash_filtered_subjects, $hash_alignments,$hash_low_quality, $hash_query_subj_lookup, $mlen, $gapn, $mismn )=@_;

  #apre il file di input
  open(BLASTP_FILE, $file_path_in) or die "Can't open input file: $!";;
  my @stats; #  numero di alignment inseriti per categoria, match length
  my $total_alignments=0;
  my $lowq_alignments=0;
  my $in_alignments=0;
  my $thre_len=0;
  while (my $line = <BLASTP_FILE>) { 
  $total_alignments++;
 
  #elimina la newline e tutti gli spazi inutili
  $line =~ s/\s+$//;
      
  # estrae i diversi componenti della riga
  my($qseqid,$sseqid, $qlen, $staxids, $salltitles, $pident, $al_length, $mismatch,$gaps, $qstart, $qend, $sstart, $send, $evalue, $bitscore, $nident, $sstrand, $qcovs) = split(/\t/,$line);
     
    
  #1) estrai le info su tutte le query con almeno un allineamento nel blast
      if (!(exists ${$hash_query_summary}{$qseqid})){
          ${$hash_query_summary}{$qseqid}=0;
      }
      ${$hash_query_summary}{$qseqid}=${$hash_query_summary}{$qseqid}+1;
      
  #2) estrai le info sulle subject
      if (!(exists ${$hash_subject_summary}{$sseqid})){
          # crea la nuova e inizializza
          my %hash_info_subject=();
          ${$hash_subject_summary}{$sseqid}=\%hash_info_subject;
	# to account for NCBI names into the orgnaism textual names
  	   my @pieces  = split(/\|/, $salltitles);
           my $num_pieces=scalar(@pieces);
 
           if ($num_pieces > 1) {# fungi dbs often have the whol ncbi-formatted entry before the genus and species name :/    
                 my $ndesc=$pieces[($num_pieces-1)];
                 ${$hash_subject_summary}{$sseqid}{'desc'}=$ndesc;
                   #${$hash_subject_summary}{$sseqid}{'complete_desc'}=$salltitles;
           } else {
                   ${$hash_subject_summary}{$sseqid}{'desc'}=$salltitles;
           }

          ${$hash_subject_summary}{$sseqid}{'count'}=0;
          ${$hash_subject_summary}{$sseqid}{'tax'}=$staxids;
          ${$hash_subject_summary}{$sseqid}{'sstart'}=$sstart;
	  ${$hash_subject_summary}{$sseqid}{'send'}=$send;
      }
      #aggiorna
      ${$hash_subject_summary}{$sseqid}{'count'}=${$hash_subject_summary}{$sseqid}{'count'}+1;
      
      #set the match threshold length
      
       if ($mlen==0) {$thre_len=$qlen;} else {$thre_len=$mlen; }
	  
	  #verifica i criteri di qualità dell'allineamento
      if (($al_length>=$thre_len) && ($mismatch <=$mismn) && ($gaps <=$gapn)) {
          
       #3) conta quanti allineamenti con stesso subject esistono per ogni query
          if (!(exists ${$hash_filtered_alignments}{$qseqid})){
              my %hash_info_query=();
              ${$hash_filtered_alignments}{$qseqid}=\%hash_info_query;
          }
          
          if (!(exists ${$hash_filtered_alignments}{$qseqid}{$sseqid})){
            ${$hash_filtered_alignments}{$qseqid}{$sseqid}=0;
          }
      
          ${$hash_filtered_alignments}{$qseqid}{$sseqid}=${$hash_filtered_alignments}{$qseqid}{$sseqid}+1;
          
        #4) conta per ogni subject quante read ci sono.
          
          if (!(exists ${$hash_filtered_subjects}{$sseqid})){
              ${$hash_filtered_subjects}{$sseqid}=0;
          }
          ${$hash_filtered_subjects}{$sseqid}=${$hash_filtered_subjects}{$sseqid}+1;
          
          
        #5) salva l'alignment in base alla query
          if (!(exists ${$hash_alignments}{$qseqid})){
              my %hash_lines=();
              ${$hash_alignments}{$qseqid}=\%hash_lines;
              
          }
          ${$hash_alignments}{$qseqid}{$in_alignments}=$line;
          $in_alignments++;
          
        
        #6) hash di lookup
          
          #6.1 for each query name, it holds all the possible subjects fulfilling criteria 1
          if (!(exists ${$hash_query_subj_lookup}{$qseqid})){
              my %hash_subjects=();
              ${$hash_query_subj_lookup}{$qseqid}=\%hash_subjects;
          }

          if (!(exists ${$hash_query_subj_lookup}{$qseqid}{$sseqid})){
            ${$hash_query_subj_lookup}{$qseqid}{$sseqid}=0;
          }
        
          ${$hash_query_subj_lookup}{$qseqid}{$sseqid}=${$hash_query_subj_lookup}{$qseqid}{$sseqid}+1;

      } else { # low quality alignments
    #6) salva low quality
              ${$hash_low_quality}{$lowq_alignments}=$line;
              $lowq_alignments++;
      }#endif match
  
  }#endwhile


# Chiude il file.
  close BLASTP_FILE;
    push(@stats,$total_alignments);
    push(@stats,$in_alignments);
    push(@stats,$lowq_alignments);
    push(@stats,$thre_len); #saves also the threshold length
  return @stats;
}

###############
# verifica che il criterio 2 sia soddisfatto
sub uniqueFiltering{

    my ($org_type, $hash_alignments, $hash_query_subj_lookup, $hash_subject_summary, $hash_ambiguous, $hash_aligned,  $hash_read_organism_details)=@_;
    my $num_amb=0;
    my $num_ali=0;
    my @stats=();

    my $flag_ambiguous=0;
    # scorre le query.
    for my $qid (keys (%{$hash_query_subj_lookup})){

        # recupera tutte le informazioni relative alla mia query
        my $ref_h=${$hash_query_subj_lookup}{$qid};
        my %hash_info_query=%{$ref_h};

        my $num_reads=0; # num di alignments per ogni read
	my %hash_genus=();
                        
        # il conto di tutti gli alignment associati alla read che sto elaborando
        foreach my $s_id (keys(%hash_info_query)){
              $num_reads=$num_reads+($hash_info_query{$s_id});
              # verifica che gli organismi siano della stesso genus.
              my $hash_info_subject_ref=${$hash_subject_summary}{$s_id};
              my %hash_info_subject=%{$hash_info_subject_ref};
              my $desc=$hash_info_subject{'desc'};
              # extract genus: it depends on genus_type (1 -> bacteria and fungi, 0 for viruses)
              my $genus='';
              # for bacteria and fungi uniqueness is checked on the genus, that is usually 
              # correctly indicated by the first term of the NCBI genus description
              if ($org_type ==1){
		 my ($term1, @other)=split(/\s+/,$desc);
                 $genus=$term1;
	      } else { #viruses
		# in viruses genus identification is a bit more complicated.
		# we have an euristic (rough but effective) approach in which the 
		# desc string is searched against the "virus" and "phage" word.
		# The genus is everything in desc until (and including) the searched word.
		# The ending comma char ( , ) is also removed
		# If neither phage nor virus are contained, all the desc is kept
		my $genus_part=$desc;
		# search for phage
                if ($desc =~ /phage/i){		
			  my $offs=index(lc($desc), 'phage');
			  $genus_part=substr($desc,0,($offs-1)) . ' phage'; 
		} elsif ($desc =~ /virus/i) {
		#search for virus
			 my $offs=index(lc($desc), 'virus');
                         $genus_part=substr($desc,0,($offs-1)) . ' virus';
		}

		# remove the comma, if there
		if (substr($genus_part,-1) =~ /,/){
                  $genus_part=substr($genus_part,0,-1);
		}	
			
		$genus=$genus_part;
	      }#endelse genus

              #my ($term1 ,$term2, @other)=split(/\s+/,$desc);
              #my $genus='';
              #if ($genus_num ==1){
              #  $genus=$term1; 
              #  } else {
              #  $genus=$term1 . $term2;
              #}#endelse genus
              $hash_genus{$genus}="";
        }
                                 
       # now check: if there is more than one genus -> ambiguous
        my $num_genus= scalar(keys(%hash_genus));
        if ($num_genus > 1) {
            ${$hash_ambiguous}{$qid}='This read maps on more than one ('.$num_genus.') genera ';
            $num_amb=$num_amb+$num_reads;
          } else{
              # le specie su cui mappa è una sola -> ALIGNED! :D :D :D
              my %hash_mapped_species=();
              ${$hash_aligned}{$qid}=\%hash_mapped_species;
              # saves info on reads and subject
             
              my %alignments=%{${$hash_alignments}{$qid}};
 
              foreach my $line_id  (sort(keys (%alignments))) {
                my $line=$alignments{$line_id};

                my ($qseqid,$organism, $qlen, $staxids, $desc, $pident, $al_length, $mismatch,$gaps, $qstart, $qend, $sstart, $send, $evalue, $bitscore, $nident, $sstrand, $qcovs) = split(/\t/,$line);
                ${$hash_aligned}{$qid}{$organism}=''; 
		
		
              	my $hash_info_subject_ref=${$hash_subject_summary}{$organism};
              	my %hash_info_subject=%{$hash_info_subject_ref};

		# to account for NCBI names into the orgnism textual description 
		my @pieces  = split(/\|/, $desc);
                my $num_pieces=scalar(@pieces);
                my $text_desc='';
                if ($num_pieces > 1) {
                        my $ndesc=$pieces[($num_pieces-1)];
                        #elimina la newline e tutti gli spazi inutili per evitare che fallisca lo split sugli spazi 
                        $ndesc =~ s/\s+$//;
                        $ndesc =~ s/^\s+//;
                        $text_desc=$ndesc;}
                else{
                        $text_desc=$desc;
                }
              	my $species='';
		my $others='';	
		# again build the correct description based on the organism type
              	if ($org_type == 1){ # bacteria and fungi
                    my ($term1 ,$term2, $term3, @other_terms)=split(/\s+/,$text_desc);
               	   $species=$term1 . " " . $term2;
                  #special case as always in bioinfo. May happens on some bacteria strains (e.g. Pseudomonas sp. UW4 chromosome...)
                  if (lc($term2) eq "sp."){
                  #if (lc($term2) =~ /sp\./){
                      $species=$species . " " .$term3;
		   } else {
			unshift(@other_terms,$term3); # otherwise $term3 is lost
		   }

                   $others=join(' ',@other_terms);
		 
              	} else { #viruses
 		 # in viruses genus/species identification is a bit more complicated.
                 # we have an euristic (rough but effective) approach in which the 
                 # desc string is searched against the "virus" and "phage" word.
                 # The genus is everything in desc until (and including) the searched word.
                 # The ending comma char ( , ) is also removed
                 # If neither phage nor virus are contained, all the desc is kept
                	my $genus_part=$text_desc;
                        my $desc_rem=' ';
                 	#search for phage
                	if ($text_desc =~ /phage/i){
                          	my $offs=index(lc($text_desc), 'phage');
                          	$genus_part=substr($text_desc,0,($offs-1)) . ' phage';
                                $desc_rem=$desc_rem . substr($text_desc,($offs)); 
                	} elsif ($desc =~ /virus/i) {
                	#search for virus
                         my $offs=index(lc($text_desc), 'virus');
                         $genus_part=substr($text_desc,0,($offs-1)) . ' virus';
                         $desc_rem=$desc_rem . substr($text_desc,($offs));   
                	}	

                	# remove the comma, if there
                	if (substr($genus_part,-1) =~ /,/){
                  		$genus_part=substr($genus_part,0,-1);
                	}

                	$species=$genus_part;
			$others=$desc_rem;

              	} #endelse genus

		if (!(exists ${$hash_read_organism_details}{$qid})){
			my %hash_organisms_counts=();
			${$hash_read_organism_details}{$qid}=\%hash_organisms_counts;
		}

		if (!(exists ${$hash_read_organism_details}{$qid}{$species})){
                        my %hash_details=();
                        ${$hash_read_organism_details}{$qid}{$species}=\%hash_details;
                }
                
		if (!(exists ${$hash_read_organism_details}{$qid}{$species}{$others})){
                 	my %hash_start=();       
			${$hash_read_organism_details}{$qid}{$species}{$others}=\%hash_start;
                }
		
		if (!(exists ${$hash_read_organism_details}{$qid}{$species}{$others}{$sstart})){
                        my %hash_end=();
                        ${$hash_read_organism_details}{$qid}{$species}{$others}{$sstart}=\%hash_end;
                }

		if (!(exists ${$hash_read_organism_details}{$qid}{$species}{$others}{$sstart}{$send})){
                        
                        ${$hash_read_organism_details}{$qid}{$species}{$others}{$sstart}{$send}=0;
                }
                ${$hash_read_organism_details}{$qid}{$species}{$others}{$sstart}{$send}= ${$hash_read_organism_details}{$qid}{$species}{$others}{$sstart}{$send}+1; 
		
		
                #if (!(exists ${$hash_subject_count}{$organism})){
                #${$hash_subject_count}{$organism}=0;
                # }
                # now save the counts of reads falling into a specific organism (subject)  
		#${$hash_subject_count}{$organism}=(${$hash_subject_count}{$organism}+$hash_info_query{$organism});
              } #foreach
              $num_ali=$num_ali+$num_reads;
          } #else 
    } #endfor
  push(@stats,$num_amb);
  push(@stats,$num_ali);
  return @stats;
} #endsub

#####################################################################################################################################
####  MAIN 
#####################################################################################################################################
# controllo i parametri in input

if (@ARGV < 3)
{
  # mancano i parametri di input!!!!!!!!
  print "ERROR!!!!!!! MISSING INPUT PARAMETERS !!!!! \n";
  usage();  # Call subroutine usage()
  exit();   # When usage() has completed execution,
            # exit the program.
} 

my $path_file_in=$ARGV[0];

if (!(-f $path_file_in)) {
    printf "\n ERROR! INPUT FILE PATH WRONG OR FILE NOT EXISTENT";
    usage();  # Call subroutine usage()
    exit();
}

my $path_file_out=$ARGV[1];

my $org_type=$ARGV[2];

if (($org_type < 0) or ($org_type > 1)){
     printf "\n WRONG ORGANISM TYPE!!";
    usage();  # Call subroutine usage()
    exit();
}

#il nome del file
my $compl_filename_in  = basename($path_file_in);
# elimina l'estensione
my ($filename_in, $suffix_in)=split(/\./,$compl_filename_in);

my $dirs  = dirname($path_file_in);

#my @fn_parts=split(/_/,$filename_in);
#my $filename_root_out=$fn_parts[0] . "_" . $fn_parts[$#fn_parts];

# make the results' directory
#my $out_dir_name= "BLAST_INFO";
#my $out_dir_path=File::Spec->catfile( $path_file_out, $out_dir_name);
my $out_dir_path=$path_file_out;

# if does note exist, create it.
if (! (-d $out_dir_path)){ 
   mkdir $out_dir_path or die "Unable to create $out_dir_path";
}

# AMBIGUOUS DIRECTORY 
 my $out_dir_ambiguous= File::Spec->catfile( $path_file_out, "AMBIGUOUS");
# if does not exist, create it.
 if (! (-d $out_dir_ambiguous)){
    mkdir $out_dir_ambiguous or die "Unable to create $out_dir_ambiguous";
    }

# LOW_QUALITY DIRECTORY 
  my $out_dir_low_quality= File::Spec->catfile( $path_file_out, "LOW_QUALITY");
# if does not exist, create it.
   if (! (-d $out_dir_low_quality)){
       mkdir $out_dir_low_quality or die "Unable to create $out_dir_low_quality";
           }

# VALID
  my $out_dir_valid= File::Spec->catfile( $path_file_out, "VALID");
#if does not exist, create it.           
   if (! (-d $out_dir_valid)){
       mkdir $out_dir_valid or die "Unable to create $out_dir_valid";
           }

# ------
# checking the optional parameters

my $mlen=0;
my $gapn=0;
my $mismn=0;


#&verify_optional(@ARGV, \$mlen, \$gapn, \$mismn); 

my $np=scalar(@ARGV);

        for (my $i=3;$i < $np; $i++ ){
          my $ip=$ARGV[$i];
         
          my ($name,$value)=split(/=/,$ip);
          if (lc $name eq lc 'L' ){
                  if ($value=~/^-?\d+$/){
                    $mlen=$value;
                } else{
                                printf "\n WARNING!! Wrong alignment lenght!! Using default value";
                }
          }
          if (lc $name eq lc 'G' ){
            if ($value=~/^-?\d+$/){
                    $gapn=$value;
                } else{
                                printf "\n WARNING!! Wrong gaps number. Using default value";
                }
          }
          if (lc $name eq lc 'M' ){
           if ($value=~/^-?\d+$/){
                    $mismn=$value;
                } else{
                                printf "\n WARNING!! Wrong mismatch number. Using default value";
                }
          }
        }


my $desc='';
if ($mlen==0){
 printf "\nUsing L=read length ";
 $desc="read length";
} else {
 printf "\nUsing L=". $mlen;
 $desc=$mlen;
}
printf " G =".$gapn." M=" .$mismn;

# --- processing file


my %hash_subject_summary=(); # tutti i subjects coinvolti
my %hash_query_summary=(); # tutte le query
my %hash_filtered_alignments=(); # read after 1st criteria filtering
my %hash_filtered_subjects=(); # subjects after 1st filtering
my %hash_alignments=(); # the blast alignment lines after 1st criteria filtering
my %hash_query_subj_lookup=();# for each query name, it holds all the possible subjects fulfilling criteria 1

# OUTPUT 
my %hash_low_quality=(); # low quality BLAST alignments not meeting the filtering criteria 1
my %hash_ambiguous=(); # ambiguous BLAST alignments (not matching criteria 2)

my %hash_aligned_paired =(); # info on the reads with the subjects fulfilling both the quality and the unique criteria
my %hash_read_organism_details=(); # info on the subjects (num of read aligning organised by read id/species/strains


print "\nProcessing...\n";
my @ali_stats=&alignmentFiltering($path_file_in, \%hash_subject_summary,\%hash_query_summary, \%hash_filtered_alignments, \%hash_filtered_subjects, \%hash_alignments, \%hash_low_quality,\%hash_query_subj_lookup, $mlen, $gapn, $mismn);

my @pair_stats=&uniqueFiltering($org_type, \%hash_alignments, \%hash_query_subj_lookup, \%hash_subject_summary, \%hash_ambiguous, \%hash_aligned_paired, \%hash_read_organism_details);

printf  "...done !\n ";
# writes output files

# prepare filenames
my $name_file_out_stats= $filename_in . "_stats.txt";
my $name_file_out_subs= $filename_in . "_subject_counts.txt";
my $name_file_out_alignments=$filename_in . "_alignments.table";
my $name_file_out_ambiguous=$filename_in . "_ambiguous.table";
my $name_file_out_lowquality=$filename_in . "_low_quality.table";
my $name_file_out_ambiguous_stats= $filename_in . "_ambiguous_stats.txt";
my $name_file_out_alignments_stats_species= $filename_in . "_alignments_stats_by_species.txt";

# --------------
 my $num_reads=scalar(keys(%hash_query_summary));
 my $num_filtered_reads=scalar(keys(%hash_query_subj_lookup));
 my $num_valid_reads=scalar(keys(%hash_aligned_paired)); # single end!
 my $num_subjects=scalar(keys(%hash_subject_summary));
 my $num_filtered_subjects=scalar(keys(%hash_filtered_subjects));
 my $valid_subjects=0;

#1.1) file di classificazione delle singole read
# salva info su specie e match count
my %hash_subject_counts=();
my %hash_valid_subjects=();
printf  "\n-------------------- ";
printf  "\n-Writing valid read vs species detailed file ";

$path_file_out = File::Spec->catfile( $out_dir_valid, $name_file_out_alignments_stats_species );
open my $fh_out_amb_spec, '>', "$path_file_out" or die "Can't write new file: $!";

printf $fh_out_amb_spec "Read_id\tOrganism\tAlignment count";

for my $read_id (sort(keys (%hash_read_organism_details))){
  my %hash_organisms_counts=%{$hash_read_organism_details{$read_id}};
  
  for my $species_id (sort(keys (%hash_organisms_counts))){
  
   # saves match counts of each read among the species 
   if (!(exists $hash_subject_counts{$species_id})){
	$hash_subject_counts{$species_id}=0; 
   }
   $hash_subject_counts{$species_id}=$hash_subject_counts{$species_id}+1;
   # 

   # now gets detailed info on the read and its alignment over this organism
   my %hash_details=%{$hash_organisms_counts{$species_id}};


   for my $strain_desc (sort(keys(%hash_details))) {
      my $org_desc= $species_id ." ". $strain_desc;
      $hash_valid_subjects{$org_desc}='';
      
      my %hash_start=%{$hash_details{$strain_desc}};
      
      my $num_homologs=0;
      for my $sstart (keys(%hash_start)){
          my %hash_ends=%{$hash_start{$sstart}};
          for my $send (keys(%hash_ends)){
          	$num_homologs=$num_homologs + $hash_ends{$send};
      	  }
      }
      printf $fh_out_amb_spec "\n$read_id\t$org_desc\t$num_homologs";
   }#endfor strain_desc
  } # endfor species_id
} # endfor read_id


$valid_subjects = scalar(keys(%hash_subject_counts));


close $fh_out_amb_spec;

# 1.2)  match count per subject (da usare per il barplot)
$path_file_out = File::Spec->catfile( $out_dir_valid, $name_file_out_subs );
open my $fh_out_subs, '>', "$path_file_out" or die "Can't write new file: $!";

printf $fh_out_subs "Genus description\tMatch count";

for my $species_id (sort(keys (%hash_subject_counts))){

 	#my %hash_info_subject=%{${hash_subject_summary}{$sub_id}};
 	#my $subj_desc=$hash_info_subject{'desc'};
 
   my $match_count=$hash_subject_counts{$species_id};
   printf $fh_out_subs "\n$species_id\t$match_count";
}

close $fh_out_subs;

####  ALLINEAMENTI 
# 1) file blast con gli allineamenti non ambigui
# 2) file blast con gli allineamenti ambigui
# 3) file blast con gli allineamenti low quality.

 printf  "\n-------------------- ";
 printf  "\n-Writing non ambiguous alignments file ";

$path_file_out = File::Spec->catfile( $out_dir_valid, $name_file_out_alignments);
open my $fh_out_aligns, '>', "$path_file_out" or die "Can't write new file: $!";

printf $fh_out_aligns "qseqid\tsseqid\tqlen\tstaxids\tsalltitles\tpident\tal_length\tmismatch\tgaps\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tnident\tsstrand\tqcovs";

for my $qid (keys (%hash_aligned_paired)){
    my %hash_lines=%{$hash_alignments{$qid}};

    for my $line_n (keys (%hash_lines)){
       printf $fh_out_aligns "\n".$hash_lines{$line_n};
    }
}
close $fh_out_aligns;

 printf  "\n-------------------- ";
 printf  "\n-Writing ambiguous alignments file ";

$path_file_out = File::Spec->catfile( $out_dir_ambiguous, $name_file_out_ambiguous);
open my $fh_out_ambigs, '>', "$path_file_out" or die "Can't write new file: $!";

printf $fh_out_ambigs "qseqid\tsseqid\tqlen\tstaxids\tsalltitles\tpident\tal_length\tmismatch\tgaps\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tnident\tsstrand\tqcovs";

for my $id (keys (%hash_ambiguous)){
 # get all the pair and mate alignments
    
    my %hash_lines=%{$hash_alignments{$id}};

    for my $line_n (keys (%hash_lines)){
       printf $fh_out_ambigs "\n".$hash_lines{$line_n};
    }
    
}
close $fh_out_ambigs;

 printf  "\n-------------------- ";
 printf  "\n-Writing low-quality alignments file ";

$path_file_out = File::Spec->catfile( $out_dir_low_quality, $name_file_out_lowquality);
open my $fh_out_lqual, '>', "$path_file_out" or die "Can't write new file: $!";

printf $fh_out_lqual "qseqid\tsseqid\tqlen\tstaxids\tsalltitles\tpident\tal_length\tmismatch\tgaps\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tnident\tsstrand\tqcovs";

for my $line_n(keys (%hash_low_quality)){
       printf $fh_out_lqual "\n".$hash_low_quality{$line_n};
    
}

close $fh_out_lqual;

 printf  "\n-------------------- ";
 printf  "\n-Writing ambiguous alignments info file ";

$path_file_out = File::Spec->catfile( $out_dir_ambiguous, $name_file_out_ambiguous_stats);
open my $fh_out_astats, '>', "$path_file_out" or die "Can't write new file: $!";

printf $fh_out_astats "Read id\tdescription";

for my $q_id(keys (%hash_ambiguous)){
       printf $fh_out_astats "\n".$q_id ."\t" . $hash_ambiguous{$q_id};
    
}
close $fh_out_astats;


printf  "\n-------------------- ";


printf  "\n-------------------- ";
printf "\n - Overall statistics -";
printf "\n - MLEN=" .$ali_stats[3] .", GAPN=$gapn, MISMN=$mismn -";
printf "\n --------- ALIGNMENTS ---------- ";
printf "\n Total : " .$ali_stats[0];
printf  "\n Low-quality : " .$ali_stats[2];
printf "\n Hi-quality  : " .$ali_stats[1];
printf "\n Ambiguous  : " .$pair_stats[0];
printf "\n VALID  --> " .$pair_stats[1];
printf "\n\n --------- READS ---------- ";
printf "\n Total  : " .$num_reads;
printf "\n Hi-quality  : " .$num_filtered_reads;
printf "\n VALID  : " .$num_valid_reads;
printf "\n\n --------- BLAST SUBJECTS ---------- ";
printf "\n Total : " .$num_subjects;
printf "\n Hi-quality : " .$num_filtered_subjects;
printf "\n VALID : " . $valid_subjects;
printf  "\n-Writing overall statistics file ";

$path_file_out = File::Spec->catfile( $out_dir_path, $name_file_out_stats );
 open my $fh_out_stats, '>', "$path_file_out" or die "Can't write new file: $!";

 printf $fh_out_stats "MLEN\t".$ali_stats[3];
 printf $fh_out_stats "\nGAPN\t$gapn";
 printf $fh_out_stats "\nMISMN\t$mismn";
 printf $fh_out_stats "\nTOTAL_ALIGNMENTS\t".$ali_stats[0];
 printf $fh_out_stats "\nLOW_QUALITY_ALIGNMENTS\t" .$ali_stats[2];
 printf $fh_out_stats "\nHI_QUALITY_ALIGNMENTS\t" .$ali_stats[1];
 printf $fh_out_stats "\nAMBIG_ALIGNMENTS\t" .$pair_stats[0];
 printf $fh_out_stats "\nVALID_ALIGNMENTS\t" .$pair_stats[1];
 printf $fh_out_stats "\nTOTAL_READS\t" .$num_reads;
 printf $fh_out_stats "\nHI_QUALITY_READS\t" .$num_filtered_reads;
 printf $fh_out_stats "\nVALID_READS\t" .$num_valid_reads;
 printf $fh_out_stats "\nTOTAL_BLASTED_ORGANISMS\t" .$num_subjects;
 printf $fh_out_stats "\nHI_QUALITY_BLASTED_ORGANISMS\t" .$num_filtered_subjects;
 printf $fh_out_stats "\nVALID_BLASTED_ORGANISMS\t" . $valid_subjects;

 close $fh_out_stats;

print "\n... finished. \nOutput files written in the directory: "  . $out_dir_path;
print "\n";
exit;
