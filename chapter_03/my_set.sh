#!/bin/sh

NAME=$(basename $0)

PASSWD="userpass"

usage() {
        echo "usage: $NAME <table> <name> <value>" >&2
        exit 1
}

[ $# -lt 3 ] && usage
table=$1
name=$2
value=$3

# Ok, do the job!
mysql -u user --password=$PASSWD -D aquarium_mon <<__EOF__

REPLACE INTO $table (n, v) VALUES('$name', '$value');

__EOF__

exit 0
