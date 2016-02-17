<?php

function file_get_data($file)
{
	$ret = file_get_contents($file);
	if ($ret === false)
		return $ret;

	return rtrim($ret);
}

function gpio_set($file, $val)
{
        $val = $val === "on" || $val === true || $val != 0 ? 1 : 0;
	
	return @file_put_contents($file . "/value", $val . "\n");
}

function gpio_get($file)
{
	$ret = @file_get_contents($file . "/value");
	if (!$ret)
		return false;

	return rtrim($ret) != 0 ? 1 : 0;
}

function temp_get()
{
        global $temp_dir;

        $val = @file_get_contents("$temp_dir/w1_slave");
        if (!$val)
                return false;
        $val = str_replace("\n", " ", $val);
        $val = explode(" ", $val);

        if ($val[11] != "YES")
                return false;

        return trim($val[21], "t=") / 1000;
}

?>
