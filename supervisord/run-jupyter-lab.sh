#!/bin/bash
sudo --preserve-env -H -u omnious bash -c 'jupyter lab --no-browser --ip=0.0.0.0 --port=8801 --notebook-dir=/home/omnious --LabApp.token="omnious" --NotebookApp.iopub_data_rate_limit=100000000' 
