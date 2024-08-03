#!/bin/bash
cd ~/node_monitoring/

while true
do
    pgrep -f cont_vit && echo "cont_vit ok" || (nohup ./cont_vit > cont_vit_log.out &)
    pgrep -f node_vit && echo "node_vit ok" || (nohup ./node_vit > node_vit_log.out &)
    sleep 60
done

