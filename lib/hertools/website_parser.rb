# frozen_string_literal: true

require 'base64'
require 'open-uri'
require 'net/http'
require 'httparty'
require 'htmlentities'
require 'nokogiri'

module Hertools
  # Summary: help to get the website info by a url.
  class WebsiteParser
    # Summary: get the title and favicon file by the url of one webpage.
    # Arguments
    # url: the url of a webpage
    # options:
    #   html_parser: %w[httparty nokogiri net_http]
    #   root_path: existing file directory
    def crawl_title_and_favicon_file(url, options = {})
      puts '>>> Parsing the arguments <<<'
      unless parse_url(url)
        puts 'Failed because the bad url!'
        return false
      end
      unless parse_options(options)
        puts 'Failed because the bad options!'
        return false
      end

      puts '>>> Analysing the http response <<<'
      case @html_parser
      when 'nokogiri'
        response = HTTParty.head(@url)
        res = begin
                Nokogiri::HTML(URI.open(url), nil, 'UTF-8')
              rescue StandardError => e
                puts e
                nil
              end
      when 'httparty'
        response = HTTParty.get(@url)
        res = response.body
      else
        response = Net::HTTP.get_response(URI(@url))
        res = response.body.force_encoding("utf-8")
      end
      puts "HttpCode: #{response.code}"

      if res.nil? || res.to_s.empty?
        puts 'No content!'
        @title = @domain_name
        @favicon_url = "#{@index_url}/favicon.ico"
        puts "Use the default favicon url: #{@favicon_url}."
      else
        @title = if nokogiri?
                   res.xpath('//head/title')[0]&.content.to_s
                 else
                   res[%r{<title>\n*(.*)\n*</title>}, 1].to_s
                 end
        if @title.empty?
          puts 'Not found the title!'
          puts 'Use the domain name as the title.'
          @title = @domain_name
        end
        unless nokogiri?
          coder = HTMLEntities.new
          @title = coder.decode(@title)
        end
        puts "Title: #{@title}"

        @favicon_url = if nokogiri?
                         favicon_links = res.xpath('//head/link[@rel="icon"]')
                         favicon_links.empty? ? '' : favicon_links[0][:href].to_s
                       else
                         res[/<link rel="icon".*href="([^"]+)/, 1].to_s
                       end
        if @favicon_url.empty?
          puts 'Not found the favicon url!'
          @favicon_url = "#{@index_url}/favicon.ico"
          puts "Use the default favicon url: #{@favicon_url}."
        else
          puts "FaviconUrl: #{@favicon_url}"
          unless @favicon_url.include?('http')
            if @favicon_url.include?('//')
              @favicon_url = "#{@protocol}:#{@favicon_url}"
              puts "Fixed favicon url: #{@favicon_url}"
            elsif @favicon_url.include?('/')
              @favicon_url = "#{@index_url}#{@favicon_url}"
              puts "Fixed favicon url: #{@favicon_url}"
            else
              @favicon_url = "#{@index_url}/favicon.ico"
              puts "Use the default favicon url: #{@favicon_url}."
            end
          end
        end
      end

      if @title.empty? && @favicon_url.empty?
        puts 'Failed because not found the title and favicon url!'
        return false
      end

      identifier = Digest::MD5.hexdigest(@url)
      file_directory_path = "#{@root_path}/#{@domain_name}_#{identifier}"
      puts "FileDirectory: #{file_directory_path}"
      Dir.mkdir(file_directory_path) unless File.directory?(file_directory_path)
      if File.directory?(file_directory_path)
        unless @title.empty?
          info_file_path = "#{file_directory_path}/website_info.txt"
          puts "InfoFilePath: #{info_file_path}"
          open(info_file_path, 'wb') { |f| f << "Title: #{@title}" }
        end

        unless @favicon_url.empty?
          favicon_file_suffix = @favicon_url.split('.').last
          favicon_file_name = Digest::MD5.hexdigest(@favicon_url) + '.' + favicon_file_suffix
          favicon_file_path = "#{file_directory_path}/#{favicon_file_name}"
          puts "FaviconFilePath: #{favicon_file_path}"
          open(favicon_file_path, 'wb') { |f| f << URI.open(@favicon_url).read }
        end
        puts 'Finished!'
        true
      else
        puts 'Failed to create the directory!'
        false
      end
    rescue StandardError => e
      puts e
      puts 'Failed because the unexpected exception!'
      false
    end

    private

    def parse_url(url)
      @url = String(url)
      puts "Url: #{@url}"
      @url_match = @url.match(%r{(https?)://([^/]+)})
      return false if @url.empty? || @url_match.nil?

      @index_url = @url_match[0]
      puts "IndexUrl: #{@index_url}"
      @protocol = @url_match[1]
      puts "Protocol: #{@protocol}"
      @domain_name = @url_match[2]
      puts "DomainName: #{@domain_name}"
      true
    rescue StandardError => e
      puts e
      false
    end

    def parse_options(options)
      options = Hash(options)
      html_parser = options.fetch(:html_parser) { 'net_http' }
      @old_html_parser = @html_parser
      @html_parser = %w[httparty nokogiri].include?(html_parser) ? html_parser : 'net_http'
      rejudge_nokogiri if @old_html_parser != @html_parser
      puts "HtmlParser: #{@html_parser}"
      root_path = options.fetch(:root_path) { Dir.pwd }
      @root_path = (File.directory?(root_path) ? root_path : Dir.pwd).chomp('/')
      puts "RootPath: #{@root_path}"
      true
    rescue StandardError => e
      puts e
      false
    end

    def nokogiri?
      @judge_nokogiri ||= @html_parser == 'nokogiri'
    end

    def rejudge_nokogiri
      @judge_nokogiri = nil
    end
  end
end
