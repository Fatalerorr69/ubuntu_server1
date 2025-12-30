<?php
// vm.php
function getVMs() {
    return shell_exec("vboxmanage list vms");
}

function getRunningVMs() {
    return shell_exec("vboxmanage list runningvms");
}

// AJAX akce
if(isset($_GET['action']) && isset($_GET['vm'])) {
    $vm = escapeshellarg($_GET['vm']);
    switch($_GET['action']) {
        case 'start':
            echo shell_exec("vboxmanage startvm $vm --type headless");
            exit;
        case 'stop':
            echo shell_exec("vboxmanage controlvm $vm acpipowerbutton");
            exit;
        case 'restart':
            echo shell_exec("vboxmanage controlvm $vm reset");
            exit;
    }
}

$vms = getVMs();
$running = getRunningVMs();
?>
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="UTF-8">
<title>Správa VM</title>
<link rel="stylesheet" href="assets/style.css">
<script src="assets/script.js"></script>
</head>
<body>
<h1>Správa VirtualBox VM</h1>

<h2>Všechny VM</h2>
<pre><?php echo $vms; ?></pre>

<h2>Běžící VM</h2>
<pre><?php echo $running; ?></pre>

<h2>Ovládání VM</h2>
<form id="vmForm">
VM jméno: <input type="text" name="vm" required>
<select name="action">
    <option value="start">Start</option>
    <option value="stop">Stop</option>
    <option value="restart">Restart</option>
</select>
<button type="button" onclick="controlVM()">Spustit akci</button>
</form>

<script>
function controlVM(){
    var form = document.getElementById('vmForm');
    var vm = form.vm.value;
    var action = form.action.value;
    fetch('vm.php?action='+action+'&vm='+encodeURIComponent(vm))
        .then(response => response.text())
        .then(data => alert('Výsledek: '+data))
        .catch(err => alert('Chyba: '+err));
}
</script>

<p><a href="index.php">Zpět na dashboard</a></p>
</body>
</html>
