# collapse-multiplex-barcodes
Collapse deep-sequencing multiplex barcode data

OPTIONS:
-a	lane 1, fastq file [L1] gzipped (required)

-b	lane 2, fastq file [L2] gzipped (optional)

-c	count, minimum read count threshold (default 2)

-l	write log file (no[0]/yes[1]) (default 1)

-h	print help message and exit

-m	length, minimum length of read (bp)

-o	output file containing the compressed barcode data (required)

-q	minimum quality score of read 
	
	value must be set between 1 and 41
	https://en.wikipedia.org/wiki/FASTQ_format#Encoding
	https://en.wikipedia.org/wiki/Phred_quality_score
	
	Phred Quality Score, Probability of incorrect base call, Base call accurary
	10, 1 in 10, 	 90%
	20, 1 in 100, 	 99%
	30, 1 in 1000, 	 99.9%
	40, 1 in 10,000, 99.99%

-r 	write out rejected (based on set filtes) reads: rejected.txt (no[0]/yes[1]) (default 0)

-t	number of threads to be used (default 4)

-v	print version of the program and exit

EXAMPLE:

bash collapse-multiplex-barcodes.sh -a ./data/reads_100k.fastq.gz -o collapsed-barcodes.txt
