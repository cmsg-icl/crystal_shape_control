# General job submitter for Lab Servers

A general job submission script for parallel programs for desktop servers without a batch system. Based on Linux Bash Shell.

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

In the table below are listed command line flags for script `run_job`. The sequence of flags is arbitrary.

| FLAG  | FORMAT | DEFINITION                                                               |
|:------|:------:| :------------------------------------------------------------------------|
| -x    | string | Executable label, see the 'EXE\_TABLE' of settings file                  |
| -in   | string | The main input file                                                      |
| -np   | int    | Number of processes                                                      |
| -nt   | int    | Number of threads. Default = 1                                           |
| -ref  | string | The common basename (without extensions) of reference files              |
| -name | string | The name of qsub file                                                    |
| -set  | string | The path of settings file, developer only                                |
| -help | string | Print instructions. Already integrated in command `HELPcrys17`           |

Note that multi-threading set-ups is at 'thread' level, which means the maximum thread of processor can be utilized.

### Keywords and default values

Parameters are defined in local 'settings' file. By default it is in `${HOME}/etc/runCRYSTAL17/` directory (CRYSTAL17 as an example). Other keywords in the template will not be read.

| KEYWORD                   | DEFAULT VALUE   | DEFINITION                                                            |
|:--------------------------|:---------------:|:----------------------------------------------------------------------|
| JOB\_TMPDIR               | \[depends\]     | The temporary directory for data files generated during a job         |
| EXEDIR                    | \[depends\]     | Directory of executable / Module load command                         |
| MPIDIR                    | \[depends\]     | Directory of MPI / Module load command                                |
| EXE\_TABLE                | \[Table\]       | Label (for -x flag) + MPI & executable option combinations            |
| PRE\_CALC                 | \[Table\]       | Saved and temporary names of input files (see following sections)     |
| REF\_FILE                 | \[Table\]       | Saved and temporary names of reference files (see following sections) |
| POST\_CALC                | \[Table\]       | Saved and temporary names of output files (see following sections)    |

## New user: Basic instructions

### Configure the job submission script

Taking 'CRYSTAL17' as the example. The following steps are necessary to set up a local 'settings' file, where values of keywords are configured according to your local environment:

1. Execute the following command and launch the script. Change `CRYSTAL17/config_CRYSTAL17.sh` accordingly if another executable is to be used. The path is consistent with this GitHub repo.  

``` console
~$ bash ~/GitHub/crystal_shape_control/NHPC101-Job-Submission/CRYSTAL17/config_CRYSTAL17.sh
```

2. Specify the directory of 'settings' file. By default, it is `${HOME}/etc/runCRYSTAL17/settings`.  
3. Specify the directory of executable. Typically default value is sufficient. Press 'Enter' to continue.  
4. Specify the directory of MPI executable. Typically default value is sufficient. Press 'Enter' to continue.  
5. After the instruction is printed out, use the following command to enable commands:

``` console
~$ source ~/.bashrc
```

### Use commands

After configuration, commands to generate the corresponding job submission file (qsub file) are defined in `~/.bashrc`, which is automatically run every time the user logs in. Detailed definitions of commands can be found in the previous section and by `HELPcrys17` command. For example, the following command runs a CRYSTAL17 job for 'mgo.d12'. The job uses 4 processes and 1 thread per process. Different from shared computation resources, no walltime is set.

``` console
~$ Pcrys17 -in mgo.d12 -np 4
```

It is highly recommended to run jobs in the same directory as input files, though in principle, the user can submit jobs from a separate directory. This feature is rarely tested and might lead to unexpected results - and somewhat meaningless because all the job-related files, including output and log files, are stored with the input.  

### Common Outputs

Although parallel codes differ from each other, 3 common outputs are generated. 

**.out file**  
Output information of the code, CRYSTAL17, for example. Also includes the input file and basic information from the job submission script, such as the path to the ephemeral directory and files copied.

**.log file**  
A verbose version output (that should be printed on screen) of job submission script & MPI, for debugging. It includes the list of scripts and commands used, synchronization of files, the list of files in the ephemeral directory and potential error messages. The main output from software is not included.

### When a job terminates

There are 4 probable occasions of job termination. If an ephemeral directory is defined, i.e., 'JOB\_TMPDIR' in 'settings' is not 'nodir', temporary files generated during calculation might be either in the output directory or in the ephemeral directory.

1. For normal termination, all the non-empty files are kept in the output directory, with 'SAVED' names. The ephemeral directory will be removed.   
3. If the job is terminated due to error, same as normal termination.  
4. If the job is killed by user, the ephemeral directory remains intact. The user can refer to '.out' file or '.log' file for the path to ephemeral directory and manually move them to output directory. Note that all the inputs are copied from the same directory so there is not need to copy inputs back.  

### How to use settings file

The 'settings' file is a dictionary for reference. Although all the necessary keywords are configured automatically, the user can always change the value of keywords according to their needs. Refer to advanced section for more information.

## Experienced user & Developer: Advanced instructions

### Multiple jobs and 'X' command

The 'X' command allows the maximum flexibility for users to define a job. Taking CRYSTAL17 as the example, using `Xcrys17` can sequentially run multiple jobs. The following code illustrates how to integrate SCF and band calculations of mgo into a single qsub file:

``` console
~$ Xcrys17 -name mgo-band -np 4 -x pcrys -in mgo.d12 -ref no -x pprop -in band.d3 -ref mgo
```

To run `Xcrys17` command, the number of in-line flags should follow certain rules:

1. `-name` flag should appear at most only once, otherwise the last one will cover the previous entries. If left blank, the qsub file will be named as `mgo_et_al.qsub` (taking the previous line as an example).  
2. `-np` flag is mandatory and should appear once.
3. `-nt` flag, if not set, is 1. If to be set, it should appear once.    
4. `-x` `-in` flags should be always in the same length, otherwise error is reported.    
5. `-ref` flags should have either 0 length or the same length as `-x`. If no reference is needed, that flag should be matched with value 'no'. See the line above.  

When job terminates, the output of each calculation is available in corresponding .out and .log files. If input files have the same name, for example, mgo.d12 and mgo.d3, the output will be attached in the same .out file, i.e., mgo.out, with a warning message dividing the files. Check [testcase of CRYSTAL17 on CX1](https://github.com/cmsg-icl/crystal_shape_control/tree/main/Imperial-HPC-Job-Submission/CRYSTAL17/testcase).

### Edit the local 'settings' file

In the current implementation, 'settings' is the only file in local environment, which can be edited by the user according to needs. When formatting the 'settings' file, please be noted:

1. Empty lines between keywords and their values are forbidden.  
3. Multiple-line values for keywords other than 'EXE\_TABLE', 'PRE\_CALC', 'FILE\_EXT' and 'POST\_CALC' are forbidden.  
4. Dashed lines and titles for 'table-like' keywords are used as separators and are not allowed to be removed.  

**JOB\_TMPDIR**

3 options are available for this keywords:

1. Left blank for 'default' : The temporary directory will be created as a sub-directory in the input directory, with name 'jobname\_tmpdir/'  
2. 'nodir' : The job will be run in the current directory and no copy/delete happens. Applicable if the code has bulit-in temporary file management system or requires minimum I/O (usually the case for serial jobs). Job and post-processing scripts are named as 'Job_script_jobname' and 'Post_script_jobname', which will be removed at the end of the job.  
3. A given directory, such as `/tmp` : The temporary directory will be created as a sub-directory under the given one, with the name 'jobname\_tmpdir/'.

**EXE\_TABLE** 
For each job submission script, multiple executables can be placed in the same directory, 'EXEDIR'. The corresponding commands to launch the executables are listed in 'EXE\_TABLE'. The following table gives information of each column. 

| NAME                | RECOGNIZABLE LENGTH | EXPLANATION                                                               |
|:--------------------|:-------------------:| :-------------------------------------------------------------------------|
| LABEL               | 11                  | Alias of MPI+executable combination. Input of `-x` flag. No space allowed |
| MPI & OPTION        | 61                  | In-line commands of MPI, such as 'mpiexec'.                               |
| EXECUTABLE & OPTION | 61                  | In-line commands of executable, such as 'gulp-mpi < \[jobname\].gin'      |
| DEFINITION          | Not read            | Definitions for reference                                                 |

Variable symbols `${V_VARIABLE}` defined under keyword 'JOB\_SUBMISSION\_TEMPLATE' are, in principle, compatible in 'MPI & OPTION' and 'EXECUTABLE & OPTION' columns. But such practice is not recommended to keep the structure clear and consistent. For example, to bring the number of processes defined in command line into the mpi commands, one can use `${V_NP}`, such as `mpiexec -np ${V_NP}`.

**PRE\_CALC, REF\_FILE and POST\_CALC**

Both tables function as file references before computation. Although 'PRE\_CALC' and 'REF\_FILE' share almost the same rules (see below), it is recommended that files with the same name as input file (the value of `-in` flag) should be listed in the former and the input reference (`-ref` flag) listed in the latter. The 'SAVED' column specifies the file names in input directory, while 'TEMPORARY' specifies the file names in ephemeral directory. Lengths of both 'SAVED' and 'TEMPORARY' columes should be 21 characters to ensure the values can be read. The 'DEFINITION' column will not be scanned. This part is skipped if 'JOB\_TMPDIR' is 'nodir'.

In practice, `run_job` scans all the formats listed and moves all the matching files forward and backward. Missing files will in any case not lead to abruption of jobs since file existence has been checked when generating qsub files. However, the priority changes when duplicate files are found in distination directory (ephemeral for 'PRE\_CALC' and 'REF\_FILE', input for 'POST\_CALC'). In all cases, that would lead to a warning message in both .out and .log files:

1. When duplicate file is defined in 'PRE\_CALC', the old one in the destination folder is covered by the new entry, unless the old one is the file specified by `-in` flag.  
2. When duplicate file is defined in 'REF\_FILE', the new entry is ignored and the old one is kept.  
3. When duplicate file is defined in 'POST\_CALC', the old one is covered by the new entry.  

**A 'pesudo' regular expression scheme**

To ensure the generality, a 'pseudo' regular expression is used. Note that not all the sym

| SYMBOL  | Definition                                                                                   |
|:--------|:---------------------------------------------------------------------------------------------|
| \[job\] | Value of `-in` flag without extension and upper-level folder                                 | 
| \[ref\] | Value of `-ref` flag without extension and upper-level folder                                |
| \*      | Match any character for any times. A single '\*' in destination means keep the original name |
| /       | Creat a folder rather than copy as files                                                     |

Note:

1. Typically the 'text\*' expression is used in 'SAVED' column and '\*' is used in 'TEMPORARY' column. '/' can be used in both.  
2. In 'SAVED' colume, both 'PRE\_CALC' and 'POST\_CALC' allow \[job\] only, while 'REF\_FILE' allows \[ref\] only.  
3. In practice, any text begins with \[job or \[ref and ends with \] are recognized and substituted. In fact, in files configured eariler, keywords \[jobname\] and \[refname\] were used. New keywords are adopted to spare space for command options.  
4. In principle, \[job\] and \[ref\] can be placed at any part of the file name, but it is strongly recommended to keep them as the 1st part of the file name to keep the consistency.

**`${V_VARIABLE}`**

Variable symbols `${V_VARIABLE}` were defined in CX1 and ARCHER2 job sumbission scripts to generate inputs for batch systems. The only one that has been used here is defined below.

| SYMBOL         | Definition      |
|:---------------|:----------------|
| `${V_ND}`      | Number of nodes |

### Structure of the repository

Scripts in the main folder, i.e., `run_job` and `settings_template` are common scripts for job submission and post processing, of which the former is executable. `settings_template` will be named as `settings` after being configured.

`run_exec` - Process the options in command line, run necessary checks (file existence, walltime and node format), move and rename input files from the home directory to the ephemeral directory and launch (usually) parallel jobs.  
`settings_template` - A formatted empty list of keywords. It will be configured when running configure scripts such as `config_CRYSTAL17.sh`.  
`version_control.txt` - Information of version numbers and authorship.

In the sub-folders with specific names of simulation codes. Taking CRYSTAL17 as the example, the configuration file is `config_CRYSTAL17.sh`, which is called during installation. The `run_help` script (a rather easy one) is launched by `HELPcrys17` command. The `settings_example_CRYSTAL17` gives an example of configured settings file and the `testcase` directory contains an example run on IC-CX1.

### How to generate a configuration file

Configurations scripts `config_CODE.sh` and help information `run_help` (a rather simple one) are code-specific so are stored separately in sub-folders with code names. Typically the core sriptes `gen_sub` `run_exec` and `post_proc` do not need revision unless bug is identified. Examples (`config_example_CRYSTAL17.sh` and `run_help_example_CRYSTAL17`) are placed in the main directory for illustrating proposes. Lines need modification are marked with comment lines `#---- BEGIN_USER ----#`, `#---- END_USER ----#`. Several considerations suggested:

1. Title line and version number, which should be provided in a separate file [version\_control.txt](https://github.com/cmsg-icl/crystal_shape_control/tree/main/NHPC101-Job-Submission/version_control.txt), which has clear instructions for reference.  
4. Executable directory: The default executable directory or `module load` command  
5. MPI directory: The default executable directory or `module load` command   
7. EXE\_TABLE: The correct in-line commands to launch the job and a simple alias for it  
8. PRE\_CALC: General format of inputs  
9. REF\_FILE: General format of references  
10. POST\_CALC: General format of outputs  
12. Alias: Check the nomenclature of commands in quick reference

## Program specific instructions

### CRYSTAL17

*Author: Spica. Vir.*

**Default settings file**

${HOME}/etc/runCRYSTAL17/settings

**Default executable**

Version 1.0.2 compiled with mpich 3.4.3 and gcc 6.2.0
Version 1.0.1 compiled with Intel OneAPI 2023.1.0

| LABEL   | ACTUAL IN-LINE COMMAND |
|:-------:|:-----------------------|
| pcrys   | mpiexec Pcrystal       | 
| mppcrys | mpiexec MPPcrystal     |
| pporp   | mpiexec Pproperties    |
| scrys   | crystal < INPUT        |
| sprop   | properties < INPUT     |

**Default ephemeral directory**

default

**Commands**  
`Pcrys17` `MPPcrys17` `Pprop17` `Scrys17` `Sprop17` `Xcrys17` `SETcrys17` `HELPcrys17`

### CRYSTAL23

*Author: Spica. Vir.*

**Default settings file**

${HOME}/etc/runCRYSTAL23/settings

**Default executable**

Version 1.0.1 compiled with Intel OneAPI 2023.1.0

All executables are compiled with multi-threading.

| LABEL   | ACTUAL IN-LINE COMMAND              |
|:-------:|:------------------------------------|
| pcrys   | mpiexec -np ${V\_TPROC} Pcrystal    | 
| mppcrys | mpiexec -np ${V\_TPROC} MPPcrystal  |
| pporp   | mpiexec -np ${V\_TPROC} Pproperties |
| scrys   | crystal < INPUT                     |
| sprop   | properties < INPUT                  |

**Default ephemeral directory**

default

**Commands**  
`Pcrys23` `MPPcrys23` `Pprop23` `Scrys23` `Sprop23` `Xcrys23` `SETcrys23` `HELPcrys23`
