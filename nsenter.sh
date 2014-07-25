#!/bin/bash
# Assuming sudo docker run --rm --name flexdisc_instance -i -t flexdisc
PID=$(docker inspect --format {{.State.Pid}} $1)
sudo nsenter --target $PID --mount --uts --ipc --net --pid
