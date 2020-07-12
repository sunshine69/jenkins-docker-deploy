#!/bin/sh -x

HOST=$(hostname -s)

ansible $HOST -m debug -a var=key_passphrase
