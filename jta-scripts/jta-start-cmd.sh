#!/bin/bash
/etc/init.d/jenkins start
/etc/init.d/ssh start
/sbin/ifconfig eth0
chown -R jenkins /userdata
/bin/bash
