from fastapi import FastAPI
import subprocess, psutil, os

app = FastAPI()

@app.get("/status")
def status():
    return {
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage("/").percent
    }

@app.get("/modules")
def modules():
    return os.listdir("/srv/modules")

@app.post("/modules/run/{name}")
def run_module(name: str):
    path = f"/srv/modules/{name}"
    subprocess.Popen(["bash", path])
    return {"status": "started", "module": name}
