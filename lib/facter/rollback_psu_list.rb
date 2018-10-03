#/tmp/puppet_rollback_db_NUM_PATCH_PATH
Facter.add(:rollback_psu_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  home_array = ['']
  home_array_f = ['']

#  command = 'ls -lQ /tmp | grep -E \"puppet_rollback_db_[0-9]*_[0-9]{4}_[0-9]{2}[[:alpha:]]{3}_to_[0-9]{4}_[0-9]{2}[[:alpha:]]{3}\"$ | awk \'$3 == "oracle" {print $9}\''
  command = 'ls -lQ /tmp | grep -E \"puppet_rollback_db_[0-9]{1}_12_2\\.[1-9]?[0-9]\\.[0-2]\"$\|\"puppet_rollback_db_[0-9]{1}_[1-9][0-9]\\.[1-9]?[0-9]\\.[0-2]\"$ | awk \'$3 == "oracle" {print $9}\''

  rollback_entries = %x[#{command}]

  if !rollback_entries.empty?
   rollback_entries.each_line.with_index do |li, index|

    holding = li.gsub('"','').strip.split("_")

    if holding.length == 6
      home_array[index] = holding[2] + '_' + holding[3] + ':' + holding[4] + '_' + holding[5]
    else
     home_array[index] = holding[2] + '_' + holding[3] + ':' + holding[4]
    end

   end
 
   home_array = home_array.sort
 
   count = 0
   compare = ''

   home_array.each do |li|
 
    holding = li.split(":")
    if compare == ''
     compare = holding[0]
     home_array_f[count] = li 
    elsif holding[0] == compare
     home_array_f[count] = home_array_f[count] + ':' + holding[1]
    else
     count = count + 1
     compare = holding[0]
     home_array_f[count] = li
    end
   end
  end
  home_array_f

 end
end
