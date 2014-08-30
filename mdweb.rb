#!/usr/bin/env ruby
# encoding: utf-8
#
# http://code.arp242.net/markdown-web
#
# Copyright © 2014 Martin Tournoij <martin@arp242.net>
# See below for full copyright
#
# TODO: 
# - Fix listing indent
# - Detect links
#


require 'kramdown'
require 'sinatra'

require './helpers.rb'
require './vcs.rb'
require './config.rb'


enable :sessions
set :session_secret, SESSION_SECRET

users = read_users
use(Rack::Auth::Basic, 'Restricted Area') do |u, p|
	BCrypt::Password.new(users[u]) == p if defined? users[u]
end


before('/*.markdown') do
	@uri = "#{params[:splat].join '/'}.markdown"
	@path = "#{PATH_DATA}/#{@uri}"
	@title = path_or_uri_to_title @uri
end

before('/*') do
	@uri = "#{params[:splat].join '/'}"
	@path = "#{PATH_DATA}/#{@uri}"
	@title = path_or_uri_to_title @uri
end


get '/*.markdown' do
	markdown = ''
	html = ''
	if File.exists? @path
		markdown = File.open(@path, 'r').read
		html = Kramdown::Document.new(markdown).to_html
		# Remove trailing newline from <pre>
		html = html.gsub(/\n<\/code><\/pre>/, '</code></pre>')

		# TODO: Detect links
	end

	erb :page, locals: { path: @path, uri: @uri, title: @title, markdown: markdown, html: html }
end


get '/*.markdown.log' do
	@path = @path.sub '\.log$', ''
	erb :log, locals: { path: @path, uri: @uri, title: @title, log: VCS.log(@path) }
end


post '/*.markdown' do
	File.open(@path, 'w+') do |fp|
		fp.write params['content'].gsub "\r\n", "\n"
		fp.write "\n" unless params['content'].end_with? "\n"
	end

	VCS.commit current_user
	flash 'File saved'
	redirect @uri
end


delete '/*.markdown' do
	File.unlink @path

	VCS.commit current_user
	flash "Page ‘#{@title}’ deleted"
	redirect '/'
end


delete '/*' do
	begin
		Dir.rmdir @path
		flash "Directoy ‘#{@title}’ removed"
		redirect '/'
	rescue Errno::ENOTEMPTY
		flash "Directory ‘#{@title}’ is not empty", :error
		redirect @uri
	end
end


get '/*' do
	return erb :listing, locals: { path: @path, uri: @uri, title: @title, listing: get_listing(@path) }
end


put '/*' do
	params[:dir].strip!
	params[:name].strip!

	if params[:name] == ''
		flash 'Filename is empty', :error
		# TODO: Don't rely on referrer
		redirect request.env['HTTP_REFERER'] || '/'
	end

	new = "#{params[:dir]}/#{params[:name]}"

	if params[:type] == 'file'
		new += '.markdown' unless new.end_with? '.markdown'

		if File.exists? "./data/#{new}"
			flash 'File already exists; here it is', :error
		else
			FileUtils.touch "./data/#{new}"
		end
		redirect new
	else
		FileUtils.mkdir_p "./data/#{new}"
		redirect new
	end
end


# The MIT License (MIT)
#
# Copyright © 2014 Martin Tournoij
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# The software is provided "as is", without warranty of any kind, express or
# implied, including but not limited to the warranties of merchantability,
# fitness for a particular purpose and noninfringement. In no event shall the
# authors or copyright holders be liable for any claim, damages or other
# liability, whether in an action of contract, tort or otherwise, arising
# from, out of or in connection with the software or the use or other dealings
# in the software.
