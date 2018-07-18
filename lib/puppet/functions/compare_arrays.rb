Puppet::Functions.create_function(:compare_arrays) do
 dispatch :compare_arrays do
   param 'Array',   :search_list
   param 'Array',   :contains_list
   # return_type 'String'
 end

 def compare_arrays (search_list, contains_list)

  contains_output = Array.new

  if search_list.empty?
   search_list = ['']
  end
  
  if contains_list.empty?
   contains_list = ['']
  end

  if search_list == [''] and contains_list == ['']
   return 'B'
  elsif search_list == ['']
   return 'S'
  elsif contains_list == ['']
   return 'C'
  else
   contains_list.each.with_index do | value, index |
    if search_list.include?(value)
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
   fail
  end
 
 end
end
