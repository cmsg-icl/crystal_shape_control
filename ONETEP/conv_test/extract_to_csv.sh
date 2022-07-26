#!/bin/bash
#Run this script from root directory (/ontepconv/) as "./extract_to_csv.sh"

relative_dat_path=`echo ./input/*.dat | sed -r "s/\.dat\$//"`
rootname=$(basename "$relative_dat_path" .dat)


#This function enters all subdirectories and extracts forces and total energies from the .onetep files present

write_forc_energ_to_csv(){

    for directory in */; do
        echo $directory
        cd $directory
        rt_dir=$(basename "$directory")

###Extract Total DFT Energy from .onetep output file

        energy=`grep '<-- CG' *.onetep | awk {'print $3'}`

###Extract Average Forces

        forcesString=`awk -v nline=$(wc -l $rootname.onetep | awk '{print $1}')  -v start=$(grep -n "^\**\s*Forces\s*\**" *.onetep | awk -F':' '{print $1}') -v end=$(grep -n "* TOTAL:" *.onetep | awk -F':' '{print $1}') '{if(NR>(start+5) && NR<(end-2)) print $4,$5,$6}' *.onetep # print the forces for each atom `
        numElements=`echo "${forcesString}" | wc -l`

        total_abs_force=0
        max=0.0
        for line in $forcesString; do
            abs=`echo ${line#-}`
            if (( $(echo "$abs $max" | awk '{print ($1 > $2)}') )); then
                max=$abs
            fi
            #total_abs_force=`echo "${total_abs_force} + $abs" | bc`
        done
        #total_avg_force=`echo "${total_abs_force}/${numElements}" | bc -l`
        species_array+=("$species_line")

###Extract SCF cycles and total time consumption

        n_scf=`grep '<-- CG' $rootname.onetep | awk '{printf "%i\n", $1}'`
        time_tot=`grep 'TOTAL TIME:' $rootname.onetep | awk '{printf "%.3f\n", $3}'`
        time_cyc=`echo "scale=3;${time_tot}/${n_scf}" | bc`
  
        
        echo "$rt_dir,$energy,${n_scf},${time_cyc}" >> ../energies.csv #write energies to root directory
        
        echo "$rt_dir,${max},${n_scf},${time_cyc}" >> ../forces.csv #write forces to root directory
        cd ..
    done
}


cutoff_csv(){
    read -p "Write CSV containing summary of results for cutoff energies? (in /cutoff/)? [y/n] " -n 1 -r
    echo    # new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > ./cutoff/forces.csv #empty file
        > ./cutoff/forces_sorted.csv #empty file
        > ./cutoff/energies.csv
        > ./cutoff/energies_sorted.csv
        cd ./cutoff
        write_forc_energ_to_csv
###########
#Sort the CSV files from low energy/force to high 
########## 

#-k1 tags the first field, the '1' means take the first field from the comma seperated field, the n means numerical result
#the -k2 tag means a secondary sorting function. Here the ,2 means take the second comma seperated value and sort it via default means (alphanumeric) 
        sort --field-separator=',' -k1,1n ./energies.csv > ./energies_sorted.csv 
        sort --field-separator=',' -k1,1n ./forces.csv > ./forces_sorted.csv 
        if [[ ${isplot} == 'F' ]]; then
            sed -i "1iTITLE,TOT E(HARTREE),N SCF CYC,TIME PER CYC(S)" ./energies.csv #write energy title
            sed -i "1iTITLE,GRAD(HARTREE/BOHR),N SCF CYC,TIME PER CYC(S)" ./forces.csv #write gradient title
            sed -i "1iTITLE,TOT E(HARTREE),N SCF CYC,TIME PER CYC(S)" ./energies_sorted.csv #write energy title
            sed -i "1iTITLE,GRAD(HARTREE/BOHR),N SCF CYC,TIME PER CYC(S)" ./forces_sorted.csv #write gradient title
        fi
        cd ..
    else
        echo "Skipping"
    fi
}


num_ngwf_csv(){
    read -p "Write CSV containing summary of results for number of NGWFs? (in /num_ngwf/)? [y/n] " -n 1 -r
    echo    # new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > ./num_ngwf/forces.csv #empty file
        > ./num_ngwf/forces_sorted.csv #empty file
        > ./num_ngwf/energies.csv
        > ./num_ngwf/energies_sorted.csv
        cd ./num_ngwf/
        write_forc_energ_to_csv
# Sort the CSV files form low energy/force to high
        sort --field-separator='_' -k1,1 -k2,2n ./energies.csv > ./energies_sorted.csv 
        sort --field-separator='_' -k1,1 -k2,2n ./forces.csv > ./forces_sorted.csv
        if [[ ${isplot} == 'F' ]]; then
            sed -i "1iTITLE,TOT E(HARTREE),N SCF CYC,TIME PER CYC(S)" ./energies.csv #write energy title
            sed -i "1iTITLE,GRAD(HARTREE/BOHR),N SCF CYC,TIME PER CYC(S)" ./forces.csv #write gradient title
            sed -i "1iTITLE,TOT E(HARTREE),N SCF CYC,TIME PER CYC(S)" ./energies_sorted.csv #write energy title
            sed -i "1iTITLE,GRAD(HARTREE/BOHR),N SCF CYC,TIME PER CYC(S)" ./forces_sorted.csv #write gradient title
        fi
        cd ..
    else
        echo "Skipping"
    fi
}

ngwf_radius_csv(){
    read -p "Write CSV containing summary of results for NGWFs Radii? (in /ngwf_radius/)? [y/n] " -n 1 -r
    echo    # new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > ./ngwf_radius/forces.csv #empty file
        > ./ngwf_radius/forces_sorted.csv #empty file
        > ./ngwf_radius/energies.csv
        > ./ngwf_radius/energies_sorted.csv
        cd ./ngwf_radius/
        write_forc_energ_to_csv
# Sort the CSV files form low energy/force to high
        sort --field-separator='_' -k1,1 -k2,2n ./energies.csv > ./energies_sorted.csv 
        sort --field-separator='_' -k1,1 -k2,2n ./forces.csv > ./forces_sorted.csv 
        if [[ ${isplot} == 'F' ]]; then
            sed -i "1iTITLE,TOT E(HARTREE),N SCF CYC,TIME PER CYC(S)" ./energies.csv #write energy title
            sed -i "1iTITLE,GRAD(HARTREE/BOHR),N SCF CYC,TIME PER CYC(S)" ./forces.csv #write gradient title
            sed -i "1iTITLE,TOT E(HARTREE),N SCF CYC,TIME PER CYC(S)" ./energies_sorted.csv #write energy title
            sed -i "1iTITLE,GRAD(HARTREE/BOHR),N SCF CYC,TIME PER CYC(S)" ./forces_sorted.csv #write gradient title
        fi
        cd ..
    else
        echo "Skipping"
    fi
}

plot(){
###########
#Plot Output.
    cat << __EOF | gnuplot -persist
set xtic auto                          # set xtics automatically
set ytic auto                          # set ytics automatically
set title "Forces versus Energy Cutoff"
set xlabel "Energy Cutoff (eV)"
set ylabel "Force (Ha/bohr)"
set datafile separator ","
set style line 1 lt 2 lc rgb "red" lw 1 pt 2 ps 3 
# use line style "ls" 1
plot './cutoff/forces_sorted.csv' using 1:2 with linespoints ls 1
__EOF

    cat << __EOF | gnuplot -persist
set xtic auto                          # set xtics automatically
set ytic auto                          # set ytics automatically
set title "Total System Energy versus Energy Cutoff"
set xlabel "Energy Cutoff (eV)"
set ylabel "Total System Energy (Ha)"
set datafile separator ","
set style line 2 lt 2 lc rgb "blue" lw 1 pt 2 ps 3
plot './cutoff/energies_sorted.csv' using 1:2 with linespoints ls 2
__EOF
}

read -p "Generate GNU plot? [y/n] " -n 1 -r
echo    # new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    isplot='T'
else
    isplot='F'
fi

cutoff_csv
num_ngwf_csv
ngwf_radius_csv

if [[ ${isplot} == 'T' ]]; then
    plot
fi

exit