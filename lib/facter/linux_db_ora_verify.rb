####
# selinux
#
# return PASS or FAIL based on the setting of selinux
# 
# FAIL selinux is set to 'enabled' or 'permissive'
# PASS selinux is set to 'deisabled'
#
####
Facter.add(:selinux) do
  confine :kernel => 'Linux'
  setcode "/usr/sbin/sestatus | /bin/awk '{print $3 }' | /bin/awk '{gsub(\"enabled|permissive\", \"FAIL\"); print }' | /bin/awk '{gsub(\"disabled\", \"PASS\"); print }'"
end

####
# chk_iptables
#
# returns PASS or FAIL based on the status of iptables
#
# FAIL iptables is 'on' or 'enabled'
# PASS iptables is 'off' or 'disabled'
#
####
Facter.add(:chk_iptables) do
  confine :kernel => 'Linux'
  setcode do
    kmv = Facter.value(:kernelmajversion)
    if (kmv == "2.6") or (kmv == "3.08")
      Facter::Core::Execution.exec('chkconfig --list iptables | awk \'{print $5}\' | awk -F: \'{print $2 }\' | /bin/awk \'{gsub("off", "PASS"); print }\' | /bin/awk \'{gsub("on", "FAIL"); print }\'')
    elsif (kmv == "3.10")
      Facter::Core::Execution.exec('/bin/systemctl list-unit-files | grep iptables.service | awk \'{print $2 }\' | /bin/awk \'{gsub("disabled", "PASS"); print }\' | /bin/awk \'{gsub("enabled", "FAIL"); print }\'')
    else
      Facter::Core::Execution.exec('echo "FAIL"') 
    end
  end
end

####
# ivp6
#
# returns PASS or FAIL based on whether the ipv6 kernal module is loaded or not
#
# FAIL ipv6 entry returned from lsmod
# PASS ipv6 entry not returned from lsmod
#
####
Facter.add(:ivp6) do
  confine :kernel => 'Linux'
  setcode "/sbin/lsmod | /bin/grep ipv6 | /usr/bin/wc -l | /bin/awk '{gsub('1', \"FAIL\"); print }' | /bin/awk '{gsub('0', \"PASS\"); print }'"
end

####
# lowerhostname
#
# returns PASS or FAIL based on the case of the servers hostname in /etc/hostname
#
# FAIL hostname entry is not lowercase
# PASS hostname entry is lowercase
#
####
Facter.add(:lowerhostname) do
  confine :kernel => 'Linux'
  setcode "/bin/hostname | /bin/awk '/[A-Z]/{print}' | /usr/bin/wc -l | /bin/awk '{gsub('1', \"FAIL\"); print }' | /bin/awk '{gsub('0', \"PASS\"); print }'"
end

####
# nslookuphostname
#
# return PASS or FAIL based on DNS registration of the server by it's hostname
#
# FAIL DNS entry for this server DNE
# PASS DNS entry for this server exists
#
###
Facter.add(:nslookuphostname) do
  confine :kernel => 'Linux'
  setcode "/usr/bin/nslookup `/bin/hostname` | /bin/grep -v 'server can' | /bin/grep `/bin/hostname` | /usr/bin/wc -l | /bin/awk '{gsub('1', \"PASS\"); print }' | /bin/awk '{gsub('0', \"FAIL\"); print }'"
end

####
# nslookuphostnamefqdn
#
# return PASS or FAIL based on DNS registration of the server by it's FQDN
#
# FAIL DNS entry for this server DNE
# PASS DNS entry for this server exists
#
####
Facter.add(:nslookuphostnamefqdn) do
  confine :kernel => 'Linux'
  setcode "/usr/bin/nslookup `/bin/hostname -f` | /bin/grep -v 'server can' | /bin/grep `/bin/hostname -f` | /usr/bin/wc -l | /bin/awk '{gsub('1', \"PASS\"); print }' | /bin/awk '{gsub('0', \"FAIL\"); print }'"
end

####
# nslookupreverseip
#
# return PASS or FAIL based on DNS registration of the server by it's IP address
#
# FAIL DNS entry for this server DNE
# PASS DNS entry for this server exists
#
####
Facter.add(:nslookupreverseip) do
  confine :kernel => 'Linux'
  setcode "/usr/bin/nslookup `/bin/hostname -i` | /bin/grep -v 'server can' | /bin/grep `/bin/hostname -f` | /usr/bin/wc -l | /bin/awk '{gsub('1', \"PASS\"); print }' | /bin/awk '{gsub('0', \"FAIL\"); print }'"
end
