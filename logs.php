<?php
$logfiles = [
    '/var/log/zabbix/zabbix_server.log',
    '/var/log/nas-health.log',
    '/var/log/vbox-monitor.log'
];
?>
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="UTF-8">
<title>Logy</title>
<link rel="stylesheet" href="assets/style.css">
</head>
<body>
<h1>Logy služeb</h1>

<?php
foreach($logfiles as $log){
    echo "<h2>$log</h2><pre>";
    if(file_exists($log)){
        echo htmlspecialchars(shell_exec("tail -n 50 ".escapeshellarg($log)));
    } else {
        echo "Soubor neexistuje.";
    }
    echo "</pre>";
}
?>

<p><a href="index.php">Zpět na dashboard</a></p>
</body>
</html>
