#!/bin/bash
#jobs=($(ls shamu_*.ps))
for job in ml_min_shamu_7_*.ps; do
	sbatch $job
done

