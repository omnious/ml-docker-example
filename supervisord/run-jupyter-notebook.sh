#!/bin/bash
sudo --preserve-env -H -u omnious bash -c 'jupyter notebook --no-browser --NotebookApp.iopub_data_rate_limit=10000000000 --ip=0.0.0.0 --port=8800 --notebook-dir=/home/omnious --NotebookApp.token="omnious"'
