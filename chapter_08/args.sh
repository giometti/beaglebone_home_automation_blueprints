#!/bin/bash

NAME=$(basename $0)
ID=$RANDOM

function log ( ) {
	echo "$(date "+%s.%N"): $NAME-$ID: $1"
}

log "executing with $# args"

n=1
for arg ; do
	log "$n) $arg"
	n=$((n + 1))
done

log "done"

exit 0
