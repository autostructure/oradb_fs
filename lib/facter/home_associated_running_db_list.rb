####
# home_associated_running_db_list
#
# returns an array of Oracle home path associated running database lists
# looks for running pmon processes and ties them back to the home they are running from
#
# each array member takes the form: ORACLE_HOME_PATH:SID:SID:...
# example: [ '/opt/oracle/product/12.2.0/db_1:test01a:test02a', '/opt/oracle/product/12.2.0/db_2:test03a' ]
#
####
Facter.add(:home_associated_running_db_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  count = 0
  compare = ''
  pid_list = ''
  pid_sid_hash = Hash.new
  pid_home_hash = Hash.new
  home_sid_array = ['']
  home_sid_array_f = ['']

  command = 'ps -ef | grep ora_pmon_ | grep -v grep |  grep -v \'s/ora\' | awk \'{print $2":"$8}\' | sed \'s/ora_pmon_//\''
  ps_entries = %x[#{command}]

  if ps_entries.empty?
   home_sid_array_f
  else
   ps_entries.each_line do | li1 |
    holding = li1.strip.split(':')
    pid_list = holding[0]  + ',' + pid_list
    pid_sid_hash[holding[0]] = holding[1]
   end

   pid_list = pid_list.chomp(',')

   command = 'lsof -p ' + pid_list + ' | grep -G "\/opt\/.*\/bin\/oracle" | sed \'s/\/bin\/.*//\' | awk \'{print $2":"$9}\''
   lsof_entries = %x[#{command}]

   lsof_entries.each_line do | li2 |
    holding = li2.strip.split(':')
    pid_home_hash[holding[0]] = holding[1]
   end

   combined_pid_sid_home_hash = Hash[pid_sid_hash].merge(Hash[pid_home_hash]) { | key, sid, home | [home, sid] }

   combined_pid_sid_home_hash.each.with_index do | value, index |
     holding = value[1]
     home_sid_array[index] = holding[0] + ':' + holding[1]
   end

   home_sid_array = home_sid_array.sort

   home_sid_array.each do | value |
    holding = value.split(':')
    if compare == ''
     compare = holding[0]
     home_sid_array_f[count] = value
    elsif holding[0] == compare
     home_sid_array_f[count] = home_sid_array_f[count] + ':' + holding[1]
    else
     count += 1
     compare = holding[0]
     home_sid_array_f[count] = value
    end
   end

  end

  home_sid_array_f


 end
end
