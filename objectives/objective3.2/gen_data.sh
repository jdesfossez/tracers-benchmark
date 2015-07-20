#!/bin/bash

cd ../objective3.1
make
./clock_gettime -s 10000000
cp sample ../objective3.2/
cp statistics ../objective3.2
make clean
