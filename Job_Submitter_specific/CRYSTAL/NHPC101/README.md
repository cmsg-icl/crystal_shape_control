# Crystal job submitter - Local version

[Crystal](https://www.crystal.unito.it/index.php) job submitter for local servers without job scheduler, i.e., no discrimination between login nodes and computation nodes. Support environment modules package and serial/parallel versions of CRYSTAL.  

## Install

1. Enter the folder and execute the script `setup.sh`.  
2. Following the instructions, specify the directory of job submitter and the directory of executables / modulefiles. 
4. Type `source ~/.bashrc` to implement user-defined commands. 

**Note**

1. All the scripts should be placed in the same directory.  
2. By default, job submitter scripts will be stored in `${HOME}/etc/runCRYSTAL/`.  

## Usage & command list

### Output and job executing information

Printed out information can be found in '.out' file (calculation related) and, by default, on the screen (file transfer related). To redirect the output on screen or to run with no-hang-up, `nohup`, refer to the next section, 'Commands'.

If a '.out' file with the same name as the job to be submitted exists in the same directory, that job won't be executed before output is either transferred to another folder or removed. 

### Temporary directory

* Temporary directory is saved in the same directory as input / output files, named as `tmp_[jobname]_[jobid]/`.  
* If the job is terminated due to improper settings of calculation parameters, temporary files will be saved in the output directory. The temporary directory will be removed.  
* If the job is killed by the user, temporary files will be saved in the temporary directory with temporary names. The temporary directory will not be removed.  

### Commands

Here are the user defined commands: 

1. `crys` - executing serial crystal calculations

``` bash
~$ crys -in jobname [-ref refname]

```

`jobname` - str, name of the input .d12 file, base name recommended.  
`refname` - str, optional, name of the previous job, base name recommended.  

The sequence of input parameters does not matter. 

To re-direct the screen print-outs to, for example, 'jobname.log', use the command below: 

``` bash
~$ crys -in jobname [-ref refname] > jobname.log 2>&1

```

Issue with `nohup`  
: `nohup` cannot find alias commands. Full path to the job submission script should be specified. For the default settings, using the following command: 

``` bash
~$ nohup ${HOME}/etc/runCRYSTAL/crystal -in jobname [-ref refname] > jobname.log 2>&1 &

```


2. `Pcrys` - executing parallel crystal calculations (Pcrystal and MPP)

``` bash
~$ Pcry -in jobname -np NP [-ref refname] > jobname.log 2>&1
```

`jobname` - str, name of the input .d12 file, base name recommended.  
`NP`      - int, number of processors used for calculation, by default 1.  
`refname` - str, optional, name of the previous job, base name recommended.  


3. `prop` - executing serial properties calculations

``` bash
~$ prop -in jobname -ref refname
``` 

`jobname` - str, name of the input .d12 file, base name recommended.  
`refname` - str, name of the previous SCF job, base name recommended.  

4. `Pprop` - executing parallel properties calculations

``` bash
~$ Pprop -in jobname -np NP -ref refname
```

`jobname` - str, name of the input .d12 file, base name recommended.  
`NP`      - int, number of processors used for calculation, by default 1.  
`refname` - str, name of the previous SCF job, base name recommended.  

5. `setcrys` - print the file `settings`. No input required.

## Script list

`setup.sh` - set up the settings file and create job submission commands.  
`settings` - store all parameters needed for CRYSTAL/PROPERTIES jobs. see the 'Keyword list' below.  
`settings_template` - empty `settings` file, will be used to cover `settings` file when installing/re-installing the job submitter.  
`runcrys` - execute 'CRYSTAL' type calculations in serial or parallel, and perform post processing after finishing the calculation.  
`runprop` - execute 'PROPERTIES' type calculations in serial or parallel, and perform post processing after finishing the calculation.  

**NOTE**

1. The name of file `settings` `settings_template` shouldn't be changed.
2. `settings` `settings_template` are generally applicable, comment the corresponding `sed` and `grep` sentences in `setup.sh`. 
2. Names of `runcrys` `runprop` can be changed, but should corresponds to the values in `settings`.  

## Keyword list
Keywords used for the script `settings` are listed in the table below. Any change in parameters should be made in that script.

| KEYWORD                 | DEFAULT VALUE   | DEFINITION |
|:------------------------|:---------------:|:-----------|
| CRYSTAL_SCRIPT          | runcrys         | Script for crystal type calculations |
| PROPERTIES_SCRIPT       | runpropn        | Script for properties type calculations |
| EXEDIR                  | -               | Directory of executables or module files |
| EXE_PCRYSTAL            | Pcrystal        | Executable for parallel crystal type calculation |
| EXE_MPP                 | MPPcrystal      | Executable for massively parallel crystal type calculation |
| EXE_PPROPERTIES         | Pproperties     | Executable for parallel properties type calculation |
| EXE_CRYSTAL             | crystal         | Executable for serial crystal type calculation |
| EXE_PROPERTIES          | properties      | Executable for serial properties type calculation |
| PRE_CALC                | \[Table\]       | Saved names, temporary names, and definitions of input files |
| POST_CRYS               | \[Table\]       | Saved names, temporary names, and definitions of output files for crystal type calculation |
| POST_PROP               | \[Table\]       | Saved names, temporary names, and definitions of output files for properties type calculation |

**NOTE**

1. Empty lines between keywords and their values are forbidden.  
2. All listed keywords have been included in the scripts. Undefined keywords are left blank.  
3. Multiple-line input for keywords other than `PRE_CALC`, `POST_CRYS`, `POST_PROP`, and `JOB_SUBMISSION_TEMPLATE` is forbidden.  
4. Dashed lines for `PRE_CALC`, `POST_CRYS`, `POST_PROP`, and `JOB_SUBMISSION_TEMPLATE` are used to define input blocks and are not allowed to be modified. Minimum length: '------------------'

## Other comments
1. File basenames are not recommended to include '.'. If so, the '.d12/.d3' extensions should be included when using the `-in` flag - otherwise the 'file not found error' might be reported because the code obtains the basename by truncating the characters after the last '.'.  
2. A new value for the same flag covers the previous one. For example, `Pcrys -type prop` is equivalent to `Pprop`. Due to the same reason, the current implementation does not support the 'multiple `-in` / multiple `-ref`' definitions similar to the CX1 general submitter. This feature might be added in future releases.
