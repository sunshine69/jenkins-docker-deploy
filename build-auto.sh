#!/bin/sh

cd ansible
p=$(./display-info.sh | grep key_passphrase | cut -f 4 -d'"')
cd -
./build.sh $p

