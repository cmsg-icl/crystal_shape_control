# Quantum Espresso job submitter - ARCHER2 version

[Quantum Espresso](https://www.quantum-espresso.org/) job submitter for [ARCHER2](https://www.archer2.ac.uk/), Slurm job scheduler. Similar to the PBS version on Imperial HPC.  

## Install

1. Use `scp -r` to upload this folder to any sub-directory of `/work/` on the cluster.  
2. Enter the folder and execute the script `setup.sh`.  
3. Following the instructions, specify the directory of job submitter and the directory of executables. 
4. Type `source ~/.bashrc` to implement user-defined commands. 

**Note**

1. All the scripts should be placed in the same directory.  
2. By default, job submitter scripts will be stored in `${WORK}/runQE/`.  
3. Due to the file transfer rule, scripts cannot be placed in `${HOME}` directory. The computational nodes cannot identify directories in `${HOME}`.  
3. By default Quantum Espresso v6.8 is loaded from the shared module, refer to [QE page on ARCHER2 documentation](https://docs.archer2.ac.uk/research-software/qe/) for instructions.  

## Usage & command list

### Command line flags

The script adopts the command-line options to launch jobs:

| FLAG | FORMAT | DEFINITION                                                               |
|:-----|:------:| :------------------------------------------------------------------------|
| -x   | string | The executable                                                           |
| -in  | string | The main input file                                                      |
| -ref | string | Optional, the common basename of reference files                         |
| -nd  | int    | The number of nodes requested for the job                                |
| -wt  | hh:mm  | The walltime requested for the job                                       |

### Conventions of input and output file names

QE allows flexible names for the input and output files. To avoid ambiguity, the user should specify the input file extension as 'executable+i'. For example, input for 'pw.x' should be named as `jobname.pwi`. Similarly, `jobname.pwo` stands for output files. 

If the output file with the same name as the job to be submitted exists in the same directory, that job won't be executed before output is either transferred to another folder or removed. 

### Debugging information

Besides the standard output file, '.log' file, which is the original 'slurm-\[jobid\].out', is available for debugging. If the script is terminated normally, the file will be named as '\[jobname\].log'. If killed, in its original name. The '.log' file contains useful information about the pre- and post- processing procedures.

### Temporary directory

* If the job is terminated due to exceeding wall time, temporary files will be saved in the output directory. The temporary directory will be removed.

* If the job is terminated due to improper settings of calculation parameters (that leads to errors from the parallel code), temporary files will be saved in the output directory. The temporary directory will be removed.

* If the job is killed before 'timeout', temporary will be saved in the temporary directory with temporary names. The temporary directory will not be removed. Refer to '.out' file or 'slurm-\[jobid\].out' (no '.log' file is produced at this stage) file for the path. 

By default, the temporary directory is set as the sub folder '\[jobname\]\_\[jobid\]/', which is in the same directory as the input/output files. 

### Work directory

Files in work directory are not backed up, and occupy storage quota - so finished jobs are recommended to be transferred to `${HOME}`. Common `cp` works on login nodes. See [ARCEHR2 manual](https://docs.archer2.ac.uk/user-guide/data/) for details. 

### Commands

Here are user defined commands: 

1. `Pqe` - executing parallel QE calculations  

``` bash
~$ Pqe -nd ND -wt WT -x EXE -in jobname [-ref refname]
```

`ND`      - int, number of nodes  
`WT`      - str, walltime, hh:mm format  
`EXE`     - str, name of the executable  
`jobname` - str, full name of input file  
`refname` - str, optional, name of the previous job  

Example:

``` bash
~$ Pqe -nd 2 -wt 02:00 -x pw.x -in jobname.pwi -ref previous_job
```

Submit files:

``` bash
~$ sbatch jobname.slurm
```

Note that multiple inputs within a single job submission is allowed, though not recommended. In that case, the numbers of `-x` and `-in` flags should be the same. The number of `-ref` flags, if > 0, should be the same as those of `-x` and `-in`. 

Example:

``` bash
~$ Pqe -nd 2 -wt 02:00 -x pw.x -in job_1.pwi -x pw.x -in job_2.pwi
```

The name of generated submission file is composed of names of both jobs, connected with '\-'. Its maximum length is 20 characters. However, their temporary file directories are the separate with the same jobid, i.e., 'job_1_jobid/' and 'job_2_jobid/'.

``` bash
~$ sbatch job_1-job_2.slurm
```

3. `setqe` - print the file `settings`. No input required.

## Script list

`setup.sh` - set up the settings file and create job submission commands.  
`settings_template` - empty `settings` file with keywords but no values, will be used to cover `settings` file when installing/re-installing the job submitter.  
`gen_sub` - generate submission file.  
`run_exec` - execute parallel Quantum Espresso calculations.  
`post_proc` - Post-processing. Copy & save files from temporary directory to the output directory.  

**NOTE**

1. The name of file `settings` `gen_sub` `settings_template` shouldn't be changed.
2. `settings` `gen_sub` `settings_template` are applicable to Imperial HPC, comment the corresponding `sed` and `grep` sentences in `gen_sub`.  

## Keyword list
Keywords used for the script `settings` are listed in the table below. Any change in parameters should be made in that script.

| KEYWORD                 | DEFAULT VALUE                | DEFINITION |
|:------------------------|:----------------------------:|:-----------|
| SUBMISSION_EXT          | .slurm                       | extension of job submission script |
| NCPU_PER_NODE           | 128                          | Number of processors per node |
| MEM_PER_NODE            | -                            | Allocated memory per node, for Imperial CX1 |
| N_THREAD                | 1                            | The default number of threading |
| NGPU_PER_NODE           | -                            | Number of GPUs per node, for Imperial CX1 |
| GPU_TYPE                | -                            | The default type of GPU, for Imperial CX1 |
| BUDGET_CODE             | *user defined*               | Budget code of a research project, see [ARCHER2 manual](https://docs.archer2.ac.uk/user-guide/scheduler/#checking-available-budget)|
| QOS                     | standard                     | Quality of service, see [ARCHER2 manual](https://docs.archer2.ac.uk/user-guide/scheduler/#quality-of-service-qos) |
| PARTITION               | standard                     | Partition of jobs, see [ARCHER2 manual](https://docs.archer2.ac.uk/user-guide/scheduler/#partitions) |
| TIME_OUT                | 3                            | Unit: min. Time spared for post processing |
| JOB_TMPDIR              | -                            | Temporary directory for calculations |
| EXEDIR                  | module load quantum_espresso | Directory of executable / Available module load command |
| EXE_PARALLEL            | -                            | Default parallel executable, Not applicable |
| EXE_OPTIONS             | -                            | Extra options for parallel executable, Not applicable |
| PRE_CALC                | \[Table\]                    | Saved names, temporary names, and definitions of mandatory input files |
| FILE_EXT                | \[Table\]                    | Saved names, temporary names, and definitions of optional input files |
| POST_CALC               | \[Table\]                    | Saved names, temporary names, and definitions of output files |
| JOB_SUBMISSION_TEMPLATE | \[script\]                   | Template for job submission scripts |

**NOTE**

1. Keyword `JOB_SUBMISSION_TEMPLATE` should be the last keyword, but the sequences of other keywords are allowed to change.  
2. Empty lines between keywords and their values are forbidden.  
3. All listed keywords have been included in the scripts. Undefined keywords are left blank.  
3. Multiple-line input for keywords other than `PRE_CALC`, `POST_CRYS`, `POST_PROP`, and `JOB_SUBMISSION_TEMPLATE` is forbidden.  
4. Dashed lines for `PRE_CALC`, `POST_CRYS`, `POST_PROP`, and `JOB_SUBMISSION_TEMPLATE` are used to define input blocks and are not allowed to be modified. Minimum length: '------------------'

