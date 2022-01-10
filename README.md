# Unix shell and command language application for GA-ANN ReaxFF parametrization tool

Python application together with the corresponding supercomputing job-script, written in a Unix shell and command language (portable to SLURM-based environment), have been developed to achieve more robust, user-friendly code performance of the GA-ANN ReaxFF parametrization tool (https://github.com/cdaksha/parametrization_clean).

The new algorithm contains the following novelty and improvements:
1) The new code allowed us to combine all processes into one. This includes control of the input; manual choice of the optimization scheme used in ReaxFF (IOPT = 0, 3 and 4 which allows to use all the training set parameters including bond distances and angles for optimization); dynamical refitting of the ReaxFF parameters in case of IOPT = 4; Verification and Analysis of the ReaxFF output. 
2) Development of the supplement code also allowed us to cut off the cases with unrealistic results (for example, when atoms were too close to each other during the ReaxFF optimization) and limit the energy errors It is necessary to note, that this scheme does not affect the performance of the original algorithm and significantly reduces the number of code crashes. 
3) Parallelization of the ReaxFF error evaluation has been added to the code. It allows to gain the 32 times (limited by maximal number of cores in a computational node) faster performance in comparison to the original algorithm. 
