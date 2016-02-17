<?php

#
# Private functions
#

function __db_set_val($type, $n, $v)
{
        $query = "REPLACE INTO $type (n, v) VALUES('$n', '$v')";

        return mysql_query($query);
}

function __db_get_val($type, $n)
{
        $query = "SELECT v FROM $type WHERE n = '$n'";

        $dbres = mysql_query($query);
        if (!$dbres)
                return false;

        $row = mysql_fetch_array($dbres);
        if (!$row)
                return false;
        return $row['v'];
}

function __db_get_all_val($type)
{
        $query = "SELECT n,v FROM $type";

        $dbres = mysql_query($query);
        if (!$dbres) {
                dbg("cannot get all $type's variables");
                return false;
        }

        $data = array();
        while ($row = mysql_fetch_array($dbres))
                $data[$row["n"]] = $row["v"];
        return $data;
}

#
# Public functions
#

function db_set_status($n, $v)
{
	return __db_set_val("status", $n, $v);
}

function db_get_status($n)
{
	return __db_get_val("status", $n);
}

function db_set_config($n, $v)
{
	return __db_set_val("config", $n, $v);
}

function db_get_config($n)
{
	return __db_get_val("config", $n);
}

function db_log_var($l, $v)
{
	$query = "REPLACE INTO $l (t, v) VALUES(now(), '$v');";
        return mysql_query($query);
}

function db_get_status_all()
{
        return __db_get_all_val("status");
}

function db_select($db)
{
	$ret = mysql_select_db($db);
	if (!$ret)
		die("unable to select database");
}

function db_connect()
{
	$ret = mysql_connect("127.0.0.1", "user", "userpass");
	if (!$ret)
		die("unable to connect with MySQL daemon");
}

function db_open($db)
{
        db_connect();
        db_select($db);
}

?>
