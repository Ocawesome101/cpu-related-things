#!/bin/bash

set -e

rm -rf ports && mkdir ports

basedir=$PWD

cd src
gcc *.c -I$basedir/include -ldl -o $basedir/fc1

cd ports

for f in $(ls); do
  gcc "$f" -I$basedir/include -shared -fPIC -o $basedir/ports/${f%.c}.o
done

cd ../..
