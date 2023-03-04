# General job submitter for Imperial CX1

A general job submission script for parallel programs for the PBS batch system on [Imperial CX1](https://www.imperial.ac.uk/admin-services/ict/self-service/research-support/rcs/), or more generally, Imperial HPC, since the current domain is 'cx3'. Based on Linux Bash Shell.

## Quick reference

### Commands and corresponding in-line flags

**Nomenclature**  

Upper case letter(s) for job definition + lower case letters for executable + version number

Here the configuration of 'CRYSTAL17' is used as the example. 

| COMMAND    | FLAGS                                         | DEFINITION                                               |
|:-----------|:---------------------------------------------:| :--------------------------------------------------------|
| Pcrys17    | -in -nd -wt -ref(Optional)                    | Run parallel CRYSTAL17 executable                        |
| MPPcrys17  | -in -nd -wt -ref(Optional)                    | Run massive parallel CRYSTAL17 executable                |
| Scrys17    | -in -nd -wt -ref(Optional)                    | Run sequential CRYSTAL17 executable                      |
| Xcrys17    | -x -in -nd -wt -ref(Optional) -name(Optional) | Run user-defined multiple jobs (see advanced section)    |
| SETcrys17  | No flag                                       | Print the local (user-defined) 'settings' file on screen |
| HELPcrys17 | No flag                                       | Print instructions on screen                             |

### Command-line flags

In the table below are listed command line flags for script `gen_sub`. The sequence of flags is arbitrary.

| FLAG  | FORMAT | DEFINITION                                                               |
|:------|:------:| :------------------------------------------------------------------------|
| -x    | string | Executable label, see the 'EXE_TABLE' of settings file                   |
| -in   | string | The main input file                                                      |
| -nd   | int    | Number of nodes requested for the job                                    |
| -wt   | hh:mm  | Walltime requested for the job                                           |
| -ref  | string | The common basename (without extensions) of reference files              |
| -name | string | The name of qsub file                                                    |
| -set  | string | The path of settings file, developer only                                |
| -help | string | Print instructions. Already integrated in command `HELPcrys17`           |

### Keywords and default values

Parameters are defined in local 'settings' file. By default it is in `${HOME}/etc/runCRYSTAL17/` directory (CRYSTAL17 as an example).

| KEYWORD                   | DEFAULT VALUE   | DEFINITION                                                            |
|:--------------------------|:---------------:|:----------------------------------------------------------------------|
| SUBMISSION\_EXT           | .qsub           | The extension of job submission script                                |
| NCPU\_PER\_NODE           | 24              | Number of processors per node                                         |
| MEM\_PER\_NODE            | 50              | Unit: GB. Requested memory per node                                   |
| N\_THREAD                 | 1               | Number of threads. Multi-threading within 1 CPU is prohibited         |
| NGPU\_PER\_NODE           | 0               | Number of GPUs per node                                               |
| GPU\_TYPE                 | RTX6000         | The default type of GPU                                               |
| BUDGET\_CODE              | -               | For ARCHER2. Not used                                                 |
| QOS                       | -               | For ARCHER2. Not used                                                 |
| PARTITION                 | -               | For ARCHER2. Not used                                                 |
| TIME\_OUT                 | 3               | Unit: min. Time spared for post processing                            |
| JOB\_TMPDIR               | \[depends\]     | The temporary directory for data files generated during a job         |
| EXEDIR                    | \[depends\]     | Directory of executable / Module load command                         |
| MPIDIR                    | \[depends\]     | Directory of MPI / Module load command                                |
| EXE\_TABLE                | \[Table\]       | Label (for -x flag) + MPI & executable option combinations            |
| PRE\_CALC                 | \[Table\]       | Saved and temporary names of input files (see following sections)     |
| REF\_FILE                 | \[Table\]       | Saved and temporary names of reference files (see following sections) |
| POST\_CALC                | \[Table\]       | Saved and temporary names of output files (see following sections)    |
| JOB\_SUBMISSION\_TEMPLATE | \[script\]      | Template for job submission scripts                                   |

## New user: Basic instructions

### Configure the job submission script

Taking 'CRYSTAL17' as the example. The following steps are necessary to set up a local 'settings' file, where values of keywords are configured according to your local environment:

1. Execute the following command and launch the script. Change `CRYSTAL17/config_CRYSTAL17.sh` accordingly if another executable is to be used. The path is consistent with this GitHub repo.  

``` console
~$ bash /rds/general/user/hz1420/home/GitHub/crystal_shape_control/Imperial-HPC-Job-Submission/CRYSTAL17/config_CRYSTAL17.sh
```

2. Specify the directory of 'settings' file. By default, it is `${HOME}/etc/runCRYSTAL17/settings`.  
3. Specify the directory of executable. Typically default value is sufficient. Press 'Enter' to continue.  
4. Specify the directory of MPI executable. Typically default value is sufficient. Press 'Enter' to continue.  
5. After the instruction is printed out, use the following command to enable commands:

```
~$ source ~/.bashrc
```

### Use commands

After configuration, commands to generate the corresponding job submission file (qsub file) are defined in `~/.bashrc`. It is important to **rerun the `source ~/.bashrc`** command every time the user logs in. Detailed definitions of commands can be found in the previous section and by `HELPcrys17` command. For example, the following command generates and submits a qsub file for input file 'mgo.d12'. The job uses 1 node and the maximum time allowance for this job is 1 hour:

``` console
~$ Pcrys17 -in mgo.d12 -nd 1 -wt 01:00
~$ qsub mgo.qsub
```

It is highly recommended to generate .qsub files in the same directory as input files, though in principle, the user can generate .qsub files and get .e`${PBS_JOBID%.*}` and .o`${PBS_JOBID%.*}` files in a separate directory. This feature is rarely tested and might lead to unexpected results - and somewhat meaningless because all the job-related files, including .out file, are stored in the input directory.  

### Common Outputs

Although parallel codes differ from each other, 3 common outputs are generated. 

**.out file**  
Output information of the code, CRYSTAL17, for example. Also includes the input file and basic information from the job submission script, such as the path to the ephemeral directory and files copied.

**.o`${PBS_JOBID%.*}` file**  
A verbose version output (that should be printed on screen) of job submission script & MPI, for debugging. Besides the basic information included in .out file, it includes the list of scripts and commands used, synchronization of files and the list of files in the ephemeral directory.

**.e`${PBS_JOBID%.*}` file**   
Error and warning messages (that should be printed on screen) from PBS system and the code. For debugging.

### When a job terminates

There are 4 probable occasions of job termination. If an ephemeral directory is defined, i.e., 'JOB_TMPDIR' in 'settings' is not 'nodir', temporary files generated during calculation might be either in the output directory or in the ephemeral directory.

1. For normal termination, all the non-empty files are kept in the output directory, with 'SAVED' names. The ephemeral directory will be removed.  
2. If the job is terminated due to exceeding walltime, same as normal termination.  
3. If the job is terminated due to error, same as normal termination.  
4. If the job is killed by user, the ephemeral directory remains intact. The user can refer to '.out' file or '.o`${PBS_JOBID%.*}`' file for the path to ephemeral directory and manually move them to output directory. Note that all the inputs are copied from the same directory so there is not need to copy inputs back.  

### How to use settings file

The 'settings' file is a dictionary for reference. Although all the necessary keywords are configured automatically, the user can always change the value of keywords according to their needs. Refer to advanced section for more information.


## Experienced user & Developer: Advanced instructions

### Multiple jobs and 'X' command

The 'X' command allows the maximum flexibility for users to define a PBS job. Taking CRYSTAL17 as the example, using `Xcrys17` can sequentially run multiple jobs. The following code illustrates how to integrate SCF and band calculations of mgo into a single qsub file:

``` console
~$ Xcrys17 -name mgo-band -nd 1 -x pcrys -in mgo.d12 -wt 01:00 -ref no -x pprop -in band.d3 -wt 00:30 -ref mgo
```

To run `Xcrys17` command, the number of in-line flags should follow certain rules:

1. `-name` flag should appear at most only once, otherwise the last one will cover the previous entries. If left blank, the qsub file will be named as `mgo_et_al.qsub` (taking the previous line as an example).  
2. `-nd` flag is mandatory and should appear once.  
3. `-x` `-in` `-wt` flags should be always in the same length, otherwise error is reported. 
4. `-wt` flag defines the walltime for individual jobs. For each job, by default 3 minutes are spared for post-processing. Check the 'TIME_OUT' keyword in settings file.   
5. `-ref` flags should have either 0 length or the same length as `-x`. If no reference is needed, that flag should be matched with value 'no'. See the line above.  

When job terminates, the output of each calculation is available in corresponding .out files. If input files have the same name, for example, mgo.d12 and mgo.d3, the output will be attached in the same .out file, i.e., mgo.out, with a warning message dividing the files. Check [testcase of CRYSTAL17](https://github.com/cmsg-icl/crystal_shape_control/tree/main/Imperial-HPC-Job-Submission/CRYSTAL17/testcase). On the other hand, PBS-related outputs, .qsub, .e`${PBS_JOBID%.*}` and .o`${PBS_JOBID%.*}` files, are defined by the `-name` flag.

### Edit the local 'settings' file

In the current implementation, 'settings' is the only file in local environment, which can be edited by the user according to needs. When formatting the 'settings' file, please be noted:

1. Empty lines between keywords and their values are forbidden.  
2. For CPU only jobs, 'NGPU' should always be 0, in which case no GPU-related PBS keyword is printed in .qsub file.  
3. Multiple-line values for keywords other than 'EXE\_TABLE', 'PRE\_CALC', 'FILE\_EXT', 'POST\_CALC' and 'JOB\_SUBMISSION\_TEMPLATE' are forbidden.  
4. Dashed lines and titles for 'table' keywords are used as separators and are not allowed to be removed.  
5. The qsub template attached during initialization is only compatible with the default settings. For user-defined executables, changes might be made accordingly in 'JOB\_SUBMISSION\_TEMPLATE'.

**JOB\_TMPDIR**

3 options are available for this keywords:

1. Left blank for 'default' : The temporary directory will be created as a sub-directory in the input directory, with name 'jobname\_`${PBS_JOBID%.*}`/'  
2. 'nodir' : The job will be run in the current directory and no copy/delete happens. Applicable if the code has bulit-in temporary file management system or requires minimum I/O (usually the case for serial jobs).
3. A given directory, such as `${EPHEMERAL}` : The temporary directory will be created as a sub-directory under the given one, with the name 'jobname\_`${PBS_JOBID%.*}`/'.

**EXE\_TABLE** 
For each job submission script, multiple executables can be placed in the same directory, 'EXEDIR'. The corresponding commands to launch the executables are listed in 'EXE\_TABLE'. The following table gives information of each column. 

| NAME                | RECOGNIZABLE LENGTH | EXPLANATION                                                               |
|:--------------------|:-------------------:| :-------------------------------------------------------------------------|
| LABEL               | 11                  | Alias of MPI+executable combination. Input of `-x` flag. No space allowed |
| MPI & OPTION        | 21                  | In-line commands of MPI, such as 'mpiexec'                                |
| EXECUTABLE & OPTION | 31                  | In-line commands of executable, such as 'gulp-mpi < \[jobname\].gin'      |
| DEFINITION          | Not read            | Definitions for reference                                                 |

**PRE\_CALC, REF\_FILE and POST\_CALC**

Both tables function as file references before computation. Files with the same name as input file (the value of `-in` flag) should be listed in 'PRE\_CALC' and the input reference (`-ref` flag) should be listed in 'REF\_FILE'. The 'SAVED' column specifies the file names in input directory, while 'TEMPORARY' specifies the file names in ephemeral directory. Lengths of both 'SAVED' and 'TEMPORARY' columes should be 21 characters to ensure the values can be read. The 'DEFINITION' column will not be scanned. This part is skipped if 'JOB_TMPDIR' is 'nodir'.

In practice, `run_exec` and `post_proc` scan all the formats listed and moves all the matching files forward and backward. Missing files will in any case not lead to abruption of jobs since file existence has been checked when generating qsub files. However, the priority changes when duplicate files are found in distination directory (ephemeral for 'PRE\_CALC' and 'REF\_FILE', input for 'POST\_CALC'). In all cases, that would lead to a warning message in both .out and .o`${PBS_JOBID%.*}` files

1. When duplicate file is defined in 'PRE\_CALC', `run_exec` will cover the old one with the new entry, unless the old one is the file specified by `-in` flag.  
2. When duplicate file is defined in 'REF\_FILE', `run_exec` will ignore the new entry and keep the old one.  
3. When duplicate file is defined in 'POST\_CALC', `post_proc` will cover the old one with the new entry  

**A 'pesudo' regular expression scheme**

To ensure the generality, a 'pseudo' regular expression is used. Note that not all the sym

| SYMBOL      | Definition                                                                                  |
|:------------|:--------------------------------------------------------------------------------------------|
| \[jobname\] | Value of `-in` flag without extension and upper-level folder                                | 
| \[refname\] | Value of `-ref` flag without extension and upper-level folder                               |
| \*          | Match any character for any times. A single '*' in destination means keep the original name |
| /           | Creat a folder rather than copy as files                                                    |

Note:

1. Typically the 'text\*' expression is used in source directory and '/' and '\*' are used in destination directory.  
2. In 'SAVED' colume, both 'PRE\_CALC' and 'POST\_CALC' allow \[jobname\] only, while 'REF\_FILE' allows \[refname\] only.


### Structure of the repository

Scripts in the main folder, i.e., `gen_sub`, `run_exec`, `post_proc` and `settings_template` are common scripts for job submission and post processing, of which the first 3 are executable. `settings_template` will be named as `settings` after being configured.

`gen_sub` - Process the options in command line, execute necessary checks (file existence, walltime and node format) and generate the qsub file.  
`run_exec` - Move and rename input files from the home directory to the ephemeral directory, sync nodes and launch (usually) parallel jobs.  
`post_proc` - Save output files to the home directory and remove the ephemeral directory.  
`settings_template` - A formatted empty list of keywords. It will be configured when running configure scripts such as `config_CRYSTAL17.sh`.

In the sub-folders with specific names of simulation codes. Taking CRYSTAL17 as the example, the configuration file is `config_CRYSTAL17.sh`, which is called during installation. The `run_help` script (a rather easy one) is launched by `HELPcrys17` command. The `settings_example_CRYSTAL17` gives an example of configured settings file and the `testcase` directory contains an example run on IC-CX1.

The basic principle of this job submission script is illustrated in the figure below:

![The Structure of Job Submitter](structure.svg)

### How to generate a configuration file

Configurations scripts `config_CODE.sh` and help information `run_help` (a rather simple one) are code-specific so are stored separately in sub-folders with code names. Typically the core sriptes `gen_sub` `run_exec` and `post_proc` do not need revision unless bug is identified. Examples (`config_example_CRYSTAL17.sh` and `run_help_example_CRYSTAL17`) are placed in the main directory for illustrating proposes. Lines need modification are marked with comment lines `#---- BEGIN_USER ----#`, `#---- END_USER ----#`. Several considerations suggested:

1. Title line and version number  
3. Script directory: The default directory  
4. Executable directory: The default executable directory or `module load` command  
5. MPI directory: The default executable directory or `module load` command   
6. Default parameters for parallel jobs: Cores per node and GPUs (if necessary)  
7. EXE\_TABLE: The correct in-line commands to launch the job and a simple alias for it  
8. PRE\_CALC: General format of inputs  
9. FILE\_EXT: General format of references  
10. POST\_CALC: General format of outputs  
11. JOB\_SUBMISSION\_TEMPLATE: Specific environmental setups for the code, such as other modules needed (especially when the code is dynamically linked), or important environmental variables if the executable is directly called  
12. Alias: Check the nomenclature of commands in quick reference

## Program specific instructions

### CRYSTAL17

*Author: Spica. Vir.*

**Default settings file**

${HOME}/etc/runCRYSTAL17/settings

**Default executable**

Version 1.0.2 compiled with mpich 3.4.3 and gcc 6.2.0

| LABEL   | ACTUAL IN-LINE COMMAND |
|:-------:|:-----------------------|
| pcrys   | mpiexec Pcrystal       | 
| mppcrys | mpiexec MPPcrystal     |
| pporp   | mpiexec Pproperties    |
| scrys   | crystal < INPUT        |
| sprop   | properties < INPUT     |

**Default ephemeral directory**

${EPHEMERAL}

**Commands**  
`Pcrys17` `MPPcrys17` `Pprop17` `Scrys17` `Sprop17` `Xcrys17` `SETcrys17` `HELPcrys17`

**Command used for testcase**

``` console
~$ Xcrys17 -name graphene-band -nd 1 -x pcrys -in graphene.d12 -wt 00:40 -ref no -x pprop -in graphene.d3 -wt 00:20 -ref graphene
```

### CRYSTAL23

*Author: Spica. Vir. Testing: K. Tallat-Kelpsa*

**Default settings file**

${HOME}/etc/runCRYSTAL23/settings

**Default executable**

Version 1.0.1 compiled with openmpi 4.1.4, AMD aocc 4.0.0 and AMD aocl 4.0

All executables are compiled with multi-threading.

| LABEL   | ACTUAL IN-LINE COMMAND |
|:-------:|:-----------------------|
| pcrys   | mpiexec Pcrystal       | 
| mppcrys | mpiexec MPPcrystal (Currently unavailable) |
| pporp   | mpiexec Pproperties    |
| scrys   | crystal < INPUT        |
| sprop   | properties < INPUT     |

**Default ephemeral directory**

${EPHEMERAL}

**Commands**  
`Pcrys23` `MPPcrys23` `Pprop23` `Scrys23` `Sprop23` `Xcrys23` `SETcrys23` `HELPcrys23`

**Command used for testcase**

``` console
~$ Scrys23 -nd 1 -in molecule-omp.d12 -wt 01:00
```

Note that this is also an illustruction of multi-threading feature of CRYSTAL23. Since a serial executable is used, the 'ompthreads' and 'OMP_NUM_THREADS' are changed to 24, while 'mpiproc' and 'NPROCESSES' are 1.

### [GULP6](http://gulp.curtin.edu.au/gulp/)

*Author: Spica. Vir.*

**Default settings file**

${HOME}/etc/runGULP6/settings

**Default executable**

Version 6.1.2 compiled with mpi/intel-2019 and intel-suite/2019.4. With PLUMED 2.8.1

| LABEL   | ACTUAL IN-LINE COMMAND             |
|:-------:|:-----------------------------------|
| pgulp   | mpiexec gulp-mpi < \[jobname\].gin | 

**Default ephemeral directory**

${EPHEMERAL}

**Commands**  
`Pglp6` `Xglp6` `SETglp6` `HELPglp6`

**Command used for testcase**

``` console
~$ Pglp6 -in example10-free-300K0G.gin -nd 1 -wt 01:00
```