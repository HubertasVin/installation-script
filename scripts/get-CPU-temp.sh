#!/bin/bash

sensors 2> /dev/null | grep "CPU:" | tr -d '+' | awk '{print $2}' | tr -d '.0'
