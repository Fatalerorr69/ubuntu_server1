<?php
// index.php
?>
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="UTF-8">
<title>Enterprise Server Dashboard</title>
<link rel="stylesheet" href="assets/style.css">
<script src="assets/script.js"></script>
</head>
<body>
<h1>Enterprise Server Dashboard</h1>

<section>
<h2>Zabbix Server</h2>
<p>Status: <?php echo shell_exec("systemctl is-active zabbix-server"); ?></p>
<p>Last 10 alerts:</p>
<pre><?php echo shell_exec("tail -n 10 /var/log/zabbix/zabbix_server.log"); ?></pre>
</section>

<section>
<h2>VirtualBox VM</h2>
<p><a href="vm.php">Správa VM</a></p>
</section>

<section>
<h2>NAS Health</h2>
<p><a href="nas.php">Disky a RAID</a></p>
</section>

<section>
<h2>Logy</h2>
<p><a href="logs.php">Zobrazit logy</a></p>
</section>

</body>
</html>
