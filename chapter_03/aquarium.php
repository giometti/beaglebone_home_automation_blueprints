<?php
require("db.php");

# Open the DB
db_open("aquarium_mon");

# Set initial statuses for input widgets
$force_cooler = db_get_status("force_cooler");
$force_pump = db_get_status("force_pump");
$force_lamp = db_get_status("force_lamp");
$force_feeder = db_get_status("force_feeder");
?>
<html>
  <head>
    <link href="aquarium.css" rel="stylesheet" type="text/css">

    <script type="text/javascript" src="Drinks.js"></script>

    <script>
      var man_in = Drinks.createManager();
      man_in.href = 'handler.php';
      man_in.input = new Array("force_cooler", "force_pump", "force_lamp", "force_feeder");
      man_in.refresh = 1;
      man_in.start();

      var man_out = Drinks.createManager();
      man_out.href = 'handler.php';
      man_out.refresh = 1;
      man_out.start();
    </script>
  </head>

  <body>
    <h1>Aquarium</h1>

    <h2>Control panel</h2>
    
    <table>
      <tr>
        <th><h3>Live video</h3></th>
        <th><h3>Alarms</h3></th>
      </tr>
      <tr>
        <td>
          <img src="http://<?=$_SERVER["SERVER_ADDR"]?>:8080/?action=stream" alt="real-time video feed" />
        </td>
        <td>
          <table class="widget">
            <tr>
              <th>system</th>
              <th>Water level</th>
              <th>Water temperature</th>
            </tr>
            <tr>
              <td><led id="alarm_sys" type="round" radius="25" color="red"></led></td>
              <td><led id="alarm_level" type="round" radius="25" color="red"></led></td>
              <td><led id="alarm_temp" type="round" radius="25" color="red"></led></td>
            </tr>
          </table>
        </td>
      </tr>
    </table>

    <hr />

    <h3>Controls</h3>
    
    <form method="post">
      <table class="widget">
        <tr>
          <th>Water temp (C)</th>
          <th>Lamp</th>
          <th>Cooler</th>
          <th>Pump</th>
          <th>Feeder</th>
        </tr>
        <tr>
          <td>
            <display id="water" type="thermo" max_range="50" range_from="10" range_to="50" autoscale="true"></display>
          </td>
          <td>
            <led id="lamp" type="round" radius="25"></led>
            <switch id="force_lamp" type="circle" value="<?=$force_lamp?>"></switch>
          </td>
          <td>
            <led id="cooler" type="round" radius="25"></led>
            <switch id="force_cooler" type="circle" value="<?=$force_cooler?>"></switch>
          </td>
          <td>
            <led id="pump" type="round" radius="25"></led>
            <switch id="force_pump" type="circle" value="<?=$force_pump?>"></switch>
          </td>
          <td>
            <led id="feeder" type="round" radius="25"></led>
            <switch id="force_feeder" type="toggle" width="80" value="<?=$force_feeder?>"></switch>
          </td>
        </tr>
      </table>
      <input type="hidden">
    </form>

    <hr />

    <h3>Temperature log</h3>

    <display id="temp_graph" type="graph" scale="range" autoscale="true" mode="ch1" power_onload="true">
      <channel href="log_temp.php" refresh="60" sweep="0.005" frequency="20"></channel>
    </display>

  </body>
</html>
