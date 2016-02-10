#!/bin/bash
useradd dc
echo "dc:adm" | chpasswd
adduser dc sudo
mkdir /home/dc
chown -R dc /home/dc
