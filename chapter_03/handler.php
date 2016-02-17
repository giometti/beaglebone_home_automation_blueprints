<?php

require("db.php");

# Open the DB
db_open("aquarium_mon");

if (count($_GET) > 0) {
	# Input section
       	db_set_status("force_cooler", $_GET["force_cooler"]);
       	db_set_status("force_pump", $_GET["force_pump"]);
       	db_set_status("force_lamp", $_GET["force_lamp"]);

	if ($_GET["force_feeder"])
		db_set_status("force_feeder", 1);
}

# Output section
$values["alarm_sys"] = db_get_status("alarm_sys");
$values["alarm_level"] = db_get_status("alarm_level");
$values["alarm_temp"] = db_get_status("alarm_temp");

$values["water"] = db_get_status("water");
$values["cooler"] = db_get_status("cooler");
$values["pump"] = db_get_status("pump");
$values["lamp"] = db_get_status("lamp");
$values["feeder"] = db_get_status("force_feeder");

$values["force_feeder"] = 0;

echo json_encode($values);
?>
