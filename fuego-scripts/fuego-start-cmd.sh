#!/bin/bash
/etc/init.d/jenkins start
/etc/init.d/ssh start
/etc/init.d/netperf start
/sbin/ifconfig eth0
chown -R jenkins /userdata
exec /usr/local/bin/maintain_config_link.sh &
/bin/bash
