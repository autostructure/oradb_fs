####
# home_remediation_list
#
####
Facter.add(:home_remediation_list) do
 confine :kernel => 'Linux'
 setcode do

  rem_array = ['']
  home = ''
  allowed_actions = [ 'all', 'partitioning' ]
  command = 'ls -lQ /tmp | grep -E \"puppet_remediatehome_db_[0-9]*_[[:alpha:]]*\" | awk \'$3 == "oracle" {print $9}\' | sort'
  rem_entries = %x[#{command}]

  if !rem_entries.empty?
   h_count = 0
   c_home = ''
   c_action = ''

   rem_entries.each_line do |li|

    holding = li[22..-1].strip
    home = holding.match('db_[0-9]*_')[0].chomp('_')
    action = holding.gsub(/.*_/, '').chomp('"')
    if c_home == ''
     c_home = home
     if allowed_actions.include?(action)
      if action == 'all'
       c_action = action
      elsif c_action == 'all'
      else
       c_action = action
      end
     end
    elsif c_home == home
     if allowed_actions.include?(action)
      if action == 'all'
       c_action = action
      elsif c_action == 'all'
      else
       c_action = c_action + '~' + action
      end
     end
    elsif c_home != home
     holding = c_action.split('~').uniq - [ '' ]
     for i in 0..(holding.length - 1)
      if i == 0
       c_action = holding[i]
      else
       c_action = c_action + '~' + holding[i]
      end
     end
     if c_action == ''
      c_action = 'none'
     end
     rem_array[h_count] = c_home + ':' + c_action
     h_count = h_count + 1
     c_home = home
     c_action = ''
     if allowed_actions.include?(action)
      if action == 'all'
       c_action = action
      elsif c_action == 'all'
      else
       c_action = action
      end
     end
    end
   end
   holding = c_action.split('~').uniq - [ '' ]
   for i in 0..(holding.length - 1)
    if i == 0
     c_action = holding[i]
    else
     c_action = c_action + '~' + holding[i]
    end
   end
   if c_action == ''
    c_action = 'none'
   end
   rem_array[h_count] = c_home + ':' + c_action
  end

  rem_array

 end
end

