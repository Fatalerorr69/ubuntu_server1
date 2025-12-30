<?php
// nas.php
$disks = shell_exec("lsblk -o NAME,SIZE,TYPE,MOUNTPOINT");
$smart = shell_exec("for d in /dev/sd?; do echo $d; smartctl -H $d; done");
?>
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="UTF-8">
<title>NAS Health</title>
<link rel="stylesheet" href="assets/style.css">
</head>
<body>
<h1>NAS Health</h1>

<h2>Disky</h2>
<pre><?php echo $disks; ?></pre>

<h2>SMART status</h2>
<pre><?php echo $smart; ?></pre>

<p><a href="index.php">Zpět na dashboard</a></p>
</body>
</html>
