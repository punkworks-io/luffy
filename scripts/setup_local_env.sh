#!/bin/bash

set -eu

PATH_REPO=${PWD}

PATH_WORKSTATION="${PATH_REPO}/workstation.env"
PATH_WORKSTATION_EXAMPLE="${PATH_REPO}/workstation.env.example"

PATH_SHOPARAZZI_LOCAL_VALUES="${PATH_REPO}/values/shoparazzi/values.local.yaml"
PATH_SHOPARAZZI_LOCAL_VALUES_EXAMPLE="${PATH_REPO}/values/shoparazzi/values.local.yaml.example"

echo "Setting up workstation "
if [ -f "${PATH_WORKSTATION}" ]; then
    echo "Workstation configuration exists. NOT overriding it"
else
    echo "Workstation configuration doesn't exist. copying from ${PATH_WORKSTATION_EXAMPLE}"
    cp  $PATH_WORKSTATION_EXAMPLE $PATH_WORKSTATION
    echo "${PATH_WORKSTATION} copied. Change your env variables"
fi
echo "** Workstation setup complete **"


if [ -f "${PATH_SHOPARAZZI_LOCAL_VALUES}" ]; then
    echo "Local Values file exists. NOT overriding it"
else
    echo "Local values file doesn't exist. copying from ${PATH_SHOPARAZZI_LOCAL_VALUES_EXAMPLE}"
    cp  $PATH_SHOPARAZZI_LOCAL_VALUES_EXAMPLE $PATH_SHOPARAZZI_LOCAL_VALUES
    echo "${PATH_SHOPARAZZI_LOCAL_VALUES} copied. modify your values."
fi
echo "** Workstation setup complete **"