<?php

require_once "setup.php";
require_once "config.php";

define('STATUS_FILE', "plant.status");
define('LOCK_FILE', "plant.lock");

#
# Facebook stuff
#

function do_post()
{
	# Define the Facebook session
	$fb = new Facebook\Facebook([
	        'app_id'                => APP_ID,
	        'app_secret'            => APP_SECRET,
	        'default_graph_version' => 'v2.4',
	        'default_access_token'  => DEF_TOKEN,
	        'fileUpload'            => true,
	        'cookie'                => true,
	]);

	# Publish to user’s timeline
       	$ret = $fb->post('/me/photos', array(
               	'message'       => 'My lovely plant!',
               	'source'        => $fb->videoToUpload(realpath('webcam-shot.jpg')),
       	));
}

#
# File locking functions
#

function file_lock($name)
{
        $f = fopen($name, 'w');
        if ($f === false)
                return false;

	$ret = flock($f, LOCK_EX);
        if ($ret === false)
                return false;

	return $f;
}

function file_unlock($f)
{
        flock($f, LOCK_UN);
        fclose($f);
}

#
# Ok, do the job
#

# Check the POST requests
if (isset($_POST["val"]))
        $new_cff_mois = floatval($_POST["val"]);
else if (isset($_POST["do"]))
	do_post();

# Wait for lock on /tmp/plant.lock
$lock = file_lock(LOCK_FILE);
if (!$lock)
	die();

# Read the status file and decode it
$ret = file_get_contents(STATUS_FILE);
if ($ret === false)
	die();
$data = json_decode($ret, true);

# Use the stored value reset to a specific defualt 
if (isset($new_cff_mois))
	$data['cff_mois'] = $new_cff_mois;

# Write back the new status (if needed)
$status = json_encode($data);
if (isset($new_cff_mois)) {
	$ret = file_put_contents(STATUS_FILE, $status);
	if ($ret === false)
        	die();
}

# Release the lock
file_unlock($lock);

# Encode data for JSON
echo $status;

?>
