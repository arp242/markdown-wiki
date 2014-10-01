#!/usr/bin/env ruby
# encoding: utf-8
#
# http://code.arp242.net/arkdown-web
#
# Copyright © 2014 Martin Tournoij <martin@arp242.net>
# See below for full copyright
#
# TODO: 
# - Detect if a file is changed since we last opened it
# - Warning is hg/git not found on running
# - Some styling could be better
#
# Later versions:
# - Write a bunch of tests
# - Maybe allow execution of code in pages? Would be cool to write code docs
# - rails integration? lib/sidekiq/web.rb does something like that; this way we
#   can document a rails project, and view it with mdweb
# - More fine-grained access control
#

require 'bundler/setup'
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


before %r{/.*\.(markdown|md)$} do
	@uri = "#{params[:splat].join '/'}.markdown"
	@path = "#{PATH_DATA}/#{@uri}"
	@title = path_or_uri_to_title @uri
end

before '/*' do
	@uri = "#{params[:splat].join '/'}"
	@path = "#{PATH_DATA}/#{@uri}"
	@title = path_or_uri_to_title @uri
end


get %r{/.*\.(markdown|md)$} do
	markdown = ''
	html = ''
	if File.exists? @path
		markdown = File.open(@path, 'r').read
		# TODO: We also have html.warnings?
		html = Kramdown::Document.new(markdown, MARKDOWN_OPTIONS.merge({input: MARKDOWN_FLAVOUR})).to_html

		# Remove trailing newline from <pre>
		html = html.gsub(/\n<\/code><\/pre>/, '</code></pre>')

		# TODO: Detect links
	end

	erb :page, locals: { path: @path, uri: @uri, title: @title, markdown: markdown, html: html }
end


get %r{/.*\.(markdown|md)\.log$} do
	@path = @path.sub(/\.log$/, '')
	erb :log, locals: { path: @path, uri: @uri, title: @title, log: VCS.log(@uri.sub(/\.log$/, '')) }
end


post %r{/.*\.(markdown|md)$} do
	if params['mv-page']
		new_path, new_url = user_input_to_path params['new-name'], File.dirname(@path)
		File.rename @path, new_path
		VCS.commit current_user
		flash "Page ‘#{@title}’ moved to ‘#{path_or_uri_to_title new_path}’"
		redirect new_url
	else
		File.open(@path, 'w+') do |fp|
			fp.write params['content'].gsub "\r\n", "\n"
			fp.write "\n" unless params['content'].end_with? "\n"
		end

		VCS.commit current_user
		flash "Page ‘#{@title}’ saved"
		redirect @uri
	end
end


delete %r{/.*\.(markdown|md)$} do
	File.unlink @path

	VCS.commit current_user
	flash "Page ‘#{@title}’ deleted"
	redirect '/'
end


delete '/*' do
	begin
		Dir.rmdir @path
		flash "Directory ‘#{@title}’ removed"
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
	params[:name].strip!
	if params[:name].strip == ''
		flash 'Filename is empty', :error
		# TODO: Don't rely on referrer
		redirect request.env['HTTP_REFERER'] || '/'
	end

	new_path, new_url = user_input_to_path params[:name], "#{PATH_DATA}/#{params[:dir]}", params[:type] == 'dir'

	if params[:type] == 'file'
		if File.exists? "#{new_path}"
			flash 'File already exists; here it is', :error
		else
			FileUtils.touch "#{new_path}"
		end
		redirect new_url
	else
		FileUtils.mkdir_p "#{new_path}"
		redirect new_url
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
