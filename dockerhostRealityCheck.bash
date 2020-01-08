#!/bin/bash
#Micahel.Hug@greensky.com

set -e

#docker
echo "Checking if docker is active (running now)"
systemctl is-active docker
echo "Checking if docker is enabled (will start at boot)"
systemctl is-enabled docker

#data-dog
echo "Checking if datadog container is active (running now)"
docker inspect --format '{{.State.Running}}' dd-agent | grep --word-regexp true
echo "Checking if datadog container is set to restart alwasy"
docker inspect --format "{{ .HostConfig.RestartPolicy.Name }}" dd-agent | grep --word-regexp always

#splunk
echo "Checking if splunk is active (running now)"
systemctl is-active SplunkForwarder
echo "Checking if splunk is enabled (will start at boot)"
systemctl is-enabled SplunkForwarder

#freeIPA
echo "Checking if freeipa is active (running now)"
systemctl is-active sssd
echo "Checking if freeipa is enabled (will start at boot)"
systemctl is-enabled sssd

#ntp
echo "Checking if ntp is active (running now)"
systemctl is-active ntpd
echo "Checking if ntp is enabled (will start at boot)"
systemctl is-enabled ntpd

#timezone
echo "Checking timezone"
timedatectl | grep 'Time zone' | grep --word-regexp America/New_York

#check if it was patched in the last 30 days
echo "Checking lastpatch"
INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id) 
EC2_REGION=$(curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/') 
PATCHDATESTRING=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Last_patch" --region $EC2_REGION --query "Tags[].Value" --output text) && echo $PATCHDATESTRING
[[ $(date --date="$(date) -30 days" +%s) -lt $(date --date="$PATCHDATESTRING" +%s) ]]

#endgame
echo "validate override to endgame esensor to run it with a nice value"
grep 'Nice=10' /etc/systemd/system/esensor.service.d/override.conf

#snmp
echo "validate snmp is less than default chatty"
ps -ef | grep snmp | grep '[/]usr/sbin/snmpd -LS0-5d -f'

#devloyment user
echo "check if svcdeployprod home directory created"
ls /home | grep --word-regexp svcdeployprod

#swap
echo "check if we have swap"
[[ $(swapon -s | wc -l) -gt 0 ]]

echo "
  ==============================
  ========== Success ===========
  =============================="
