#!/bin/bash

sudo apt-get update && sudo apt-get -y upgrade 

sudo apt-get install -y python3-pip cmake r-base linux-tools-common linux-tools-6.8.0-64-generic libcurl4-openssl-dev libssl-dev libfontconfig1-dev libxml2-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

sudo sysctl -w kernel.perf_event_paranoid=-1

cd $HOME && git clone --recursive https://github.com/jessdagostini/miniGiraffe.git