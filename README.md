# MuLaNA -- Muzzio Lab Neuroscience Analysis

This is a set of neuroscience analysis codes written mostly in MATLAB.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

* MClust 4.4 -- The only functionality we need is "readheader". This requirement will be eliminated.

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
- object_task_consecutive_trial
- one_context_tetrode
- two_contexts_tetrode

### Create a new instance of a pre-made project
Navigate to a desired folder where you would like to create an instance of the project. Then type
```
mulana_project_create( 'projectName' )
```
where **projectName** is one of the available projects.

### Installing

A step by step series of examples that tell you how to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Marc Normandin** - *Developer, Muzzio Lab* - [Marc Normandin](https://github.com/marcnormandin)
* **Celia Gagliardi** - *Developer, Muzzio Lab* - [Celia Gagliardi](https://github.com/celiagagliardi)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is PRIVATE to Muzzio Lab members. All Rights Reserved 2020.

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
