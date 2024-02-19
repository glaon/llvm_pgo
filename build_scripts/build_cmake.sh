#!/usr/bin/env bash

git clone --branch v3.29.0-rc1 --depth=1 https://github.com/Kitware/CMake.git cmake

cd cmake 

./bootstrap 
make