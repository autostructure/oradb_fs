Facter.add(:fqdn_yaml_exists) do
 confine :kernel => 'Linux'
 setcode do

  host_fqdn = Facter.value(:fqdn) 
 
  command = 'ls /opt/puppetlabs/facter/facts.d/' + host_fqdn + '.yaml 2>/dev/null | wc -l '
  output = %x[#{command}]
  
  output.strip

 end
end

