Facter.add(:selinux) do
  confine :kernel => 'Linux'
  setcode "/usr/sbin/sestatus | /bin/awk '{print $3 }' | /bin/awk '{gsub(\"enabled|permissive\", \"FAIL\"); print }' | /bin/awk '{gsub(\"disabled\", \"PASS\"); print }'"
end

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

Facter.add(:ivp6) do
  confine :kernel => 'Linux'
  setcode "/sbin/lsmod | /bin/grep ipv6 | /usr/bin/wc -l | /bin/awk '{gsub('1', \"FAIL\"); print }' | /bin/awk '{gsub('0', \"PASS\"); print }'"
end

Facter.add(:lowerhostname) do
  confine :kernel => 'Linux'
  setcode "/bin/hostname | /bin/awk '/[A-Z]/{print}' | /usr/bin/wc -l | /bin/awk '{gsub('1', \"FAIL\"); print }' | /bin/awk '{gsub('0', \"PASS\"); print }'"
end

Facter.add(:nslookuphostname) do
  confine :kernel => 'Linux'
  setcode "/usr/bin/nslookup `/bin/hostname` | /bin/grep -v 'server can' | /bin/grep `/bin/hostname` | /usr/bin/wc -l | /bin/awk '{gsub('1', \"PASS\"); print }' | /bin/awk '{gsub('0', \"FAIL\"); print }'"
end

Facter.add(:nslookuphostnamefqdn) do
  confine :kernel => 'Linux'
  setcode "/usr/bin/nslookup `/bin/hostname -f` | /bin/grep -v 'server can' | /bin/grep `/bin/hostname -f` | /usr/bin/wc -l | /bin/awk '{gsub('1', \"PASS\"); print }' | /bin/awk '{gsub('0', \"FAIL\"); print }'"
end

Facter.add(:nslookupreverseip) do
  confine :kernel => 'Linux'
  setcode "/usr/bin/nslookup `/bin/hostname -i` | /bin/grep -v 'server can' | /bin/grep `/bin/hostname -f` | /usr/bin/wc -l | /bin/awk '{gsub('1', \"PASS\"); print }' | /bin/awk '{gsub('0', \"FAIL\"); print }'"
end
