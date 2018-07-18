#!/bin/ksh
logs=/home/oracle/cleanup/logs
scripts=/home/oracle/cleanup/logs
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/em13.2.0
export EM_INST_HOME=$ORACLE_HOME/gc_inst
export AGENT_HOME=/opt/oracle/emagent/agent_inst
export AGENT_LOG=$AGENT_HOME/sysman/log
export MW_HOME=$ORACLE_HOME/middleware

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Size of $ORACLE_BASE prior to cleanup.
echo '##############################################################'
df -k $ORACLE_BASE
echo '##############################################################'

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up logs under $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs.
echo '##############################################################'
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs -name EMGC_OMS* -mtime +7|xargs rm -Rf

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up logs under $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs.
echo '##############################################################'
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs -name EMGC_ADMINSERVER.out* -mtime +7|xargs rm -Rf
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs -name GCDomain.log* -mtime +7|xargs rm -Rf
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs -name ohs_admin.log* -mtime +7|xargs rm -Rf

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up logs under $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs.
echo '##############################################################'
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/BIP/logs -name BIP.out* -mtime +7|xargs rm -Rf
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/BIP/logs -name BIP.log* -mtime +7|xargs rm -Rf

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up logs under $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_OMS1/adr/diag/ofm/EMGC_DOMAIN/EMOMS/incident.
echo '##############################################################'
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_OMS1/adr/diag/ofm/EMGC_DOMAIN/EMOMS/incident -name incdir* -mtime +7|xargs rm -Rf

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up logs under $EM_INST_HOME/em/EMGC_OMS1/sysman/log.
echo '##############################################################'
find $EM_INST_HOME/em/EMGC_OMS1/sysman/log -name emoms_pbs*.trc* -mtime +14|xargs rm -Rf
find $EM_INST_HOME/em/EMGC_OMS1/sysman/log -name oms_diag_info*.msg -mtime +30|xargs rm -Rf
find $EM_INST_HOME/em/EMGC_OMS1/sysman/log -name repo_dump*.html -mtime +30|xargs rm -Rf
find $EM_INST_HOME/em/EMGC_OMS1/sysman/log/jvmdlogs -name jvmdengine.log.* -mtime +30|xargs rm -Rf

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up logs under $EM_INST_HOME/user_projects/domains/GCDomain/servers/ohs1/logs.
echo '##############################################################'
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/ohs1/logs -name ohs1*.log -mtime +14|xargs rm -Rf
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/ohs1/logs -name admin_log.* -mtime +14|xargs rm -Rf
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/ohs1/logs -name em_upload_http_access_log.* -mtime +14|xargs rm -Rf
find $EM_INST_HOME/user_projects/domains/GCDomain/servers/ohs1/logs -name em_upload_https_access_log.* -mtime +14|xargs rm -Rf

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Clean up agent log files under $AGENT_LOG.
echo '##############################################################'
find $AGENT_LOG -name gcagent.log.* -mtime +14|xargs rm -Rf 2>&1
find $AGENT_LOG -name gcagent_sdk.trc.* -mtime +14|xargs rm -Rf 2>&1
find $AGENT_LOG -name emdctlj.log.* -mtime +14|xargs rm -Rf 2>&1

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Size of $ORACLE_BASE after cleanup.
echo '##############################################################'
df -k $ORACLE_BASE


########################################################
# Rename cleanup.log file and delete old log files
########################################################
    mv $logs/cleanup.log $logs/cleanup.log.$(date +%Y%m%d%H%M)
    chmod 774 $logs/cleanup.log*
    find $logs -name cleanup.log.* -mtime +7|xargs rm -Rf

