# This script runs miRDeep2 modules (mapper and miRDeep) on fastq files in given folder
# 1st argument - path with input .fastq files. Absolute path should be specified!
# 2nd argument - path to indexed reference genome (without .fa extension)
# 3rd argument - species ID (e.g. hsa, mmu, cel)
# 4nd argument - folder in which output should be written. Absolute path should be specified!
# 5th argument - number of threads
# Example: path_to_this_script.bash /folder/with/fastq/files /path/to/reference.genome hsa /output/folder 8

IN_PATH=$1
REFERENCE_GENOME=$2
SPECIES=$3
OUT_PATH=$4
N_THREADS=$5

# Iterate through all .fastq files in IN_PATH and run mapper module
mkdir -p ${OUT_PATH}/mapping
cd ${OUT_PATH}/mapping
for file in ${IN_PATH}/*.fastq; do
	FILE_ID=$(basename $file ".fastq")
	mapper.pl \
		$file \
		-e -h -j -o ${N_THREADS} -m \
		-p ${REFERENCE_GENOME} \
		-s ${FILE_ID}_collapsed.fa \
		-t ${FILE_ID}_collapsed_vs_genome.arf \
		2> ${FILE_ID}_report.log
done

mkdir -p ${OUT_PATH}/quantification
cd ${OUT_PATH}/quantification

mkdir -p miRBase
cd miRBase
# Download and unpack mature and hairping sequences from the miRBase
wget ftp://mirbase.org/pub/mirbase/CURRENT/mature.fa.gz
wget ftp://mirbase.org/pub/mirbase/CURRENT/hairpin.fa.gz
gunzip mature.fa.gz
gunzip hairpin.fa.gz
# Extract rows for specified species
git clone https://github.com/Drmirdeep/mirdeep2_patch
perl mirdeep2_patch/extract_miRNAs.pl mature.fa ${SPECIES} > ../mature.fa
perl mirdeep2_patch/extract_miRNAs.pl hairpin.fa ${SPECIES} > ../hairpin.fa
cd ..

# Run miRDeep module (fast) for all files
for file in ${IN_PATH}/*.fastq; do
	FILE_ID=$(basename $file ".fastq")
	mkdir -p $FILE_ID
	cd $FILE_ID
	
	quantifier.pl \
		-m ../mature.fa -p ../hairpin.fa \
		-r ${OUT_PATH}/mapping/${FILE_ID}_collapsed.fa \
		-t ${SPECIES} \
		2> report.log

	cp miRNAs* ../${FILE_ID}.tsv
	cd ..
done
