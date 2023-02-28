# General job submitter for Imperial CX1

A general job submitter for parallel programs on [Imperial CX1](https://www.imperial.ac.uk/admin-services/ict/self-service/research-support/rcs/), PBS job scheduler. Based on Linux Bash Shell.

[toc]

## Structure of the repository

Scripts in the main folder, i.e., `gen_sub`, `settings_template`, `run_exec`, and `post_proc` are shared scripts for job submission and post processing, which will be configured and placed in the directory specified during installation. `settings_template` will be named as `settings` after being configured.

* `gen_sub` - Process the options specified in command line, execute necessary checks (file existence, walltime and node format), and generate the '.qsub' file.  
* `run_exec` - Process the options for parallel programs, move and rename input files from the home directory to the ephemeral directory, sync nodes, execute the mpi command to launch parallel jobs.  
* `post_proc` - Save output files from the ephemeral directory to the home directory and remove the ephemeral directory to save disk space.  
* `settings_template` - An empty list of keywords, which sets values of program-dependent parameters. It will be referred by other scripts after being initialized.

In the sub-folders with specific names of simulation codes, there are configuration files named as `config_CODE.sh`, which is the script for installation. The `settings_example_CODE` gives a example of setups.

The structure of this general job submitter is illustrated in the figure below:

![The Structure of Job Submitter](structure.svg)

## Install

1. Use `scp` to upload 4 general scripts and a specific configuration script `config_CODE.sh` to `${HOME}` on the cluster.  
2. Execute the script: `bash config_CODE.sh`.  
3. Following the instructions, specify the directory of the job submitter and the directory of executables, or module loading command.  
4. Type `source ~/.bashrc` to implement user-defined commands. 

**Note**

1. All the scripts should be placed in the same directory.  
2. By default, job submitter scripts will be stored in `${HOME}/runCODE/`.  

## General instructions

This job submitter is useful for jobs launched by a constant parallel executable, i.e., multiple jobs with the same command is supported, but any job involving multiple commands is not. Besides, it is only useful for jobs launched by a 'main' input file. Other file inputs is allowed either as mandatory or optional files, but only one file can be used to define an `-in` flag (see below).

For the 'main' input file used for `-in` flag, the convention is that its name should have an extension, while its basename is used to define the jobname. The full name should be the input of `-in`, and the program truncates text on the right side of the last full stop '.'.  

### User defined commands

The `config_CODE.sh` code sets user defined commands (command aliases) in file `~/.bashrc` during initialization. Commands include a `Pcode` command to generate .qsub files for the specific code and a `setcode` command to print out the `settings` file. The block configuring command aliases begins with `# >>> CODE job submitter settings >>>` and ends with `# <<< finish GROMACS job submitter settings <<<`, which function as separators and should not be removed. To activate command aliases, use this command every time when logging in:

``` console
~$ source ~/.bashrc
```

### Command line flags

The script adopts the command-line options to launch jobs. The general flags include:

| FLAG | FORMAT | DEFINITION                                                               |
|:-----|:------:| :------------------------------------------------------------------------|
| -in  | string | The main input file                                                      |
| -ref | string | Optional, the common basename of reference files                         |
| -nd  | int    | The number of nodes requested for the job                                |
| -wt  | hh:mm  | The walltime requested for the job                                       |
| --   | (NA)   | The separator, followed by other command line options for the executable |

### Multiple jobs

This job submitter supports multiple jobs, as long as they uses the same 'mpi + executable + options' pair. To achieve this, all the main inputs and reference files should be put into the same directory - sub-directory is not permitted. Multiple jobs should be launched with the following command:

``` console
~$ Pcode -in jobA.input -ref jobA_prejob -in jobB.input -ref jobB_prejob -nd 1 -wt 01:00
```

The sequence of flags is arbitrary. Note that the length of flag `-ref` should be either 0 or the same length as `-in` to avoid ambiguity, which means the multiple job option is more suitable for 'parallel' jobs rather than 'sequential' jobs, e.g., SCF jobs for different systems, rather than 1 geometry optimization + 1 SCF. The latter one, of course, is possible. In .qsub file, an extra line can be added between 2 jobs to copy and rename the output of a previous job as an optional input of the next job. 

The generated .qsub file is named as `jobA-jobB.qsub`. The maximum length of its basename is 20 characters. All the outputs defined in 'POST\_CALC' table and the .out file (see below) will be stored separately, e.g., as `jobA.out` and `jobB.out`. The .o\[pbsjobid\] and .e\[pbsjobid\] files (see below) are shared by both jobs, named as `jobA-jobB.o\[pbsjobid\]` and `jobA-jobB.e\[pbsjobid\]`.

### Keyword list

Keywords used for `settings_template` are listed in the table below. Modify the values in the same file to change the parameters used during computation.

| KEYWORD                   | DEFAULT VALUE   | DEFINITION |
|:--------------------------|:---------------:|:-----------|
| SUBMISSION\_EXT           | .qsub           | The extension of job submission script |
| NCPU\_PER\_NODE           | 24              | Number of processors per node |
| MEM\_PER\_NODE            | 50              | Unit: GB. Requested memory per node |
| N\_THREAD                 | 1               | The default number of threading |
| NGPU\_PER\_NODE           | 0               | Number of GPUs per node |
| GPU\_TYPE                 | RTX6000         | The default type of GPU |
| BUDGET\_CODE              | -               | For ARCHER2. Budget code of a research project |
| QOS                       | -               | For ARCHER2. Quality of service |
| PARTITION                 | -               | For ARCHER2. Partition of jobs |
| TIME\_OUT                 | 3               | Unit: min. Time spared for post processing |
| JOB\_TMPDIR               | ${EPHEMERAL}    | The temporary directory for calculations |
| EXEDIR                    | \[depends\]     | Directory of executable / Available module load command |
| EXE\_PARALLEL             | \[depends\]     | The parallel executable |
| EXE\_OPTIONS              | \[depends\]     | Default command line options for the executable specified |
| PRE\_CALC                 | \[Table\]       | Saved names, temporary names, and definitions of mandatory input files |
| FILE\_EXT                 | \[Table\]       | Saved names, temporary names, and definitions of optional input files |
| POST\_CALC                | \[Table\]       | Saved names, temporary names, and definitions of output files |
| JOB\_SUBMISSION\_TEMPLATE | \[script\]      | Template for job submission scripts |

**NOTE**

1. Keyword 'JOB\_SUBMISSION\_TEMPLATE' should be the last keyword, but the sequences of other keywords are allowed to change.  
2. Empty lines between keywords and their values are forbidden.  
3. All listed keywords have been included in the scripts. Undefined keywords are left blank.  
4. Multiple-line input for keywords other than 'PRE\_CALC', 'FILE\_EXT', 'POST\_CALC' and 'JOB\_SUBMISSION\_TEMPLATE' is forbidden, otherwise the code will only read the top line.  
5. Requesting any GPU will lead the job to the queue for GPU node. For CPU only jobs, 'NGPU' should always be 0, in which case 'GPU\_TYPE' will never be visited.  
6. By default, 'JOB\_TMPDIR' is set as `${EPHEMERAL}`. The folder for the current job is named as '\[jobname\]\_\[pbsjobid\]'.  
7. Dashed lines and titles for 'PRE\_CALC', 'POST\_CALC', and 'JOB\_SUBMISSION\_TEMPLATE' are used as separators and are not allowed to be removed.  
8. The qsub template attached during initialization is only compatible with the default settings. For user-defined executables / commands, changes might be made accordingly in the 'JOB\_SUBMISSION\_TEMPLATE' block (see the LAMMPS test case).

**Explanations of mpi commands**

The definition of keywords 'EXEDIR', 'EXE\_PARALLEL' and 'EXE\_OPTIONS' seems confusing and verbose. It is indeed a compromise to ensure the generality. 'EXEDIR' was generated to deal with multiple executables in the same directory and share the same job submission scripts - which is already banned in this general job submitter, so 'EXEDIR' will probably disappear in the stable release. 

'EXE\_OPTIONS' is to deal with the command line options needed for the main input file. For example, LAMMPS requires a `-in` flag, GULP requires `<`, and CRYSTAL needs nothing. 

The mpi command that is actually used on PBS nodes is:

```console
~$ mpiexec ${EXEDIR}/${EXE_PARALLEL} ${EXE_OPTIONS} main.input
```

### 'PRE\_CALC', 'FILE\_EXT' and 'POST\_CALC' tables

These 3 keywords require 3 separate tables of mandatory input files, optional input files and output files. 'SAVED' specifies the desired name in `${HOME}` directory, while 'TEMPORARY' specifies the desired name in `${EPHEMERAL}` directory. 'DEFINITION' will not be scanned, which is used as a comment / reminder.

In practice, `run_exec` and `post_proc` scan all the formats listed and moves all the matching files forward and backward. Missing any file in 'PRE\_CALC' table immediately leads to the interruption of calculation, while missing files listed in 'FILE\_EXT' does not stop the job. The result of every scan is printed in '.o\[pbsjobid\]' file. 

The naming scheme of input files are recommended to follow certain rules. Meanwhile, to ensure the generality, some extra rules have to be set for codes extremely flexible to input formats when performing simulations (usually MD codes, especially LAMMPS, which might be a tradition different from the DFT community). To achieve this, a 'pseudo' regular expression is used. Keywords are listed below:

`[jobname]` - The variable of the main input file basename. No '.' is allowed for `[jobname]`, i.e., all the characters after the first full stop are recognized as extensions.  
`[pre_job]` - The variable of the reference file basename. No '.' is allowed. All the reference files should be placed in the same directory, even not in any sub-directory, and have the same basename, `[pre_job]`.  

**Keywords below are allowed in 'POST_CALC' only**

`/` - At the end of a string. It indicates that the string should be recognized as a folder, rather than a file.  
`*` - In the 'TEMPORARY' column, it has the same meaning as '\*' in bash shell - any string of any length. In the 'SAVED' column, it is only allowed to appear at the beginning of a string, which means saving the file in `${HOME}` as its temporary name.

### Normal termination vs Interruption

* If the job is terminated due to exceeding walltime, temporary files will be saved in the output directory. The temporary directory will be removed.

* If the job is terminated due to improper settings of calculation parameters, temporary files will be saved in the output directory. The temporary directory will be removed.

* If the job is killed before 'timeout' (usually by user), temporary will be saved in the temporary directory with temporary names. The temporary directory will not be removed. Refer to '.out' file or '.o\[pbsjobid\]' file for the path. 

### General outputs

**\[jobname\].out**  
Output file in home directory, used to record information and monitor the progress of parallel jobs.

**\[jobname\].o\[pbsjobid\]**  
A verbose version of .out file, for debugging. Besides the information of .out file, it includes the scripts , the list of files in the ephemeral directory, and the screen outputs of `run_exec` and `post_proc` scripts.

**\[jobname\].e\[pbsjobid\]**   
For debugging. Records the screen outputs when PBS system executes the .qsub file (usually error messages).

## How to generate a configuration file

4 scripts included in the main directory are for general proposes, which need configuration before being used. Configurations are automatically executed using `config_CODE.sh` scripts stored separately in sub-folders with code names. An example (GROMACS\_v0.1) is placed in the main directory for illustrating proposes.

To generate a configuration file for a new code, several modification should be made. Lines need modification are marked with comment lines `#--# BEGIN_USER`, `#--# END_USER` and instructions. Several considerations suggested:

1. Title line: Who is responsible for this file?  
2. Title line: The date and version of the file? A new `config_CODE.sh` file changes the version number after the decimal point, i.e. v0.1 --> v0.2, while a change in general-propose scripts changes the major version number and resets the minor version number i.e., v0.1 --> v1.0  
3. Script directory: The default directory  
4. Executable directory: The default directory or `module load` command  
5. Executable name: The default executable name and command-line options - does the code require any general in-line commands? Of course users can also define them in command lines, except the mandatory input.   
6. Default parameters for parallel jobs: Depends on your habit. Do you prefer 24 cores per node or 32 cores? Do you need GPUs?  
7. PRE\_CALC: What is the general format of mandatory inputs? (Maybe I'll directly use regular expressions for the next version...)  
8. FILE\_EXT: What is the general format of optional inputs?  
9. POST\_CALC: What is the general format of outputs?  
10. JOB\_SUBMISSION\_TEMPLATE: Any specific environmental setups for the code? e.g., Do you need a dynamically linked lib? Do you need export some environmental variables?  

## Program specific instructions

### [CRYSTAL](https://www.crystal.unito.it/index.php)

*Authors: Spica. Vir. & G. Mallia*

### [LAMMPS](https://www.lammps.org/)

*Author: Spica. Vir., Contributors: A. Arber & K. Tallat-Kelpsa*

**Mandatory input**  
\[jobname\].in

**Defaults**  
EXEDIR - module load  lammps/19Mar2020  
EXE\_PARALLEL - lmp\_mpi  
EXE\_OPTIONS - -in

**Commands**  
`Plmp` - Generate qsub files for LAMMPS MD jobs.  
`setlmp` - Check the `settings` file of runLAMMPS.

**Explanations of test cases**

The unite cell of Form II paracetamol crystal (CCDC: [HXACAN37](https://www.ccdc.cam.ac.uk/structures/Search?Ccdcid=HXACAN37&DatabaseToSearch=Published)) generated by [MOLTEMPLATE](http://moltemplate.org/) is used as the test case. In **Step 1**, an energy minimization followed by 5000 steps (5 ps) under the NVT ensemble (T=100 K) is performed. In **Step 2**, the job is restarted from the 4000th step and runs for another 5000 steps under the same conditions. Both jobs use the intel acceleration package and run on 4 threads (see extra notes below). Following commands are used:

``` console
~$ Plmp -in f2_nvt.in -wt 00:20 -nd 1 -- -sf intel -pk omp 4
~$ Plmp -in f2_nvt_restart.in -ref f2_nvt-wt 00:20 -nd 1 -- -sf intel -pk omp 4
```

**Extra notes**  
1. The self-compiled LAMMPS Sept. 2021 version is used, which is based on Intel OneAPI v2022.1.2, so in 'JOB_SUBMISSION_TEMPLATE' block, an extra line is inserted to load Intel MPI, OpenMP and FFTW3.  
2. The definition of LAMMPS inputs is too flexible that specific rules are set to regularize the naming schemes. A more specific version with more flexible input/output format requirements is available [here](https://github.com/cmsg-icl/crystal_shape_control/tree/main/LAMMPS_job_sub_ICHPC). 


### [GROMACS](https://www.gromacs.org/)

*Author: Spica. Vir., Contributor: K. Tallat-Kelpsa*

**Mandatory input**  
\[jobname\].tpr

**Defaults**  
EXEDIR - module load  gromacs/2021.3-mpi  
EXE\_PARALLEL - gmx\_mpi  
EXE\_OPTIONS - mdrun -s

**Commands**  
`Pgmx` - Generate qsub files for GROMACS MD jobs.  
`setgmx` - Check the `settings` file of runGROMACS.

**Explanations of test cases**

The energy minimization steps in [Tutorial 1: Lysozyme in Water](http://www.mdtutorials.com/gmx/lysozyme/index.html) and [Tutorial 3: Umbrella Sampling](http://www.mdtutorials.com/gmx/umbrella/index.html) are used as testing cases. The interactive generation of '.tpr' file is obtained in serial on login nodes. Only 'mdrun' is allowed to run in parallel. To illustrate that the job submitter can combine different mpi jobs into the same qsub file, the following commands are used:

``` console
~$ Pgmx -in em-1AKI.tpr -in em-2BEG.tpr -wt 00:20 -nd 1
~$ qsub em-1AKI-em-2BEG.qsub
```

### [GULP](http://gulp.curtin.edu.au/gulp/)

*Author: Spica. Vir.*
