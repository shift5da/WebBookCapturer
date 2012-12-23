# -*- coding: utf-8 -*-
# File operater util class

module Util
  
  class FileUtil

    #create file according filename, content, path
    def self.create_file(file_name, content, path=nil)
      if path == nil
        absolute_file_path = file_name
      else
        if path.length == (path.rindex('/')+1)
          absolute_file_path = "#{path}#{file_name}"
        else
          absolute_file_path = "#{path}/#{file_name}"
        end
      end
      File.open(absolute_file_path, 'w+') do |out|
        out.write content
      end
    end
  end
end


def create_file_test
  Util::FileUtil.create_file('1.txt', 'aaa')
  Util::FileUtil.create_file('2.txt', 'aaa', '/Users/wuda/Documents/workspace/ruby/WebBookCapturer/')
  Util::FileUtil.create_file('3.txt', 'aaa', '/Users/wuda/Documents/workspace/ruby/WebBookCapturer')  
end
