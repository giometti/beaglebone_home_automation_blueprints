#!/usr/bin/php
<?php

require_once "setup.php";
require_once "config.php";

include('../lib/logging.php');

#
# Usage
#

function usage()
{
        fprintf(STDERR, "usage: %s [-h] [-d] \n", NAME);
        fprintf(STDERR, "    -h         - show this message\n");
        fprintf(STDERR, "    -d         - enable debugging messages\n");

        die();
}

#
# Main
#

# Check the command line
$shortopts  = "hd";
$options = getopt($shortopts);
foreach ($options as $o => $a) {
        switch ($o) {
        case "h":
                usage();

        case "d":
                $debug = true;
                break;
        }
}

# Define the Facebook session
$fb = new Facebook\Facebook([
	'app_id'		=> APP_ID,
	'app_secret'		=> APP_SECRET,
	'default_graph_version'	=> 'v2.4',
	'default_access_token'	=> DEF_TOKEN,
	'fileUpload'            => true,
	'cookie'		=> true,
]);

# Print user's information
try {
	$res = $fb->get('/me');
} catch(Exception $e) {
        err("error!\n");
	dbg("===============================================================================\n");
	dbg($e);
	dbg("===============================================================================\n");
        die();
}
$node = $res->getGraphObject();
info("name is \"%s\" (%s)\n",
	$node->getProperty('name'), $node->getProperty('id'));

# Print user's permissions
$res = $fb->get("/me/permissions");
$node = $res->getDecodedBody();
info("permissions are:\n");
foreach ($node['data'] as $perm)
	info("\t%s is %s\n", $perm['permission'], $perm['status']);

?>
