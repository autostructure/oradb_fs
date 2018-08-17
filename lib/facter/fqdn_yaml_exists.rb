####
# fqdn_yaml_exists
#
# returns 0 or 1 based on the exsistence of /opt/puppetlabs/facter/facts.d/FQDN.yaml
#
# 1 file exists
# 0 file DNE
#
####
Facter.add(:fqdn_yaml_exists) do
 confine :kernel => 'Linux'
 setcode do

  host_fqdn = Facter.value(:fqdn) 
 
  command = 'ls /opt/puppetlabs/facter/facts.d/' + host_fqdn + '.yaml 2>/dev/null | wc -l '
  output = %x[#{command}]
  
  output.strip

 end
end

