####
# home_associated_remediation_list
#
# returns an array of home variable set assciated database names that are marked for remediation
# remediation is enabled by creating /tmp/puppet_remediate_db_NUM_SID_ACTION as the Oracle user
#
# each array member takes the form of: HOME_VARIABLE_SET:SID~ACTION~ACTION...:SID~ACTION...
# example: [ 'db_1:test01a~all:test02a~security', 'db_2:test03a~patch~security' ]
#
####
Facter.add(:home_associated_remediation_list) do
 confine :kernel => 'Linux'
 setcode do

  rem_array = ['']
  home = ''
  sid = ''
  allowed_actions = [ 'all', 'patch', 'security' ]
  command = 'ls -lQ /tmp | grep -E \"puppet_remediate_db_[0-9]*_[[:alpha:]]{1}[A-Za-z0-9_\$\#]{0\,7}_[[:alpha:]]*\" | awk \'$3 == "oracle" {print $9}\' | sort'
  rem_entries = %x[#{command}]

  if !rem_entries.empty?
   h_count = 0
   s_count = 0
   c_home = ''
   c_sid = ''
   c_action = ''

   rem_entries.each_line do |li|

    holding = li[18..-1].strip
    home = holding.match('db_[0-9]*_')[0].chomp('_')
    sid = holding.gsub(/db_[0-9]*_/, '').gsub(/_.*/, '')
    action = holding.gsub(/.*_/, '').chomp('"')
    if c_home == ''
     c_home = home
     c_sid = sid
     if allowed_actions.include?(action)
      if action == 'all'
       c_action = action
      elsif c_action == 'all'
      else
       c_action = action
      end
     end
    elsif c_home == home
     if c_sid == sid
      if allowed_actions.include?(action)
       if action == 'all'
        c_action = action
       elsif c_action == 'all'
       else
        c_action = c_action + '~' + action
       end
      end
     else
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
      if s_count == 0
       rem_array[h_count] = c_home + ':' + c_sid + '~' + c_action
      else
       rem_array[h_count] = rem_array[h_count] + ':' + c_sid + '~' + c_action
      end
      s_count = s_count + 1
      c_sid = sid
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
     if s_count == 0
      rem_array[h_count] = c_home + ':' + c_sid + '~' + c_action
     else
      rem_array[h_count] = rem_array[h_count] + ':' + c_sid + '~' + c_action
     end
     s_count = 0
     h_count = h_count + 1
     c_home = home
     c_sid = sid
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
   if s_count == 0
    rem_array[h_count] = c_home + ':' + c_sid + '~' + c_action
   else
    rem_array[h_count] = rem_array[h_count] + ':' + c_sid + '~' + c_action
   end
  end

  rem_array

 end
end

