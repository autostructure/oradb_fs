####
# fqdn_yaml_artifactory_exists
#
# returns -2, -1, 0, 1, or 2 based on the availabilty of artifactory,
# the checksum of /opt/puppetlabs/facter/facts.d/FQDN.yaml, and the checksum of the FQDN.yaml file stored in artifcatory
#
# -2 no FQND.yaml file in Art. and the FQDN.yaml file locally is not the default file
# -1 servers domain not recognized or Art. is currently unreachable
# 0 checksums of Art. FQDN.yaml file and local FQDN.yaml file match
# 1 checksums of Art. FQDN.yaml file and local FQDN.yaml file do not match
# 2 no FQND.yaml exists in Art. and no FQDN.yaml exists locally
#
####
Facter.add(:fqdn_yaml_artifactory_exists) do
 confine :kernel => 'Linux'
 setcode do

  host_fqdn = Facter.value(:fqdn)
  
  if Facter.value(:domain) == 'wrk.fs.usda.gov' 
   area_domain = 'work'
  elsif Facter.value(:domain) == 'fdc.fs.usda.gov'
   area_domain = 'prod'
  else
   area_domain = 'fail'
  end

  if area_domain == 'fail'
   -1 #Area domain not defined
  else
   command = 'curl -s https://artifactory.fdc.fs.usda.gov/artifactory/api/storage/oracle-platform-config-' + area_domain + '/' + host_fqdn + '.yaml 2>/dev/null'
   output = %x[#{command}]
   if output.empty?
    -1 #No art. response.
   else
    command = 'curl -s https://artifactory.fdc.fs.usda.gov/artifactory/api/storage/oracle-platform-config-' + area_domain + '/' + host_fqdn + '.yaml | sed -n \'/"checksums" : {/,/}/p\' | sed -n \'s/.*md5.* : "\(.*\)".*/\1/p\''
    md5_artifactory = %x[#{command}]

    local_file = '/opt/puppetlabs/facter/facts.d/' + host_fqdn + '.yaml' 

    if !md5_artifactory.empty?
     if File.exist?(local_file)
      command = 'md5sum /opt/puppetlabs/facter/facts.d/' + host_fqdn + '.yaml | awk \'{print $1}\''
      md5_local = %x[#{command}]
      if md5_local != md5_artifactory
       1 #Checksum mismatch. Pull new file.
      else
       0 #Checksum match.
      end
     else
      1 #Local file DNE.
     end
    else
     if File.exist?(local_file)
      command = 'md5sum /opt/puppetlabs/facter/facts.d/' + host_fqdn + '.yaml | awk \'{print $1}\''
      md5_local = %x[#{command}]
      if md5_local.strip != '8afabfeeeb946ae0c2ca8b5db69db0ff'
       -2 #Art. file DNE. Local file is not the default file.
      else #checksum match
       0 #Art. file DNE. Local file exists.
      end
     else
      2 #Art. file DNE. Local file DNE.
     end
    end
   end
  end
 end
end

