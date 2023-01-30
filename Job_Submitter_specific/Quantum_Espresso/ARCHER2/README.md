# Crystal job submitter - ARCHER2 version

[Crystal](https://www.crystal.unito.it/index.php) job submitter for [ARCHER2](https://www.archer2.ac.uk/), Slurm job scheduler. Similar to the PBS version on Imperial HPC.  

## Install

1. Use `scp -r` to upload this folder to any sub-directory of `/work/` on the cluster.  
2. Enter the folder and execute the script `setup.sh`.  
3. Following the instructions, specify the directory of job submitter and the directory of executables. 
4. Type `source ~/.bashrc` to implement user-defined commands. 

**Note**

1. All the scripts should be placed in the same directory.  
2. By default, job submitter scripts will be stored in `/work/consortium/consortium/user/runCRYSTAL/`.  
3. Due to the file transfer rule, scripts cannot be placed in `${HOME}` directory. The nodes executing calculations cannot identify directories in `${HOME}`.  
3. CRYSTAL is loaded as a module, refer to [CRYSTAL page on ARCHER2 documentation](https://docs.archer2.ac.uk/other-software/crystal/) for instructions.  

## Usage & command list

### Output and job executing information

Printed out information can be found in '.out' file and '.log' file. '.log' file is the original `slurm-[jobid].out` file processed by `post_proc_slurm`. If the script is terminated normally, the file will be named as `[jobname].log`. If killed, in its original name.

If a '.out' file with the same name as the job to be submitted exists in the same directory, that job won't be executed before output is either transferred to another folder or removed. 

### Temporary directory

* If the job is terminated due to exceeding wall time, temporary files will be saved in the output directory. The temporary directory will be removed.

* If the job is terminated due to improper settings of calculation parameters, temporary files will be saved in the output directory. The temporary directory will be removed.

* If the job is killed before 'timeout', temporary will be saved in the temporary directory with temporary names. The temporary directory will not be removed. Refer to '.out' file or '.o\<jobid\>' file for the path. 

By default, the temporary directory is set as the sub folder `tmp_[jobname]_[jobid]/`, which is in the same directory as the input/output files. 

### Work directory

Files in work directory are not backed up, and occupy storage quota - so finished jobs are recommended to be transferred to `${HOME}`. Common `cp` works on login nodes. See [ARCEHR2 manual](https://docs.archer2.ac.uk/user-guide/data/) for details. 

### Commands

Here are user defined commands: 

**NB: v1.0 update** - The 'Command-line option' fashion is implemented for input parameters. The sequence of parameters is flexible for v1.0. Only 'long options' are recognized.

1. `Pcrys` - executing parallel crystal calculations (Pcrystal and MPP)  

``` bash
$~ Pcrys -nd ND -wt WT -in jobname [-ref refname]
```

`ND`      - int, number of nodes  
`WT`      - str, walltime, hh:mm format  
`jobname` - str, name of input .d12 file  
`refname` - str, optional, name of the previous job  

Equivalent examples:

``` bash
$~ Pcrys -nd 2 -wt 02:00 -in jobname.d12 -ref previous_job
$~ ${SCRIPTDIR}/gen_sub --type crys --wt 02:00 --in jobname --ref previous_job --nd 2
```

Submit files:

``` bash
$~ sbatch jobname.slurm
```

2. `Pprop` - executing parallel properties calculations (Pproperties)

``` bash
$~ Pprop -nd ND -wt WT -in jobname -ref SCFname
``` 

`ND`      - int, number of nodes  
`WT`      - str, walltime, hh:mm format  
`jobname` - str, name of input .d3 file  
`SCFname` - str, name of the previous 'crystal' job  

Equivalent examples:

``` bash
$~ Pprop -in prop_job.d3 -ref previous_job.d12 -nd 1 -wt 00:30 
$~ ${SCRIPTDIR}/gen_sub --type prop --nd 1 --wt 00:30 --in prop_job --ref previous_job
```

Then submit files. 

3. `setcrys` - print the file `settings`. No input required.

## Script list

`setup.sh` - set up the settings file and create job submission commands.  
`settings` - store all parameters needed for CRYSTAL/PROPERTIES jobs. see the 'Keyword list' below.  
`settings_template` - empty `settings` file, will be used to cover `settings` file when installing/re-installing the job submitter.  
`gen_sub` - generate submission file.  
`Pcry_slurm` - execute 'CRYSTAL' type calculations in parallel (P and MPP).  
`Pprop_slurm` - execute 'PROPERTIES' type calculations in parallel.  
`post_processing` - Copy & save files from temporary directory to the output directory.  

**NOTE**

1. The name of file `settings` `gen_sub` `settings_template` shouldn't be changed.
2. `settings` `gen_sub` `settings_template` are applicable to Imperial HPC, comment the corresponding `sed` and `grep` sentences in `gen_sub`. 
2. Names of `Pcry_slurm` `Pprop_slurm` `post_processing` can be changed, but should corresponds to the values in `settings`.  

## Keyword list
Keywords used for the script `settings` are listed in the table below. Any change in parameters should be made in that script.

| KEYWORD                 | DEFAULT VALUE   | DEFINITION |
|:------------------------|:---------------:|:-----------|
| SUBMISSION_EXT          | .slurm          | extension of job submission script |
| NCPU_PER_NODE           | 128             | Number of processors per node |
| MEM_PER_NODE            | -               | Allocated memory per node, for Imperial cluster |
| BUDGET_CODE             | *user defined*  | Budget code of a research project, see [ARCHER2 manual](https://docs.archer2.ac.uk/user-guide/scheduler/#checking-available-budget)|
| QOS                     | standard        | Quality of service, see [ARCHER2 manual](https://docs.archer2.ac.uk/user-guide/scheduler/#quality-of-service-qos) |
| PARTITION               | standard        | Partition of jobs, see [ARCHER2 manual](https://docs.archer2.ac.uk/user-guide/scheduler/#partitions) |
| TIME_OUT                | 3               | Unit: min. Time spared for post processing |
| CRYSTAL_SCRIPT          | runcryP         | Script for crystal type calculations |
| PROPERTIES_SCRIPT       | runpropP        | Script for properties type calculations |
| POST_PROCESSING_SCRIPT  | post_processing | Post processing script |
| JOB_TMPDIR              | -               | Temporary directory for calculations |
| EXEDIR                  | -               | Directory of executables, for Imperial cluster |
| EXE_PCRYSTAL            | -               | Executable for parallel crystal type calculation, for Imperial cluster |
| EXE_MPP                 | -               | Executable for massively parallel crystal type calculation, for Imperial cluster |
| EXE_PPROPERTIES         | -               | Executable for parallel properties type calculation, for Imperial cluster |
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

## Other comments
1. File basenames are not recommended to include '.'. If so, the '.d12/.d3' extensions should be included when using the `-in` flag - otherwise the 'file not found error' might be reported because the code obtains the basename by truncating the characters after the last '.'.  
2. A new value for the same flag covers the previous one. For example, `Pcrys -type prop` is equivalent to `Pprop`. Due to the same reason, the current implementation does not support the 'multiple `-in` / multiple `-ref`' definitions similar to the CX1 general submitter. This feature might be added in future releases.

