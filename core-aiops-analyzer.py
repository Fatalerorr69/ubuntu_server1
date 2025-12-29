import json

with open("/srv/aiops/state.json") as f:
    data = json.load(f)

issues = []

if "100%" in data["disk"]:
    issues.append("KRITICKÉ: Disk je plný")

if int(data["services_failed"]) > 0:
    issues.append("Služby selhaly – zkontroluj systemctl")

if not issues:
    issues.append("Systém je ve zdravém stavu")

for i in issues:
    print(i)
