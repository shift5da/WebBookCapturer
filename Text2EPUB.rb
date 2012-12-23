# -*- coding: utf-8 -*-
# convert text to epub file util class

require "rubygems"
require "fileutils"
require 'nokogiri'
require 'iconv'
require 'util/zipper'
require 'open-uri'

class Text2EPUB
  
  class Chapter
    attr_accessor :chapter_title
    attr_accessor :chapter_content
    attr_accessor :chapter_file_name
    attr_accessor :chapter_xhtml_file_name
    def initialize chapter_title, chapter_content, chapter_file_name
      @chapter_title = chapter_title
      @chapter_content = chapter_content
      @chapter_file_name = chapter_file_name
      @chapter_xhtml_file_name = "#{@chapter_file_name}.xhtml"
    end
  end
  
  
  attr_accessor :book_name
  attr_accessor :author
  attr_accessor :book_path
  attr_accessor :chapters
  attr_accessor :cover_image_url
  
  
  def initialize book_name, author, cover_image_url
    @book_name = book_name
    @author = author
    @cover_image_url = cover_image_url
    @chapters = Array.new
  end
  
  def add_chapter(chapter_title, chapter_content)
    chapter = Chapter.new chapter_title, chapter_content, "chapter#{chapters.length+1}"
    @chapters << chapter
  end
  
  def write_to_file book_dir
    if book_dir.rindex('/') == book_dir.length-1
      @book_path = book_dir + book_name
    else
      @book_path = "#{book_dir}/#{book_name}"
    end
    FileUtils.rm_r @book_path if File::exists? @book_path
    
    FileUtils.rm "#{@book_path}.epub" if File::exists? "#{@book_path}.epub"
    
    FileUtils.mkdir_p("#{@book_path}/META-INF")
    FileUtils.mkdir_p("#{@book_path}/OEBPS/images")
    
    File.open("#{@book_path}/OEBPS/images/cover.jpg", 'w+') do |out|
      out.write open(@cover_image_url).read
    end
    
    create_mimetype_file
    create_container_xml_file
    create_content_opf_file
    create_stylesheet_css_file
    create_toc_ncx_file
    create_cover_xhtml_file
    create_catalog_xhtml_file
    create_copyright_xhtml_file
    create_chapter_xhtml_files
    package_epub_file
    
    
  end
  
  
  
  #####################
  # private functions #
  #####################
  private
  
  
  def create_mimetype_file
    File.open("#{book_path}/mimetype", 'w') { |file|
      file.print 'application/epub+zip'
    }
  end
  
  def create_container_xml_file
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.container('version'=>'1.0', 'xmlns'=>'urn:oasis:names:tc:opendocument:xmlns:container'){
        xml.rootfiles {
          xml.rootfile('full-path'=>'OEBPS/content.opf', 'media-type'=>'application/oebps-package+xml')
        }
      }
    end
    File.open("#{book_path}/META-INF/container.xml", 'w') { |file|
      file.puts builder.to_xml
    }
  end
  
  def create_content_opf_file
    builder = Nokogiri::XML::Builder.new do |xml|
        xml.package('xmlns'=>'http://www.idpf.org/2007/opf', 'version'=>'2.0', 'unique-identifier'=>'uuid_id') {
          xml.metadata('xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance', \
          'xmlns:dcterms'=>'http://purl.org/dc/terms/', \
          'xmlns:calibre'=>'http://calibre.kovidgoyal.net/2009/metadata', \
          'xmlns:dc'=>'http://purl.org/dc/elements/1.1/') {   
            xml['dc'].title @book_name
            xml['dc'].creator @author
            xml['dc'].subject ''
            xml['dc'].language 'zh-cn'
            xml['dc'].date Time.now.strftime("%Y-%m-%d")
            xml['dc'].contributor ''
            xml['dc'].type_ ''
            xml['dc'].format 'Text/html(.xhtml,.html)'
            xml.meta('name'=>'cover', 'content'=>'cover-image')
          }
          xml.manifest {
            xml.item('id'=>'ncx', 'href'=>'toc.ncx', 'media-type'=>'application/xhtml+xml')
            xml.item('id'=>'cover', 'href'=>'cover.xhtml', 'media-type'=>'application/xhtml+xml')
            xml.item('id'=>'copyright', 'href'=>'copyright.xhtml', 'media-type'=>'application/xhtml+xml')
            xml.item('id'=>'catalog', 'href'=>'catalog.xhtml', 'media-type'=>'application/xhtml+xml')
            @chapters.each { |chapter|
              xml.item('id'=>"#{chapter.chapter_file_name}", 'href'=>"#{chapter.chapter_xhtml_file_name}", 'media-type'=>'application/xhtml+xml')
            }
            xml.item('id'=>'cover-image', 'href'=>'images/cover.jpg', 'media-type'=>'image/jpeg')
            
            
          }
          xml.spine('toc'=>'ncx') {
            xml.itemref('idref'=>'cover')
            xml.itemref('idref'=>'copyright')
            xml.itemref('idref'=>'catalog')
            @chapters.each { |chapter|
              xml.itemref('idref'=>"#{chapter.chapter_file_name}")
            }
            xml.itemref('idref'=>'copyright')
          }
          xml.guide {
            xml.reference('href'=>'cover.xhtml', 'type'=>'text', 'title'=>'封面')
            xml.reference('href'=>'catalog.xhtml', 'type'=>'text', 'title'=>'目录')
          }
        }
    end
    
    File.open("#{book_path}/OEBPS/content.opf", 'w') { |file|
      file.puts builder.to_xml
    }
  end
  
  def create_stylesheet_css_file
    File.open("#{book_path}/OEBPS/stylesheet.css", 'w') { |file|
      file.puts 'h1{text-align:right; margin-right:2em; page-break-before: always; font-size:1.6em; font-weight:bold;} h3 { text-align: center;}p.center{text-align:center;}p.catalog{margin:20px 10px;padding:0;}'
    }
  end
  
  def create_toc_ncx_file
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ncx('xmlns'=>'http://www.daisy.org/z3986/2005/ncx/', 'version'=>'2005-1') {
        xml.head{
          xml.meta('content'=>'178_0','name'=>'dtb:uid')
          xml.meta('content'=>'2','name'=>'dtb:depth')
          xml.meta('content'=>'0','name'=>'dtb:totalPageCount')
          xml.meta('content'=>'0','name'=>'dtb:maxPageNumber')
        }
        xml.docTitle{
          xml.text_ @book_name
        }
        xml.docAuthor{
          xml.text_ @author
        }
        xml.navMap{
          xml.navPoint('id'=>'catalog', 'playOrder'=>'0'){
            xml.navLabel{
              xml.text_ '目录'
            }
            xml.content('src'=>'catalog.xhtml')
          }
          
          count = 1
          
          @chapters.each { |chapter|
            xml.navPoint('id'=>"#{chapter.chapter_file_name}", 'playOrder'=>"#{count}"){
              xml.navLabel{
                xml.text_ "#{chapter.chapter_title}"
              }
              xml.content('src'=>"#{chapter.chapter_xhtml_file_name}")
            }
            count = count +1
          }
          
        }
      }
      
    end
    
    File.open("#{book_path}/OEBPS/toc.ncx", 'w') { |file|
      file.puts builder.to_xml
    }
    
  end
  
  
  def create_catalog_xhtml_file
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset(
      'html',
      "-//W3C//DTD XHTML 1.1//EN",
      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
      )
      xml.html('xmlns'=>'http://www.w3.org/1999/xhtml', 'xml:lang'=>'zh-CN'){
        xml.head{
          xml.title '导航'
          xml.link('href'=>'stylesheet.css', 'type'=>'text/css', 'rel'=>'stylesheet')
          #xml.link('href'=>'page-template.xpgt', 'type'=>'application/vnd.adobe-page-template+xml', 'rel'=>'stylesheet')
        }
        xml.body{
          xml.h1 '目录'
          @chapters.each { |chapter|
            xml.p('class'=>'catalog'){
              xml.a('href'=>"#{chapter.chapter_xhtml_file_name}"){
                xml.text "#{chapter.chapter_title}"
              }
            }
          }
        }
      }
    end
    
    File.open("#{book_path}/OEBPS/catalog.xhtml", 'w') { |file|
      file.puts builder.to_xml
    }
    
  end
  
  def create_copyright_xhtml_file
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset(
      'html',
      "-//W3C//DTD XHTML 1.1//EN",
      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
      )
      xml.html('xmlns'=>'http://www.w3.org/1999/xhtml', 'xml:lang'=>'zh-CN'){
        xml.head{
          xml.title 'copyright'
          xml.link('href'=>'stylesheet.css', 'type'=>'text/css', 'rel'=>'stylesheet')
          #xml.link('href'=>'page-template.xpgt', 'type'=>'application/vnd.adobe-page-template+xml', 'rel'=>'stylesheet')
        }
        xml.body{
          xml.text '本电子书用于测试，请勿用于任何商业用途，请在下载24小时候删除，如果你喜欢请购买正版'
        }
      }
    end
    
    File.open("#{book_path}/OEBPS/copyright.xhtml", 'w') { |file|
      file.puts builder.to_xml
    }
  end
  
  
  def create_cover_xhtml_file
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset(
      'html',
      "-//W3C//DTD XHTML 1.1//EN",
      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
      )
      xml.html('xmlns'=>'http://www.w3.org/1999/xhtml', 'xml:lang'=>'zh-CN'){
        xml.head{
          xml.title 'copyright'
          xml.link('href'=>'stylesheet.css', 'type'=>'text/css', 'rel'=>'stylesheet')
          #xml.link('href'=>'page-template.xpgt', 'type'=>'application/xhtml+xml', 'rel'=>'stylesheet')
        }
        xml.body{
          xml.p('class'=>'center'){
            xml.img('src'=>'images/cover.jpg')
          }
        }
      }
    end
    
    File.open("#{book_path}/OEBPS/cover.xhtml", 'w') { |file|
      file.puts builder.to_xml
    }
  end
  
  
  def create_chapter_xhtml_files
    @chapters.each { |chapter|
      create_chapter_xhtml_file chapter
    }
  end
  
  
  def create_chapter_xhtml_file chapter
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset(
      'html',
      "-//W3C//DTD XHTML 1.1//EN",
      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
      )
      xml.html('xmlns'=>'http://www.w3.org/1999/xhtml', 'xml:lang'=>'zh-CN'){
        xml.head{
          xml.title 'copyright'
          xml.link('href'=>'stylesheet.css', 'type'=>'text/css', 'rel'=>'stylesheet')
          #xml.link('href'=>'page-template.xpgt', 'type'=>'application/vnd.adobe-page-template+xml', 'rel'=>'stylesheet')
        }
        xml.body{
          xml.h3 "#{chapter.chapter_title}"
          xml.text "#{chapter.chapter_content}"
        }
      }
    end
    
    File.open("#{book_path}/OEBPS/#{chapter.chapter_xhtml_file_name}", 'w') { |file|
      file.puts builder.to_xml.gsub(/&lt;/, '<').gsub(/&gt;/, '>')
    }
  end
  
  
  def package_epub_file
    Zipper.zip(@book_path, "#{@book_name}.epub", true)
  end
  
end



def test1
  
  epub = Text2EPUB.new 'aaa', 'bbb', 'http://vipbook.sinaedge.com/bookcover/pics/70/cover_7b9ba8d3ce67128e14ce4dc606fbd09f.jpg'
  epub.add_chapter '第一章', '第一章'
  epub.add_chapter '第二章', '第二章'
  epub.write_to_file '.'
  
end






