#!/bin/bash

find /sys/devices -type f -name gt_cur* -print0 | xargs -0 cat
