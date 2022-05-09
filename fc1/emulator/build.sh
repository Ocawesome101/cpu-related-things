#!/bin/bash

set -e

rm -rf devices && mkdir devices

basedir=$PWD

cd src
gcc *.c -I$basedir/include -ldl -o $basedir/fc1 -rdynamic -Wno-incompatible-pointer-types

cd devices

for f in $(ls); do
  gcc "$f" -I$basedir/include -shared -fPIC -o $basedir/devices/${f%.c}.o
done

cd ../..
