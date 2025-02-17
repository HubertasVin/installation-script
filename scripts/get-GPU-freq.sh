#!/bin/bash

nvidia-smi --query-gpu=name,utilization.gpu --format=csv | tail -n1 | cut -d',' -f2 | tr -d ' %'
