#!/bin/bash
#$ -N Devel_script
#$ -cwd
#$ -q mag*
#$ -pe smp* 1-
#$ -m e
#$ -M evgenii.strugovshchikov@fundacio.urv.cat

source /etc/profile.d/modules.sh
module load apps/adf/2020

export PATH=/home/programes/miniconda3/bin:$PATH
source activate reaxff

GENERATION_NUM=1
MAX_GENERATION_NUM=1001
TRAINING_PATH="training_set/"
POPULATION_PATH="output/"
CONFIG_PATH="config.json"
POPULATION_SIZE=30
NUM_OF_CORES=$NSLOTS
IOPT=4
TIME_OUT=300

# initialize a semaphore with a given number of tokens
open_sem(){
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for((;i>0;i--)); do
        printf %s 000 >&3
    done
}

# run the given command asynchronously and pop/push tokens
run_with_lock(){
    local x
    # this read waits until there is something to read
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
     ( "$@"; )
    # push the return code of the command to the semaphore
    printf '%.3d' $? >&3
    )&
}

initial_error() {
##INPUT="error_function_${i}"
CHILD="child-${i}"

cd "$CHILD"
##scp ../$CHILD/ffield .

# =====================================
#        CONTROL SETTINGS
# =====================================
cat > control <<eor
# General parameters
      1 tors13     Use 2013 formula for torsions
      0 itrans
      1 icobo
      1 icentr     0: off, 1: put center of masss at center of cube, 2: put com at origin
      1 imetho     Normal MD-run 1: Energy minimisation
      1 igeofo     0:xyz-input geometry 1: Biograf input geometry 2: xmol-input geometry
  100.0 axis1      a cell axis
  100.0 axis2      b cell axis
  100.0 axis3      c cell axis
 90.000 angle1     cell angles
 90.000 angle2     cell angles
 90.000 angle3     cell angles
     25 irecon     Frequency of reading control-file
      0 isurpr     1: Surpress lots of output 2: Read in all geometries at the same time
      5 ixmolo     xmolout 0: xyz only, 1: xyz + vels + molnr, 2: xyz + mol.nr, 5: xyz + bonds
      1 ichupd     Charge update frequency
      4 icharg     always 4: Full ystem EEM
 298.00 mdtemp     MD-temperature (K), unless tregime file is present
  100.0 tdamp1     1st Berendsen/Anderson temperature damping constant (fs)
      0 nrstep
# MD-parameters
      1 imdmet     MD-method. 1:Velocity Verlet+Berendsen 2:Hoover-Nose (again NVT); 3:NVE 4:NPT
  0.250 tstep      MD-time step (fs)
   0.00 mdpres     MD-pressure (GPa)
  500.0 pdamp1     Berendsen pressure damping constant (fs)
      0 inpt       0: Change all cell parameters in NPT-run  1: fixed x 2: fixed y 3: fixed z
  40000 nmdit      Number of MD-iterations
1000000 iout1      Output frequency to unit 71 and unit 73
1000000 iout2      Save coordinates (xmolout, moldyn.vel, Molfra)
      1 iout3      Create moldyn.xxx files (0: yes, 1: no)
      0 ivels      0: Use velocities from vels restart-file; 1: Zero initial velocities
   2000 iout6      Frequency of molsav.xxxx restart file creation (xyz, vels and accel)
     50 iout7      Frequency of reaxout.kf writing
     25 irten      Frequency of removal of rotational and translational motions
      0 npreit     Nr. of iterations in previous runs
   0.00 range      range for back-translation of atoms outside periodic box
# MM-parameters
  1.000 endmm      End point criterium for MM energy minimisation (force)
      1 imaxmo     0: conjugate gradient, 1: L-BFGS
  03000 imaxit     Maximum number of iterations
      1 iout4      Frequency of structure output during minimisation
      0 icelop     0 : no cell opt, 1: numerical cell opt
1.00010 celopt     Cell parameter change factor
      0 icelo2     0: Cubic cell optimization; 1/2/3: only a/b/c; 4: c/a ratio
#MCFFOptimizer parameters
      0 mcffit     
      1 fort99         
eor

cat > iopt <<eor
$IOPT
eor

export NSCM=1
timeout $TIME_OUT $AMSBIN/reaxff >> output_log.txt
if test -f fort.99.best ; then cp fort.99.best fort.99 ; fi

# =====================================
#        REMOVE NOT USED OUTPUT FILES
# =====================================

for oldfile in MCFFOptimizer.log ffield_best ffield_last_accepted.1 ffieldss istop 4s 13s 13s2 fort.3 fort.4 fort.9 fort.13 fort.20 fort.21 reaxout.kf summary.txt
do
  if test -f $oldfile ; then  rm $oldfile ; fi
done

##scp fort.99  ../$CHILD/

cd ..
}

calculation_error() {
##INPUT="error_function_${i}"
CHILD="child-${i}"

cd "$CHILD"

rm params
scp ../params .

FILE=fort.99
if [ -f "$FILE" ]; then
	echo "child-${i} - $FILE exists."
else
	#echo "$FILE does not exist."
	export NSCM=1
	timeout $TIME_OUT $AMSBIN/reaxff >> output_log.txt
	cp fort.99.best fort.99
fi


##cp fort.99.best fort.99
analyze_errors 1 0 >> output_log.txt

if grep -q "Atoms are too close" output_log.txt ; then
    echo "child-${i} - found too close"
    rm fort.99
fi

if grep -q "RMSD (Energy):" output_log.txt ; then
    echo "child-${i} - found Energy"
else
    echo "child-${i} - not found Energy"
    rm fort.99
fi

for oldfile in MCFFOptimizer.log ffield_best ffield_last_accepted.1 ffieldss istop 4s 13s 13s2 fort.99.best fort.3 fort.4 fort.9 fort.13 fort.20 fort.21 reaxout.kf summary.txt
do
  if test -f $oldfile ; then  rm $oldfile ; fi
done

##scp fort.99  ../$CHILD/

cd ..
}

script_main() {
#for ((i = 0; i < $((POPULATION_SIZE - 1)); i++)); do

#OINPUT="error_function_${i}"
#j=$((i + 1))
#OOUTPUT="error_function_${j}"

#mkdir "$OOUTPUT"
#scp -r "$OINPUT"/* "$OOUTPUT"

#done

open_sem $NUM_OF_CORES
for ((i = 0; i < ${POPULATION_SIZE}; i++)); do

run_with_lock initial_error

done
wait

for ((j = 0; j < ${POPULATION_SIZE}; j++)); do

##INPUT="error_function_${j}"
CHILD="child-${j}"

cd "$CHILD"
scp output_log.txt ../
cd ..


python params_script.py

rm output_log.txt

done


open_sem $NUM_OF_CORES
for ((i = 0; i < ${POPULATION_SIZE}; i++)); do
#CHILD="child-${i}"

#scp params $CHILD/

run_with_lock calculation_error

done
wait

for ((i = 0; i < ${POPULATION_SIZE}; i++)); do

CHILD="child-${i}"

cd "$CHILD"

grep "RMSD (Energy):" output_log.txt >> ../../${GENERATION_NUM}-energy.txt

cd ..

done

}


scp "${TRAINING_PATH}"/params errors/
mkdir best_output

while [ $GENERATION_NUM -le $MAX_GENERATION_NUM ]; do
	
cli --generation_number ${GENERATION_NUM} --training_path "${TRAINING_PATH}" --population_path "${POPULATION_PATH}" --config_path "${CONFIG_PATH}"
    
if [[ ! -d "${POPULATION_PATH}/generation-${GENERATION_NUM}" ]]; then
GENERATION_NUM=$((GENERATION_NUM - 1))
rm -r "${POPULATION_PATH}/generation-${GENERATION_NUM}"
echo "Deleting simulations for generation-${GENERATION_NUM}..."
continue
fi
echo "Submitting simulations for generation-${GENERATION_NUM}..."

if (( GENERATION_NUM > 1 )); then
cd "best_output"
mkdir "generation-$((GENERATION_NUM - 1))"
cd "../output/generation-$((GENERATION_NUM - 1))"
BEST_TEXT="$(grep "case-" 00-gen-summary.txt|awk ' {print $6}')" 
IFS='-'
read -a strarr <<< "$BEST_TEXT"
BEST_TEXT="${strarr[1]}"
BEST_CHILD="child-${BEST_TEXT}"
##echo "$BEST_CHILD"
scp -r "$BEST_CHILD"/* ../../best_output/"generation-$((GENERATION_NUM - 1))"/
cd ../..
fi

scp -r errors/* "${POPULATION_PATH}/generation-${GENERATION_NUM}"

cd "${POPULATION_PATH}/generation-${GENERATION_NUM}"

script_main

cd ..

scp ../errors/count_energy.py .
python count_energy.py 1 ${GENERATION_NUM}
rm count_energy.py

if (( GENERATION_NUM > 5 )); then 
rm -r generation-$((GENERATION_NUM - 5))
fi

cd ..

GENERATION_NUM=$((GENERATION_NUM + 1))

done

exit
