### Decontaminer tool : detecting unexpected contamination in unmapped NGS data

Our decontaminer web server is under maintenance, so we are making it available here. Please read the decontaminer publication for more details.

https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-019-2684-x

Compressed folder "decontaMiner_1.4.tar.gz" contains latest version of the tool. **Required databases can be downloaded from link mentioned below.**   

DecontaMiner, a tool to unravel the presence of contaminating sequences among the unmapped reads. It uses a subtraction approach to identify bacteria, fungi and viruses genome contamination. DecontaMiner generates several output files to track all the processed reads, and to provide a complete report of their characteristics. The good quality matches on microorganism genomes are counted and compared among samples. DecontaMiner builds an offline HTML page containing summary statistics and plots. The software is freely available at http://www-labgtp.na.icar.cnr.it/decontaminer.

## Database download link
https://drive.google.com/drive/u/2/folders/1UQCiuUVnS5TpkT0We2AkRVew-km_gR_u

### some updates for database configration settings 

if you have fasta and idx path as listed below

###### fasta path        DB/HUMAN_RNA/rRNA.fasta
###### idx path          DB/HUMAN_RNA/rRNA.idx

You should mention this in configuration file in the following way 

##### RIBO_DB=DB/HUMAN_RNA
##### RIBO_NAME=rRNA

## Download link for example BAM files
https://drive.google.com/drive/u/2/folders/1B9WNJc1cGY_LIi2XGwkQ0h_9916_A8Ij 

## Main scripts
#### (a) decontaMiner.sh 
#### (b) filterBlastInfo.sh and
#### (c) collectInfo.sh


### 

![Image of Decontaminer PipeLine](https://media.springernature.com/full/springer-static/image/art%3A10.1186%2Fs12859-019-2684-x/MediaObjects/12859_2019_2684_Fig1_HTML.png?as=webp)

### Overview of the results

![Image of Decontaminer PipeLine](https://media.springernature.com/full/springer-static/image/art%3A10.1186%2Fs12859-019-2684-x/MediaObjects/12859_2019_2684_Fig5_HTML.png?as=webp)
