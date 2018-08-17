#!/bin/bash
START=$(date +%s)
# Erik Zwart
# erik.zwart@gmail.com
# August 2018
# ?add demultiplex option to samples
# ? printout files and setting used
print_usage() {
	echo "-----------------------------------------------"
	echo "Compress Multiplex Barcode Deep-Sequencing data"
	echo "-----------------------------------------------"
	echo "OPTIONS:"
	echo "-l1, -lane1"
	echo "	fastq file [L1] gzipped"
	echo "-l2, -lane2"
	echo "	fastq file [L2] gzipped"

	echo "-c, -count"
	echo "	minimum read count threshold, default 2"

	echo "-m, -length"
	echo "	minimum length of read (bp)"

	echo "-o, -output"
	echo "	output file containing the compressed barcode data"
	echo "-t, -threads"
	echo "	OPTIONAL: number of threads to be used, default 4"

	echo "-q, -quality"
	echo "	OPTIONAL: minimum quality score of read"
	echo "	value must be set between 1 and 40"
	echo "	https://en.wikipedia.org/wiki/FASTQ_format#Encoding"
	echo "	https://en.wikipedia.org/wiki/Phred_quality_score"
	echo ""
	echo "	Phred Quality Score, Probability of incorrect base call, Base call accurary"
	echo "	10, 1 in 10, 90%"
	echo "	20, 1 in 100, 99%"
	echo "	30, 1 in 1000, 99.9%"
	echo "	40, 1 in 10,000, 99.99%"

	echo "-h, -help"
	echo "	print help message and exit"
	echo "-v, -version"
	echo "	print version of the program and exit"
}

test_fastq() {
	# test fastq file to see if it is valid
	# ! will only test the first read !
	# line 2 needs to contain the read only bases are allowed ACTGN
	# line 4 needs to contain the quality information, FASTQ quality score Sanger or Illumina 1.8+
	f=$1
	if zcat -c $f | head -2 | tail -1 | egrep -ie '[^ACTGN]';
	then
		echo "ERROR: FASTQ data has invalid characters"
		exit 1
	fi

	if zcat -c $f | head -4 | tail -1 | egrep -e '[^!-J]';
	then
		echo "ERROR: Invalid FASTQ quality encoding"
		exit 1
	fi
}

check_fastq() {
	# see if user provided fastq file is valid and gzipped .gz
	f=$1
	if [ ! -f $f ];
	then
		echo "ERROR: input fastq file does not exists."
		exit 1
	else
		# file needs to be gzipped
		case "$f" in
			*.gz) test_fastq $f;;
			*) echo "ERROR: input fastq file is not gzipped (.gz)."; exit 1;;
		esac
		# file is ok
		return 0
	fi
}

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
			"-l1"|"-lane1" 	) L1="$1"; shift;;
			"-l2"|"-lane2" 	) L2="$1"; shift;;
			"-c"|"-count"   ) COUNT="$1"; shift;;
			"-m"|"-length"  ) MINLEN="$1"; shift;;
			"-o"|"-output"	) OUTPUT="$1"; shift;;
			"-t"|"-threads"	) THREADS="$1"; shift;;
			"-q"|"-quality" ) QUALITY="$1"; shift;;
			"-v"|"-version"	) echo "version 0.1"; exit 0;;
			*				) echo "ERROR: Invalid argument: \""$opt"\"" >&2
							  exit 1;;
		esac
	done
fi

if [[ "$L1" == "" ]];
then
	echo "ERROR: [-l1, -lane1] requires an argument." >&2; exit 1
fi

if [[ "$OUTPUT" == "" ]];
then
	echo "ERROR: [-o, -output] requires an argument." >&2; exit 1
fi

if [[ "$THREADS" == "" ]];
then
	# number of threads is not set, defaulting to 4 threads
	THREADS=4
elif [[ "$THREADS" -le 0 ]];
then
	# number of threads is set to 0 or lower, defaulting to 4 threads
	THREADS=4
elif [[ "$THREADS" -gt 32 ]];
then
	echo "WARNING: [-t, -threads] is set to $THREADS"
	echo "Are you sure your system supports that?"
else
	case "$THREADS" in
		(*[!0-9]*|'') echo "ERROR: [-t, -threads] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi

if [[ "$QUALITY" == "" ]];
then
	# minimum read quality is not set, defaulting to lowest setting 0 (0=!==33)
	QUALITY=0
elif [[ "$QUALITY" -lt 0 || "$QUALITY" -gt 40 ]];
then
	echo "ERROR: [-q, -quality] invalid argument, value must be set between 1 and 40." >&2; exit 1
else
	case "$QUALITY" in
		(*[!0-9]*|'') echo "ERROR: [-q, -quality] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi 

if [[ $L1 ]]; then check_fastq $L1; else echo "ERROR: [-l1, -lane1] is not set."; exit 1; fi
if [[ $L2 ]]; then check_fastq $L2; fi

if [[ "$COUNT" == "" ]];
then
	# minimum read count is not set, default to 2 (remove singletons)
	COUNT=0
elif [[ "$COUNT" -le 1 ]];
then
	echo "ERROR: [-c, -count] is set to low." >&2; exit 1
else
	case "$COUNT" in
		(*[!0-9]*|'') echo "ERROR: [-c, -count] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi

if [[ "$MINLEN" == "" ]];
then
	# minimum read length is not set, default to 0 (in effect ignore setting)
	MINLEN=0
elif [[ "$MINLEN" -gt 150 ]];
then
	echo "WARNING: [-m, -length] is set higher then expected."
elif [[ "$MINLEN" -le -1 ]];
then
	echo "ERROR: [-m, -length] is set to low" >&2; exit 1
else
	case "$MINLEN" in
		(*[!0-9]*|'') echo "ERROR: [-m, -length] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi
# see if minimum read length is set to high
if `zcat -c $L1 | head -2 | tail -1 | awk '{if (length($0) < '$MINLEN') {exit 0} else {exit 1} }'`;
then
	echo "ERROR: [-m, -length] minimum set to high" >&2; exit 1
fi

#ord "a"
# quality score of 10 = 10+33 ASCII
#chr 43
# quality score of 20 = 20+33
# max score is 40+33
# minimal quality score 32 corresponds to A 65
##qs=33
##offset=33
# convert decimal to ascii value + phred offset
a=$(printf "\\$(printf '%03o' $(( $QUALITY + 33 )))")
#echo $a

#zcat -c $L1 $L2 | awk '{if (NR % 4 == 0) {
#	if ($1 ~ /[^'$a'-'J']/) {pass = 0} else {pass = 1}}};
#	{if (NR % 4 == 2 && pass) {print $1}}' | sort --parallel=$THREADS |
#	uniq -d -c | sort --parallel=$THREADS -nr | sed -e 's/\s*//;s/\s/\t/' |
#	awk 'BEGIN {FS = "\t"; OFS = "\t"};{print $2,$1}' > $OUTPUT
#echo $COUNT

#zcat -c $L1 $L2 | awk '{if (NR % 4 == 0) {
#	if ($1 ~ /[^'$a'-'J']/) {pass = 0} else {pass = 1}}};
#	{if (NR % 4 == 2 && pass) {print $1}}' | sort --parallel=$THREADS |
#	uniq -d -c | sort --parallel=$THREADS -nr | sed -e 's/\s*//;s/\s/\t/' |
#	awk 'BEGIN {FS = "\t"; OFS = "\t"};{if ('$COUNT' == 0) {print $2,$1} else {
#	if ($1 >= '$COUNT') {print $2,$1}}}' > $OUTPUT

zcat -c $L1 $L2 | awk '{if (NR % 4 == 0) {if ($1 ~ /[^'$a'-'J']/) {pass = 0} else {pass = 1}}};
	{if (NR % 4 == 2 && pass) {if (length($1) >= '$MINLEN') {print $1}}}' |
	sort --parallel=$THREADS | uniq -d -c | sort --parallel=$THREADS -nr | 
	sed -e 's/\s*//;s/\s/\t/' |	awk 'BEGIN {FS = "\t"; OFS = "\t"};
	{if ('$COUNT' == 0) {print $2,$1} else {if ($1 >= '$COUNT') {print $2,$1}}}' > $OUTPUT


END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $DIFF seconds"
# add minimum length filter
# add minimum read count threshold

#echo "----"
#zcat -c $L1 | head -80 | awk 'NR % 4 == 2'

# retrieve the sequences only
##zcat -c $L1 | awk 'NR == 0 || NR % 4 == 2' > out_1.out
# sort the sequences --parallel stands for the usable cores (do not set this to high..)
##sort --parallel=32 out_1.out > out_2.out
# only report duplicate lines and count the number of occurrences,
# in effect get rid of singletons
##uniq -d -c out_2.out > out_3.out
# sort the results from high to low sequence counts
##sort --parallel=32 -nr out_3.out > out_4.out
# remove the spaces from the beginning of each line
##sed -e 's/\s*//;s/\s/\t/' out_4.out > out_5.out
# replace tab delimiter to ; and print the sequence in front of the count
##awk 'BEGIN {FS = "\t"; OFS = ";"};{print $2,$1}' out_5.out > $OUTPUT
# cleanup intermediate files
#rm out_1.out out_2.out out_3.out out_4.out out_5.out
