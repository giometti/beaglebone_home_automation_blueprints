debug="false"
logstderr=""

function dbg () {
        $debug && logger -p user.debug -t $NAME $logstderr "$1"
}

function info () {
        logger -p user.info -t $NAME $logstderr "$1"
}

function err () {
        logger -p user.err -t $NAME $logstderr "$1"
}
