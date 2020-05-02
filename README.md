# MuLaNA -- Muzzio Lab Neuroscience Analysis

This is a set of neuroscience analysis codes written mostly in MATLAB.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

* Neuralynx MATLAB Netcom Utilities -- Download from https://neuralynx.com/software/category/matlab-netcom-utilities

```
Add the external libraries to the MATLAB search path
```

### List pre-made projects
There are some pre-made projects for analyses performed by the ML. List them using the following command
```
mulana_project_list()
```
Some of the available projects are:
- general_tetrode
- object_task_consecutive_trials
- two_contexts_tetrode

### Create a new instance of a pre-made project
Navigate to a desired folder where you would like to create an instance of the project. Then type
```
mulana_project_create( 'projectName' )
```
where **projectName** is one of the available projects. The initialization script will then ask you for some information such as the location of your data directory (input) and the location of your analysis directory (output).


### Requirements of the user
Each experiment requires a file named 'experiment_description.json'. This file contains information about the experiment that is not part of the tetrode dataset. Below are examples.

## Example of a rectangular arena, two alternating contexts, used for chengs_task_2c. The tfiles are specified as '-1', which tells the system to load them as the appropriate bits.
```
{
	"animal": "JJ9_CA1",
	"imaging_region": "CA1",
	"experiment": "chengs_task_two_context",
	"arena": {
		"shape": "rectangle",
		"x_length_cm": 20.0,
		"y_length_cm": 30.0
	},
	"num_contexts": 2,
	"session_folders": ["d1", "d2", "d3"],
	"mclust_tfile_bits": -1
}
```

## Example of a square arena, one context, used for the consecutive object task. The tfiles are specified as '64', which forces the system to load them as 64 bit valued timestamps (the other options are '32' or '-1').
```
{
	"animal": "MG1_CA1",
	"imaging_region": "hippocampus",
	"experiment": "object_task_consecutive_trials",
	"arena": {
		"shape": "square",
		"length_cm": 35.0
	},
	"num_contexts": 1,
	"session_folders": ["hab","test"],
	"mclust_tfile_bits": 64
}
```

## Authors

* **Marc Normandin** - *Developer, Muzzio Lab* - [Marc Normandin](https://github.com/marcnormandin)
* **Celia Gagliardi** - *Developer, Muzzio Lab* - [Celia Gagliardi](https://github.com/celiagagliardi)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is PRIVATE to Muzzio Lab members. All Rights Reserved 2020.

## Acknowledgments

* Hat tip to anyone whose code was used
* Thanks to StackOverflow
