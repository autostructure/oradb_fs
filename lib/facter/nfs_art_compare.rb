####
# nfs_art_compare
#
####
Facter.add(:nfs_art_compare) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => :oem
 setcode do
  nfs_art_array = [ '' ]
  hour = Time.now.hour
#  if ( hour >= 20 and hour <= 21 ) or ( hour >= 4 and hour <= 5 ) or ( hour >= 12 and hour <= 13 )
  if ( hour >= 0 and hour <= 12 ) or ( hour >= 12 and hour <= 23 )
   if Facter.value(:domain) == 'wrk.fs.usda.gov'
    area_domain = 'work'
   elsif Facter.value(:domain) == 'fdc.fs.usda.gov'
    area_domain = 'prod'
   else
    fail_out = 1
   end
   available_patches = Facter.value(:"oradb_fs::12_2::available_patches")
   if !available_patches.empty?
    available_patches.each_with_index do | patch_path, index |
     version = ''
     quarter = ''
     quarter_f = ''
     month = ''
     add_years = ''
     year_f = ''
     patch_date = ''
     yaml_patch_path = ''
     update_nfs = ''
     holding = patch_path.split(/[.]/)
     if holding[0] == '12_2'
      version = '12.2.0.1'
     else
      fail_out = 1
     end
     if !holding[1].empty?
      quarter = ( holding[1].to_i + holding[2].to_i ).modulo(4) 
      if quarter == 0
       quarter_f = 4
      else
       quarter_f = quarter
      end
      if quarter_f == 1
       month = 'jan'
      elsif quarter_f == 2
       month = 'apr'
      elsif quarter_f == 3
       month = 'jul'
      elsif quarter_f == 4
       month = 'oct'
      else
       fail_out = 1
      end
     end
     year = 2017
     add_years = ( ( holding[1].to_i + holding[2].to_i - 1 ) / 4 ).floor
     year_f = year + add_years
     patch_date = "#{year_f}q#{quarter_f}#{month}"
     yaml_patch_path = patch_path.gsub(/[.]/,'_')
     if holding[2] == '0'
      db_zip = Facter.value(:"oradb_fs::#{yaml_patch_path}::db_patch_file")
      ojvm_zip = Facter.value(:"oradb_fs::#{yaml_patch_path}::ojvm_patch_file")
      opatch_zip = Facter.value(:"oradb_fs::#{yaml_patch_path}::opatch_file")
      file_pathes = [ "oracle-media-local/db/#{version}/psu/#{patch_date}/#{patch_path}/db/#{db_zip}:/fslink/sysinfra/oracle/automedia/#{version}/db/#{patch_path}/db/#{db_zip}",
                      "oracle-media-local/db/#{version}/psu/#{patch_date}/#{patch_path}/ojvm/#{ojvm_zip}:/fslink/sysinfra/oracle/automedia/#{version}/db/#{patch_path}/ojvm/#{ojvm_zip}",
                      "oracle-media-local/db/#{version}/psu/#{patch_date}/#{patch_path}/opatch/#{opatch_zip}:/fslink/sysinfra/oracle/automedia/#{version}/db/#{patch_path}/opatch/#{opatch_zip}" ]
     else
      db_zip = Facter.value(:"oradb_fs::#{yaml_patch_path}::db_patch_file")
      file_pathes = [ "oracle-media-local/db/#{version}/psu/#{patch_date}/#{patch_path}/db/#{db_zip}:/fslink/sysinfra/oracle/automedia/#{version}/db/#{patch_path}/db/#{db_zip}" ]
     end
     file_pathes.each do | path_pair |
      art_path = path_pair.split(':') [0]
      nfs_path = path_pair.split(':') [1]
      command = "/bin/curl -s https://artifactory.fdc.fs.usda.gov/artifactory/api/storage/#{art_path}" + ' | /bin/sed -n \'/"checksums" : {/,/}/p\' | /bin/sed -n \'s/.*md5.* : "\(.*\)".*/\1/p\''
      art_md5 = %x[#{command}]
      command = "/bin/md5sum #{nfs_path} 2>/dev/null" + ' | /bin/awk \'{print $1}\'' 
      nfs_md5 = %x[#{command}]
      if nfs_md5.empty? and !art_md5.empty?
       if update_nfs != -1 or update_nfs != -2 or update_nfs != -3
        update_nfs = 1
       end
      elsif !nfs_md5.empty? and !art_md5.empty?
       if update_nfs != -1 or update_nfs != -2 or update_nfs != -3
        if nfs_md5 == art_md5
         update_nfs = 0
        else
         update_nfs = 1
        end
       end
      elsif !nfs_md5.empty? and art_md5.empty?
       if update_nfs == -2
        update_nfs = -3
       else
        update_nfs = -1
       end
      elsif nfs_md5.empty? and art_md5.empty?
       if update_nfs == -1
        update_nfs = -3
       else
        update_nfs = -2
       end        
      else
       fail_out = 1
      end
     end
     nfs_art_array[index] = "#{patch_path}:#{update_nfs}:#{version}:#{patch_date}:#{yaml_patch_path}"
    end
   end
  else
   fail_out = 0
  end
  if fail_out == 0
   [ '0' ]
  elsif fail_out == 1
   [ '' ]
  else
   nfs_art_array
  end
 end
end

