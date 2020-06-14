#!/bin/sh -x

HOST=$(hostname)

ansible $HOST -m debug -a var=key_passphrase
