# Determine if incoming patch is installed using info passed in from a custom fact
Puppet::Functions.create_function(:patch_installed) do
#
 # @param patch_num patch number of incoming patch
 # @param home_patches list of installed patches from custom fact
 # @return [String] Return patch_num or NotFound
 # @example
 #   patch_installed('123123123', '_1435125_12354125_123') => '123123123' or 'NotFound'
 dispatch :patch_installed do
   param 'String', :patch_num
   param 'String', :home_patches
   
   # return_type 'String'
 end

 def patch_installed (patch_num, home_patches)
  if home_patches.include? patch_num
   return patch_num
  end
  'NotFound'
 end
end
