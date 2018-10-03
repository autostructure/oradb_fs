####
# home_associated_delete_db_list
#
# returns an array of home variable set assciated database names that have the 'delete database' destructor enabled
# destructor is enabled by creating /tmp/puppet_delete_db_NUM_SID as the Oracle user
#
# each array member takes the form of: HOME_VARIABLE_SET:SID:SID:...
# example: [ 'db_1:test01a:test02a', 'db_2:test03a' ]
#
####
Facter.add(:home_associated_delete_db_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  home_array = ['']


  command = 'ls -lQ /tmp | grep -E \"puppet_delete_db_[0-9]*_[[:alpha:]]{1}[A-Za-z0-9_\$\#]{0\,7}\"$ | awk \'$3 == "oracle" {print $9}\' | sort'
  delete_entries = %x[#{command}]

  if !delete_entries.empty?
   count = 0
   compare = ''
 
   delete_entries.each_line do |li|
 
    holding = li[15..-1].strip
    home = holding.match('db_[0-9]*_')[0]
    sid = holding.gsub(/db_[0-9]*_/, '').chomp('"')
    home = home.chomp('_')

    if compare == ''
     compare = home
     home_array[count] = compare  + ':' + sid
    elsif home == compare
     home_array[count] = home_array[count] + ':' + sid
    else
     count = count + 1
     compare = home
     home_array[count] = compare + ':' + sid
    end
   end
  end

  home_array

 end
end
