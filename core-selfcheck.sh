#!/usr/bin/env bash

echo "CPU:"; lscpu | head -5
echo "RAM:"; free -h
echo "DISK:"; df -h /
echo "SERVICES:"
systemctl --failed
