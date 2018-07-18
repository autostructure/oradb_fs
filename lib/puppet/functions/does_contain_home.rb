# Determine if incoming patch is installed using info passed in from a custom fact
Puppet::Functions.create_function(:does_contain) do
#
 # @param search_list flat fact array of home associated sids
 # @param contains_list flat fact array of home associated sids to search for in the search_list
 # @param home_number home number of the home currently being worked on
 # @param home_path home path of the home currently being worked on
 # @return [String] Return 'B', 'S', 'C', 'T', 'F' 
 #   B = both input arrays are empty or the desired home is not in the incoming arrays
 #   S = search_list was empty or the desired home was not found in the search_list
 #   C = contains_list was empty or the desired home was not found in the contains_list
 #   T = the entire sid list of the desired home from contains_list WAS found in the desired home's sid list from search_list 
 #   F = at least one sid of the desired home from contains_list WAS NOT found in the desired home's sid list from search_list
 # @example
 #   does_contain( Array_A, Array_B , 'home_#', '/opt/oracle/...' )=> 'B', 'S', 'C', 'T', 'F'
 dispatch :does_contain do
   param 'Array',   :search_list
   param 'Array',   :contains_list
   param 'String',  :home_number
   param 'String',  :home_path

   # return_type 'String'
 end

 def does_contain (search_list, contains_list, home_number, home_path)
 
  search_list_compare_var = ''
  contains_list_compare_var = ''
  contains_output = Array.new
  search_match = Array.new
  contains_match = Array.new

  if search_list.length == 0 and contains_list.length == 0
   return 'B'
  elsif search_list.length == 0
   return 'S'
  elsif contains_list.length == 0
   return 'C'
  end

  holding = search_list[0].split(':')

  if holding[0] =~ /\/opt\/oracle\/.*/
   search_list_compare_var = home_path
  elsif holding[0] =~ /home_[0-9]*/
   search_list_compare_var = home_number
  elsif holding[0].length <= 8 and holding[0].length >= 1
  else
   fail
  end

  holding = contains_list[0].split(':')

  if holding[0] =~ /\/opt\/oracle\/.*/
   contains_list_compare_var = home_path
  elsif holding[0] =~ /home_[0-9]*/
   contains_list_compare_var = home_number
  elsif holding[0].length <= 8 and holding[0].length >= 1
  else
   fail
  end


  if !search_list_compare_var.empty?
   search_list.each do | value |
    holding = value.split(':')
    if holding[0] == search_list_compare_var
     search_match = holding.drop(1)
    end
   end
  else
   search_list.each.with_index do  | value, index |
    holding = value.split(':')
    search_match[index] = holding[0]
   end
  end

  if !contains_list_compare_var.empty?
   contains_list.each do | value |
    holding = value.split(':')
    if holding[0] == contains_list_compare_var
     contains_match = holding.drop(1)
    end
   end
  else
   contains_list.each.with_index do | value, index |
    holding = value.split(':')
    contains_match[index] = holding[0]
   end
  end

  if search_match.length == 0 and contains_match.length == 0
   return 'B'
  elsif search_match.length == 0
   return 'S'
  elsif contains_match.length == 0
   return 'C'
  else
   contains_match.each.with_index do | value, index |
    if search_match.include?(value)
     contains_output[index] = 'T'
    else
     contains_output[index] = 'F'
    end
   end
  end

  t_test = contains_output.include?('T')
  f_test = contains_output.include?('F')
  
  if t_test and f_test
   return 'P'
  elsif t_test and !f_test
   return 'T'
  elsif !t_test and f_test
   return 'F'
  else
   return 'F'
  end

 end
end
