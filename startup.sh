#!/bin/bash

HOST=`hostname`

echo $HOST > /etc/torque/server_name
echo $HOST > /var/spool/torque/server_priv/acl_svr/acl_hosts
echo root@$HOST > /var/spool/torque/server_priv/acl_svr/operators
echo root@$HOST > /var/spool/torque/server_priv/acl_svr/managers
echo "$HOST np=1" > /var/spool/torque/server_priv/nodes
echo $HOST > /var/spool/torque/mom_priv/config

pbs_server -t create
pbs_mom
pbs_sched

sleep 5

qmgr -c 'set server scheduling = true'
qmgr -c 'set server keep_completed = 300'
qmgr -c 'set server mom_job_sync = true'

qmgr -c 'create queue short'
qmgr -c 'set queue short queue_type = execution'
qmgr -c 'set queue short started = true'
qmgr -c 'set queue short enabled = true'
qmgr -c 'set queue short resources_default.walltime = 1:00:00'
qmgr -c 'set queue short resources_default.nodes = 1'
qmgr -c 'set server default_queue = short'

qmgr -c "set server submit_hosts = $HOST"
qmgr -c 'set server allow_node_submit = true'
