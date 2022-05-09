#!/bin/bash

set -e

rm -rf devices && mkdir devices

basedir=$PWD

cd src
gcc *.c -I$basedir/include -ldl -o $basedir/fc1 -Wno-incompatible-pointer-types -rdynamic

cd devices

for f in $(ls); do
  gcc "$f" -I$basedir/include -shared -fPIC -o $basedir/devices/${f%.c}.so
done

cd ../..
