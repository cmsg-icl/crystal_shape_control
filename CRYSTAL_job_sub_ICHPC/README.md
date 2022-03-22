# Crystal job submitter - Imperial Cluster version

[Crystal](https://www.crystal.unito.it/index.php) job submitter for [Imperial Cluster](https://www.imperial.ac.uk/admin-services/ict/self-service/research-support/rcs/), PBS job scheduler.  

## Install

1. Use `scp -r` to upload this folder to any sub-directory of `${HOME}` on the cluster.  
2. Enter the folder and execute the script `setup.sh`.  
3. Following the instructions, specify the directory of job submitter and the directory of executables. 
4. Type `source ~/.bashrc` to implement user-defined commands. 

**Note**

1. All the scripts should be placed in the same directory.  
2. By default, job submitter scripts will be stored in `${HOME}/runCRYSTAL/`.  
3. By default, CRYSTAL17v2.2gnu will be set as the executable.  

## Usage & command list

Printed out information can be found in '.out' file and '.o\<jobid\>' file. 

If a '.out' file with the same name as the job to be submitted exists in the same directory, that job won't be executed before output is either transferred to another folder or removed. 

If the job is terminated due to exceeding wall time, temporary files will be saved in the output directory. The temporary directory will be removed.

If the job is terminated due to improper settings of calculation parameters, temporary files will be saved in the output directory. The temporary directory will be removed.

If the job is killed before 'timeout', temporary will be saved in the temporary directory with temporary names. The temporary directory will not be removed. Refer to '.out' file or '.o\<jobid\>' file for the path. 

By default, the temporary directory is set as `/rds/general/ephemeral/user/${USER}/ephemeral`, where the contents will be automatically removed after 30 days. 

Here are user defined commands: 

1. `Pcry` - executing parallel crystal calculations (Pcrystal and MPP)  

``` bash
Pcry ND WT jobname [refname]
```

`ND`      - int, number of nodes  
`WT`      - str, walltime, hh:mm format  
`jobname` - str, name of input .d12 file  
`refname` - str, optional, name of the previous job  

Equivalent examples:

``` bash
> Pcry np=2 wt=02:00 jobname.d12 previous_job
> Pcry 2 02:00 jobname previous_job
> ~/job/submitter/dir/gen_sub crys 2 02:00 jobname previous_job
```

Submit files:

``` bash
> qsub jobname.qsub
```

2. `Pprop` - executing parallel properties calculations (Pproperties)

``` bash
Pprop ND WT jobname SCFname
``` 

`ND`      - int, number of nodes  
`WT`      - str, walltime, hh:mm format  
`jobname` - str, name of input .d3 file  
`SCFname` - str, name of the previous 'crystal' job  

Equivalent examples:

``` bash
> Pprop np=1 wt=00:30 prop_job.d3 previous_job.d12
> Pprop 1 00:30 prop_job previous_job
> ~/job/submitter/dir/gen_sub prop 1 00:30 prop_job previous_job
```

Then submit files. 

3. `setcrys` - print the file `settings`. No input required.

## Script list

`setup.sh` - set up the settings file and create job submission commands.  
`settings` - store all parameters needed for CRYSTAL/PROPERTIES jobs. see the 'Keyword list' below.  
`settings_template` - empty `settings` file, will be used to cover `settings` file when installing/re-installing the job submitter.  
`gen_sub` - generate submission file.  
`runcryP` - execute 'CRYSTAL' type calculations in parallel (P and MPP).  
`runpropP` - execute 'PROPERTIES' type calculations in parallel.  
`post_processing` - Copy & save files from temporary directory to the output directory.  

**NOTE**

1. The name of file `settings` `gen_sub` `settings_template` shouldn't be changed.
2. `settings` `gen_sub` `settings_template` are applicable to ARHCER2, comment the corresponding `sed` and `grep` sentences in `gen_sub`. 
2. Names of `runcryP` `runpropP` `post_processing` can be changed, but should corresponds to the values in `settings`.  

## Keyword list
Keywords used for the script `settings` are listed in the table below. Any change in parameters should be made in that script.

| KEYWORD                 | DEFAULT VALUE   | DEFINITION |
|:------------------------|:---------------:|:-----------|
| SUBMISSION_EXT          | .qsub           | extension of job submission script |
| NCPU_PER_NODE           | 48              | Number of processors per node |
| MEM_PER_NODE            | 50              | Unit: GB. Allocated memory per node |
| BUDGET_CODE             | -               | Budget code of a research project, for ARCHER2|
| QOS                     | -               | Quality of service, for ARCHER2 |
| PARTITION               | -               | Partition of jobs, for ARCHER2 |
| TIME_OUT                | 3               | Unit: min. Time spared for post processing |
| CRYSTAL_SCRIPT          | runcryP         | Script for crystal type calculations |
| PROPERTIES_SCRIPT       | runpropP        | Script for properties type calculations |
| POST_PROCESSING_SCRIPT  | post_processing | Post processing script |
| JOB_TMPDIR              | /rds/general/ephemeral/user/${USER}/ephemeral | Temporary directory for calculations |
| EXEDIR                  | /rds/general/user/gmallia/home/CRYSTAL17_cx1/v2.2gnu/bin/Linux-mpigfortran_MPP/Xeon___mpich__3.2.1 | Directory of executables |
| EXE_PCRYSTAL            | Pcrystal        | Executable for parallel crystal type calculation |
| EXE_MPP                 | MPPcrystal      | Executable for massively parallel crystal type calculation |
| EXE_PPROPERTIES         | Pproperties     | Executable for parallel properties type calculation |
| EXE_CRYSTAL             | -               | Executable for serial crystal type calculation, for workstation |
| EXE_PROPERTIES          | -               | Executable for serial properties type calculation, for workstation |
| PRE_CALC                | \[Table\]       | Saved names, temporary names, and definitions of input files |
| POST_CRYS               | \[Table\]       | Saved names, temporary names, and definitions of output files for crystal type calculation |
| POST_PROP               | \[Table\]       | Saved names, temporary names, and definitions of output files for properties type calculation |
| JOB_SUBMISSION_TEMPLATE | \[script\]      | Template for job submission files |

**NOTE**

1. Keyword `JOB_SUBMISSION_TEMPLATE` should be the last keyword, but the sequences of other keywords are allowed to change.  
2. Empty lines between keywords and their values are forbidden.  
3. All listed keywords have been included in the scripts. Undefined keywords are left blank.  
3. Multiple-line input for keywords other than `PRE_CALC`, `POST_CRYS`, `POST_PROP`, and `JOB_SUBMISSION_TEMPLATE` is forbidden.  
4. Dashed lines for `PRE_CALC`, `POST_CRYS`, `POST_PROP`, and `JOB_SUBMISSION_TEMPLATE` are used to define input blocks and are not allowed to be modified. Minimum length: '------------------'


