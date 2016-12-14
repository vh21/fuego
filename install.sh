sudo fuego-host-scripts/docker-build.sh
sudo bash -c "if [ -f /etc/ttc.conf -a ! -f userdata/conf/ttc.conf ] ; then cp /etc/ttc.conf userdata/conf ; fi"
