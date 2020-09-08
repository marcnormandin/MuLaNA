#!/usr/bin/python3

import numpy as np
import json
import os
import sys, getopt

# January 31, 2020
# February 27, 2020: Modified script to take command line arguments to make easier for others
# May 29, 2020: Added ouput folder flag instead of saving in the directory where this script was called
# Aug 24, 2020: Added the script name as part of the log so that the log can be found easier.

# Find the trial folders associated with a given session number (of an experiment)
def get_trial_folders_for_session(recordingsParentFolder, experiment, session_index):
	pf = os.listdir(recordingsParentFolder + '/' + experiment['session_folders'][session_index])
	tf = []
	for f in pf:
		s = f.split('_')
		if len(s) != 3: # must have three parts
			continue

		if s[0][0] != 'H' or s[1][0] != 'M' or s[2][0] != 'S':
			continue

		if s[0][1:].isdigit() == False or s[1][1:].isdigit() == False or s[2][1:].isdigit() == False:
			continue

		t = int(s[0][1:])*60*60 + int(s[1][1:])*60 + int(s[2][1:])

		tf.append((f, t))
	return tf

def create_script_files(pipeline_cfg_filename, tasks_cfg_filename, recordingsParentFolder, analysisParentFolder, outputFolder):
	#recordingsParentFolder = os.getcwd();
	#analysisParentFolder = recordingsParentFolder.replace('recordings', 'analysis');

	#pipeline_cfg = 'pipeline_config.json'
	experiment_cfg = 'experiment_description.json'
	#tasks_cfg = 'shamu_tasks.json'
	
	#dirpath = os.getcwd()
	#pipeline_cfg_filename = dirpath + '/' + pipeline_cfg
	experiment_cfg_filename = recordingsParentFolder + '/' + experiment_cfg
	#tasks_cfg_filename = dirpath + '/' + tasks_cfg

	    
	with open( experiment_cfg_filename, 'r') as f:
		experiment = json.load(f)

	for session_index, session_name in enumerate(experiment['session_folders']):
		tf = get_trial_folders_for_session(recordingsParentFolder, experiment, session_index)
		numTrials = len(tf)

		session_num = session_index + 1


		for trial_index in range(numTrials):
			trial_num = trial_index + 1
			localFnPrefix = 'ml_min_shamu_' + str(session_num) + '_' + str(trial_num)
			tfn = outputFolder + '/' + localFnPrefix + '.ps'

			with open(tfn, 'w') as out_file:

				out_file.write("#!/bin/bash\n");
				out_file.write("#\n")
				out_file.write("#SBATCH --job-name=" + experiment['animal'] + "_" + str(session_num) + "_" + str(trial_num) + "\n")
				
				#out_file.write("#$ -q all.q\n")
				#out_file.write("#$ -cwd\n")
				#out_file.write("#$ -j y\n")
				out_file.write("#SBATCH --output=" + localFnPrefix + ".log\n")
				out_file.write("#SBATCH --partition=defq\n")
				out_file.write("#SBATCH --time=8:00:00\n")
				out_file.write("#SBATCH --nodes=1\n")
				out_file.write("#SBATCH --ntasks=1\n")
				out_file.write("#SBATCH --cpus-per-task=12\n")
				#out_file.write("#SBATCH --mail-type=ALL\n")
				#out_file.write("#SBATCH --mail-user=marc.normandin@utsa.edu\n")
				
				#  $JOB_ID.log\n")
				#out_file.write("#$ -pe threaded 12\n")
				out_file.write(". /etc/profile.d/modules.sh\n")
				out_file.write("module load shared matlab/R2019a\n")
				out_file.write("srun matlab -nodisplay -nodesktop -r \"run('/home-new/fym313/MATLAB/startup_uclaminiscope_batch.m'); ml_cai_pipeline_execute_trial_tasks('" + pipeline_cfg_filename + "', '" + recordingsParentFolder + "', '" + analysisParentFolder + "', '" + tasks_cfg_filename + "', " + str(session_num) + "," + str(trial_num) + ")\"\n")





def main(argv):
	pipeline_cfg_filename = ''
	tasks_cfg_filename = ''
#	experiment_cfg_filename = ''
	recordingsParentFolder = ''
	analysisParentFolder = ''
	outputFolder = ''

	usage = 'cmd -p <pipeline config> -t <task config> -r <recordings parent folder> -a <analysis parent folder> -o <script output folder>'

	try:
		opts, args = getopt.getopt(argv,"hp:t:r:a:o:",["pfile=","tfile=","rdir=","adir=","odir="])
	except getopt.GetoptError:
		print(usage)
		sys.exit(2)
	
	for opt, arg in opts:
		if opt == '-h':
			print(usage)
			sys.exit()
		elif opt in ("-p", "--pfile"):
			pipeline_cfg_filename = arg
		elif opt in ("-t", "--tfile"):
			tasks_cfg_filename = arg
		elif opt in ("-r", "--rdir"):
			recordingsParentFolder = arg
		elif opt in ("-a", "--adir"):
			analysisParentFolder = arg
		elif opt in ("-o", "--odir"):
			outputFolder = arg

	if pipeline_cfg_filename != '' and tasks_cfg_filename != '' and recordingsParentFolder != '' and analysisParentFolder != '' and outputFolder != '':	
		print('Using the following:\n')
		print('Pipeline config: ', pipeline_cfg_filename)
		print('Tasks config: ', tasks_cfg_filename)
		print('Recordings parent folder: ', recordingsParentFolder)
		print('Analysis parent folder: ', analysisParentFolder)
		print('Output folder: ', outputFolder)

		create_script_files(pipeline_cfg_filename, tasks_cfg_filename, recordingsParentFolder, analysisParentFolder, outputFolder)
	else:
		print(usage)
	sys.exit(2)


if __name__ == "__main__":
	main(sys.argv[1:])


