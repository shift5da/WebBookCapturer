require 'rubygems'
require 'zip/zip'
require 'find'
require 'fileutils'


class Zipper
 
  def self.zip(dir, zip_dir, remove_after = false)
    Zip::ZipFile.open(zip_dir, Zip::ZipFile::CREATE) do |zipfile|
      Find.find(dir) do |path|
        Find.prune if File.basename(path)[0] == ?.
        dest = /#{dir}\/(\w.*)/.match(path)
        # Skip files if they exists
        begin
          zipfile.add(dest[1],path) if dest
        rescue Zip::ZipEntryExistsError
        end
      end
    end
    FileUtils.rm_rf(dir) if remove_after
  end
  
  
  def self.unzip(zip, unzip_dir, remove_after = false)
    Zip::ZipFile.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
    FileUtils.rm(zip) if remove_after
  end
  
  def self.test
    
    puts 'aaa'
  end
  
 
end