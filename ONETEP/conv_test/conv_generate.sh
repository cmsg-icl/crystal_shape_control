#!/bin/bash
#20/05/2014 Ben Lowe
#Convergence Utility: Generates a set in input files and the scripts to the run them on a local machine.
#Usage: Within the root directory simply run: ./conv_generate.sh 

#
#todo: insert displace atoms for accurate forces option
#


read -p "This script will generate a set of input files. If this script has been run before it will overwrite all previous results. Continue? [y/n] " -n 1 -r
echo    # new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
else 
    echo "Exiting"
    exit 101
fi


root=`pwd`

################## 
# Parse settings.conv for parameters to get the parameters for the tool
##################

source ./lib/parse_input.sh

#################
# Clean up all input files from previous runs
#################

if [ "$clean" == "T" ]; then
  echo "cleaning all subdirectories of files from previous OntepConv runs"
  #find ./cutoff/ -name \*.dat -type f -delete 
  #find ./ngwf_radius/ -name \*.dat -type f -delete 
  #find ./num_ngwf/ -name \*.dat -type f -delete 
  rm -r ./cutoff/
  rm -r ./ngwf_radius/
  rm -r ./num_ngwf/
fi

#################
# Check input files. 
# - Checks .dat file is present
# - Checks .recpot files are present
# - Checks 'WRITE_FORCES' is present in .dat file
################# 

ndatfiles=`ls ./input/*.dat | wc -l`

if [ $ndatfiles -eq 0 ]; then
  echo "No .dat files in ./input/. Aborting." >&2
  exit 101
fi

if [ $ndatfiles -gt 1 ]; then
  echo "More than one dat file in ./input/, don't know which one to choose. Aborting." >&2
  exit 102
fi

relative_dat_path=`echo ./input/*.dat | sed -r "s/\.dat\$//"`
rootname=$(basename "$relative_dat_path" .dat) 

nrecpotfiles=`ls ./recpot/*.recpot | wc -l`

if [ $nrecpotfiles -eq 0 ]; then
  echo "No .recpot norm-conserving pseudopotential files in ./recpot/. Aborting." >&2
  exit 101
fi

if ! grep -i -q '^write_forces\s*:*\s*T' ./input/$rootname.dat; then 
  echo "write_forces : T command not found in the /input/$rootname.dat, please enable this. Exiting."
  exit 101
fi

################ 
# Varying the Kinetic Energy Cutoff
################


echo "Running Kinetic Energy Cutoff Scan Generation..."

mkdir -p cutoff

cp ./input/$rootname.dat ./cutoff/$rootname.dat

i=$min_cutoff

while [ $(bc <<< "$i <= $max_cutoff") -eq 1 ]
do
   dir=${i}
   echo "Generating param files for $i Cutoff Energy in ./cutoff/$dir/"
   #Make a directory for each KE cutoff
   mkdir -p ./cutoff/$dir
   sed -i -e "s/CUTOFF_ENERGY.*/CUTOFF_ENERGY $i eV/I" ./cutoff/$rootname.dat
   echo "  Copying relevant input files (dat, recpot) to ./cutoff/$dir"
   cp ./recpot/*.recpot ./cutoff/$dir
   cp ./cutoff/$rootname.dat ./cutoff/$dir
   i=`echo "$i + $cutoff_spacing" | bc`
done

############### 
# Varying Number of NGWFs
###############


#BL/Tests: Tested for non-integer spacings
echo "Running Number of NGWF Scan Generation..."

source ./lib/num_ngwf.sh

############### 
# Varying NGWF Radius
###############

echo "Running NGWF Radius Scan Generation..."

#Note that this .sh script relies upon an species block array generated in num_ngwf.sh
source ./lib/ngwf_radius.sh

##############
# Speed up Single Point Energy Calculations by resuming NGWFs and DKN from a previous run
##############

#Note that this cannot be done for the number of NGWF scan

if [ "$reuse_calculations" == "T" ]; then

	echo "reuse_calculations=T."

	if ! grep -i -q 'READ_TIGHTBOX_NGWFS T' ./input/*.dat ; then
    		echo "READ_TIGHTBOX_NGWFS T not found. Ensure this is present for reuse_calculations=T. Abort."
		exit 101 
	fi

	if ! grep -i -q 'READ_DENSKERN T' ./input/*.dat ; then
    		echo "READ_TIGHTBOX_NGWFS T not found. Ensure this is present for reuse_calculations=T. Abort."
		exit 101 
	fi

	nngwf=`ls ./input/*.tightbox_ngwfs | wc -l`

	if [ $nngwf -eq 0 ]; then
	  echo "No .tightbox_ngwfs files in ./input/. Aborting." >&2
	  exit 101
	fi

	if [ $nngwf -gt 1 ]; then
	  echo "More than one .tightbox_ngwfs file in ./input/, don't know which one to choose. Aborting." >&2
	  exit 102
	fi

	ndkn=`ls ./input/*.dkn | wc -l`

	if [ $ndkn -eq 0 ]; then
	  echo "No .dkn files in ./input/. Aborting." >&2
	  exit 101
	fi

	if [ $ndkn -gt 1 ]; then
	  echo "More than one .dkn file in ./input/, don't know which one to choose. Aborting." >&2
	  exit 102
	fi

	echo "Copying .dkn and .tightbox_ngwfs to relevant directories"

	for dir in "cutoff" "ngwf_radius";
	do
		cd $dir
		#copy this into all subdirectories of $dir recursively
		find . -type d -exec cp $root/input/*.tightbox_ngwfs {} \; 
		find . -type d -exec cp $root/input/*.dkn {} \; 
		cd ..
	done

	# Ensures num_ngwfs uses fresh ngwf and dkn (basis set)

	for dir in "num_ngwf";
	do
		cd $dir
		dat=`ls ./*.dat`		
		sed -i "s/READ_TIGHTBOX_NGWFS.*/READ_TIGHTBOX_NGWFS F/Ig" $dat
		sed -i "s/READ_DENSKERN.*/DENSKERN F/Ig" $dat

		for folder in */;
		do
			cd $folder
			dat=`ls ./*.dat`		
			sed -i "s/READ_TIGHTBOX_NGWFS.*/READ_TIGHTBOX_NGWFS F/Ig" $dat
			sed -i "s/READ_DENSKERN.*/READ_DENSKERN F/Ig" $dat
			cd ..
		done
		cd ..
	done

else
  echo "Please ensure READ_TIGHTBOX_NGWFS F and READ_DENSKERN F (or are unspecified) in your input .dat file"
fi

echo "Complete."

#####
#Useful code for debugging
#####
#if [ "$i" -eq 2 ]; then 
#		exit 101
#fi


