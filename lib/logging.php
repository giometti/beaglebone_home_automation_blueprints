<?php

define("NAME", basename($argv[0]));

$debug = false;

if (defined('USE_SYSLOG')) {
	define('__log_debug', LOG_DEBUG);
	define('__log_info', LOG_INFO);
	define('__log_err', LOG_ERR);

	function __message($file, $line, $par1, $string)
	{
		syslog($par1, $string);
	}
} else { /* !USE_SYSLOG */
	define('__log_debug', STDERR);
	define('__log_info', STDERR);
	define('__log_err', STDERR);

	function __message($file, $line, $par1, $string)
	{
		fprintf($par1, sprintf("%s[%4d]: %s",
				basename($file), $line, $string));
	}

} /* USE_SYSLOG */

function dbg()
{
        global $debug;
        if (!isset($debug) || !$debug)
                return;

        $argv = func_get_args();
        $format = array_shift($argv);

	$bt = debug_backtrace();
	$caller = array_shift($bt);

	__message($caller['file'], $caller['line'],
			__log_debug, vsprintf($format, $argv));
}

function info()
{
        $argv = func_get_args();
        $format = array_shift($argv);

	$bt = debug_backtrace();
	$caller = array_shift($bt);

	__message($caller['file'], $caller['line'],
			__log_info, vsprintf($format, $argv));
}

function err()
{
        $argv = func_get_args();
        $format = array_shift($argv);

	$bt = debug_backtrace();
	$caller = array_shift($bt);

	__message($caller['file'], $caller['line'],
        		__log_err, vsprintf($format, $argv));
}

?>
