#!/bin/bash
#START=$(date +%s)
#INPUT="/home/erik/Data_Erik/1_current-projects/deep_sequencing/2017_05_barcodes_Mirjam_89393/03_merged/merged.fastq"
#INPUT="./data/reads_100k.fastq.gz"
#OUTPUT="test.cmp.fastq"
print_usage() {
	echo "Compress Multiplex Barcode Deep-Sequencing data"
	echo ""
	echo "OPTIONS:"
	echo "-i, -input"
	echo "	fastq file unzipped or gzipped"
	echo "-o, -output"
	echo "	output file containing the compressed barcode data"
	echo "-t, -threads"
	echo "	OPTIONAL: number of threads to be used, default 4"
	echo "-h, -help"
	echo "	print help message and exit"
	echo "-v, -version"
	echo "	print version of the program and exit"
}
# ./original-script.sh -i ./data/reads_100k.fastq -o test.fq
# https://stackoverflow.com/questions/18414054/bash-getopts-reading-optarg-for-optional-flags
if [[ "$1" =~ ^((-{1,2})([Hh]$|[Hh][Ee][Ll][Pp])|)$ ]];
then
	print_usage; exit 1
else
	while [[ $# -gt 0 ]];
	do
		opt="$1"
		shift;
		current_arg="$1"
		if [[ "$current_arg" =~ ⁻{1,2}.* ]];
		then
			echo "ERROR: You left an argument blank."; exit 1
		fi
		case "$opt" in
			"-i"|"-input" 	) INPUT="$1"; shift;;
			"-o"|"-output"	) OUTPUT="$1"; shift;;
			"-t"|"-threads"	) THREADS="$1"; shift;;
			"-v"|"-version"	) echo "version 0.1"; exit 0;;
			*				) echo "ERROR: Invalid option: \""$opt"\"" >&2
							  exit 1;;
		esac
	done
fi

if [[ "$INPUT" == "" ]];
then
	echo "ERROR: Option [-i, -input] requires an argument." >&2; exit 1
fi

if [[ "$OUTPUT" == "" ]];
then
	echo "ERROR: Option [-o, -output] requires an argument." >&2; exit 1
fi

if [[ "$THREADS" == "" ]];
then
	# number of threads is not set, defaulting to 4 threads
	THREADS=4
elif [[ "$THREADS" -gt 33 ]]; 
then
	echo "WARNING: Option [-t, -threads] is set to $THREADS"
	echo "Are you sure your system supports that?"
else
	case "$THREADS" in
		(*[!0-9]*|'') echo "ERROR: Option [-t, -threads] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi

# See if input file exists otherwise exit
#if [ -f $INPUT ]
#then
	#echo "File exists, continue"
#	continue
#else
#	echo "Error: $INPUT does not exists"
#	exit
#fi

# check 4th line
# cat $INPUT | head -4 | tail -1

# Check if file is gzipped
#case "$INPUT" in
#	*.gz | *.zip) echo "File is gzipped";;
#	*.bz2) echo "File is BZIP2 compressed";; # bzip2 -df $INPUT
#	*.fastq | *.fa | *.txt) echo "File is not zipped";;
#	*) echo "Error: unsuported file type";;
#esac

# retrieve the sequences only
zcat -c $INPUT | awk 'NR == 0 || NR % 4 == 2' > out_1.out
# sort the sequences --parallel stands for the usable cores (do not set this to high..)
sort --parallel=32 out_1.out > out_2.out
# only report duplicate lines and count the number of occurrences,
# in effect get rid of singletons
uniq -d -c out_2.out > out_3.out
# sort the results from high to low sequence counts
sort --parallel=32 -nr out_3.out > out_4.out
# remove the spaces from the beginning of each line
sed -e 's/\s*//;s/\s/\t/' out_4.out > out_5.out
# replace tab delimiter to ; and print the sequence in front of the count
awk 'BEGIN {FS = "\t"; OFS = ";"};{print $2,$1}' out_5.out > $OUTPUT
# cleanup intermediate files
#rm out_1.out out_2.out out_3.out out_4.out out_5.out 

#END=$(date +%s)
#DIFF=$(( $END - $START ))
#echo "It took $DIFF seconds"
# source GNU parallel
# http://www.rankfocus.com/use-cpu-cores-linux-commands/
# https://www.gnu.org/software/parallel/
compress_unzipped () {
	echo "Hi"
}

#compress_unzipped