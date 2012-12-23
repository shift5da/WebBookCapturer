# -*- coding: utf-8 -*-
# Sina book capturer 

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'iconv'
require 'Text2EPUB'

class SinaBookCapturer
  
  def parse(url)
    parse_index(url)
  end 
  
  #####################
  # private functions #
  #####################
  private
  def parse_index(index_url)
    begin
      doc = Nokogiri::HTML.parse(open(index_url), nil, 'gb2312')#不这样写会有乱码
    rescue Errno::ETIMEDOUT => e
      puts 'Errno::ETIMEDOUT'
      return nil
    end
    
    if not doc.text =~ /连载结束/
      puts '该文章没有连载结束'
      #return nil
    end
    

    #get book title
    title = doc.xpath("//body/div[@id='wrap']/div[@class='blk_01']/h1").text()
    
    #get book author
    author = doc.xpath("//body/div[@id='wrap']/div[@class='blk_01']/div[@class='mess']/a")[0].text()
    
    #get book cover
    cover_image_url = doc.xpath("//body/div[@id='wrap']/div[@class='blk_01']/div[@class='le']/div[@class='pic']/img").attr('src');

    epub = Text2EPUB.new title, author, cover_image_url

    catalog_label = doc.xpath("//body/div[@id='wrap']/div[@class='blk_02']/div[@class='le']/div[@class='blk_03']")

    catalog_label.children().each(){|label|

      if label.node_name == 'ul'
        label.xpath('li').each(){|chapter_link|
          if not chapter_link.attr('class') == 'line'

            #get chapter title
            chapter_title = chapter_link.text()

            #get chapter url
            content_relative_url = chapter_link.xpath('a').attr('href')

            #construct chapter url
            content_url = index_url[0, index_url.rindex('/')+1] + content_relative_url

            chapter_content = parse_context(content_url)

            until chapter_content != nil
              sleep(1)
              chapter_content = parse_context(content_url)
            end

            epub.add_chapter chapter_title, chapter_content
            puts chapter_title + " ok!"
          end
        }
      end
    }
    epub.write_to_file '.'
  end

  def parse_context(content_url)
    begin
      doc = Nokogiri::HTML.parse(open(content_url), nil, 'gb2312')#不这样写会有乱码
    rescue OpenURI::HTTPError => e
      puts content_url + ' error...'
      return nil
    end
    original_content = doc.xpath("//body/div[@id='wrap']/div[@class='main']/div[@class='mainL']/div[@class='mainContent']/div[@id='contTxt']").inner_html
    Iconv.conv("UTF-8//IGNORE","GB18030//IGNORE",original_content)
  end
  
end

def test
  url = 'http://vip.book.sina.com.cn/book/index_61345.html' 
  SinaBookCapturer.new.parse(url)
  puts 'over...'
end


def search_book
  (11...200000).each do |i|
    index_url = "http://vip.book.sina.com.cn/book/index_#{i}.html"
    begin
      doc = Nokogiri::HTML.parse(open(index_url), nil, 'gb2312')#不这样写会有乱码
    rescue Errno::ETIMEDOUT => e
      puts "#{index_url}, error..."
    end

    #skip blank page
    if doc.text =~ /所访问的页面不存在/
      next
    end

    #get book title
    title = doc.xpath("//body/div[@id='wrap']/div[@class='blk_01']/h1").text()
    puts title
  end
  
end

test







