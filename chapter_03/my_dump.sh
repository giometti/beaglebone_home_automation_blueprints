#!/bin/sh

NAME=$(basename $0)

PASSWD="userpass"

usage() {
        echo "usage: $NAME <table>" >&2
        exit 1
}

[ $# -lt 1 ] && usage
table=$1

# Ok, do the job!
mysql -u user --password=$PASSWD -D aquarium_mon <<__EOF__

# Do the whole dump
SELECT * FROM $table;

__EOF__

exit 0
