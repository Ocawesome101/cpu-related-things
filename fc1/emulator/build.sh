#!/bin/bash

set -e

cd emusrc
gcc *.c -I../include -ldl -o emulator

cd ../portsrc

for f in $(ls); do
  gcc "$f" -I../include -shared -fPIC -o ${f%.c}.o
done

cd ..
