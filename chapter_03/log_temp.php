<?php

require("db.php");

# Open the DB
db_open("aquarium_mon");

# Get the last 20 points
$query = "SELECT v FROM temp_log ORDER BY t DESC LIMIT 20";
$ret = mysql_query($query);
if (!$ret)
	die();

$data = array();
$n = 0;
while ($row = mysql_fetch_array($ret)) {
	array_unshift($data, $row["v"]);
	$n++;
}

if ($n < 20)
	echo json_encode(array_merge(array_fill(0, 20 - $n, 0), $data));
else
	echo json_encode($data);
?>
