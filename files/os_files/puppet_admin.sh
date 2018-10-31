#!/bin/bash
################################################################################
# File     :  /usr/local/bin/puppet_admin.sh
# Author   : matthewparker
# Email    : dimensional,dba@comcast.net
# Date     : October 17, 2017
# Last Mod : October 31, 2018
# Version  : 2.2
# Purpose  : This is the admin utility for the Oracle Platform puppet module.
#            This is used by the OPS/eDBA team to interact with puppet.
# Command  :
#            These are the commands for the Database and OEM Platform.
#
#            /usr/local/bin/puppet_admin.sh agent run
#            /usr/local/bin/puppet_admin.sh agent disable
#            /usr/local/bin/puppet_admin.sh agent enable
#            /usr/local/bin/puppet_admin.sh service stop
#            /usr/local/bin/puppet_admin.sh service start
#            /usr/local/bin/puppet_admin.sh yaml remove
#
################################################################################

########################################
# VERIFY RUNNING AS ROOT
########################################
if [[ $EUID -ne 0 ]] ; then
 echo "This script must be run with root permissions" 1>&2
 exit 1
fi

human=`/usr/bin/who am i | awk '{print $1}'`
if [[ ("$1" == "agent" && "$2" = "run") ]]; then
  /usr/local/bin/puppet agent -t
elif [[ ("$1" == "agent" && "$2" = "disable") ]]; then
  if [ -f /opt/puppetlabs/puppet/cache/state/agent_disabled.lock ]; then
    echo 'Agent was already Disabled.'
    cat /opt/puppetlabs/puppet/cache/state/agent_disabled.lock | awk -F\" '{print $4}'
  else
    echo 'Disabling Agent.'
    /usr/local/bin/puppet agent --disable "User:${human} Performing Maintenance started on `date`"
    echo 'Agent Disabled.'
  fi
elif [[ ("$1" == "agent" && "$2" = "enable") ]]; then
  if [ ! -f /opt/puppetlabs/puppet/cache/state/agent_disabled.lock ]; then
    echo 'Agent was already Enabled.'
  else
    echo 'Enabling Agent.'
    /usr/local/bin/puppet agent --enable
    echo 'Agent Enabled.'
  fi
elif [[ ("$1" == "service" && "$2" = "stop") ]]; then
  status=`/usr/bin/systemctl status puppet | grep "Active: active (running)" | awk -F\( '{print $2}' | awk -F\) '{print $1}'`
  if [[ "${status}" == "running" ]] ; then
    echo 'Stopping Puppet.'
    /usr/bin/systemctl stop puppet
    echo 'Puppet Stopped.'
  else
    echo 'Puppet Already Stopped.'
  fi
elif [[ ("$1" == "service" && "$2" = "start") ]]; then
  status=`/usr/bin/systemctl status puppet | grep "Active: active (running)" | awk -F\( '{print $2}' | awk -F\) '{print $1}'`
  if [[ "${status}" == "running" ]] ; then
    echo 'Puppet Already Stared.'
  else
    echo 'Starting Puppet.'
    /usr/bin/systemctl start puppet
    echo 'Puppet Started.'
  fi
elif [[ ("$1" == "yaml" && "$2" = "remove") ]] ; then
        /usr/bin/rm -f /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml
else
        echo 'usage: $0 {agent disable|agent enable|service stop|service start|yaml remove}'
fi


