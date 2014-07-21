#!/bin/bash
# Assuming sudo docker run --rm --name flexdisc_instance -i -t flexdisc
PID=$(docker inspect --format {{.State.Pid}} flexdisc_instance)
sudo nsenter --target $PID --mount --uts --ipc --net --pid
