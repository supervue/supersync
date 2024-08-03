#!/bin/bash
cd ~/node_monitoring/check-pull-run-kill-delete/

while true
do
    pgrep -f 1check && echo "1 ok" || (nohup ./1check > 1_log.out &)
    pgrep -f 2pullrun && echo "2 ok" || (nohup ./2pullrun > 2_log.out &)
    pgrep -f 3killdel && echo "3 ok" || (nohup ./3killdel > 3_log.out &)
    sleep 60
done

