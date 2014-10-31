#!/usr/bin/env ruby
# encoding: utf-8
#
# http://code.arp242.net/markdown-web
#
# Copyright © 2014 Martin Tournoij <martin@arp242.net>
# See below for full copyright
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


before '/*' do
	@uri = "#{params[:splat].join '/'}"
	@path = "#{PATH_DATA}/#{@uri}"
	@title = path_or_uri_to_title @uri
	session[:previous] = @uri

	if !VCS.on_system?
		flash "The selected VCS ‘#{VCS.name}’ is not found; mdweb will work, but \
		will *not* keep a history. If you don’t want to use a VCS & want this \
		warning to disapear, then set VCS to ‘Dummy.new’ in config.rb", :error
	end
end


# Show markdown page
get %r{/.*\.(markdown|md)$} do
	markdown = html = ''
	if File.exist? @path
		markdown = File.open(@path, 'r').read
		html = Kramdown::Document.new(markdown, MARKDOWN_OPTIONS.merge({input: MARKDOWN_FLAVOUR})).to_html
	end

	erb :page, locals: { path: @path, uri: @uri, title: @title, markdown: markdown, html: html }
end


# Show logs
get %r{/.*\.(markdown|md)\.log$} do
	@path = @path.sub(/\.log$/, '')
	erb :log, locals: { path: @path, uri: @uri, title: @title, log: VCS.log(@uri.sub(/\.log$/, '')) }
end


# Create, edit, or move markdown page
post %r{/.*\.(markdown|md)$} do
	# Move page
	if params['mv-page']
		if params['new-name'].strip == ''
			flash 'Page name is empty', :error
			redirect previous_page
		end

		new_path, new_url = user_input_to_path params['new-name'], File.dirname(@path)
		if File.exist? "#{new_path}"
			flash "The page ‘#{new_url}’ already exists.", :error
			redirect previous_page
		end

		begin
			FileIO::rename @path, new_path
		rescue FileIO::Error => exc
			flash "There was a problem renaming the page to ‘#{path_or_uri_to_title new_url}’: ‘#{exc}’", :error
			redirect @uri
		end
		VCS.commit current_user
		flash "Page ‘#{@title}’ moved to ‘#{path_or_uri_to_title new_path}’"
		redirect new_url
	# Edit or create page
	else
		begin
			FileIO::write @path, sanitize_page(params['content'])
		rescue FileIO::Error => exc
			flash "There was a problem writing the page ‘#{path_or_uri_to_title @uri}’: ‘#{exc.message}’", :error
			redirect @uri
		end

		VCS.commit current_user
		flash "Page ‘#{@title}’ saved"
		redirect @uri
	end
end


# Delete markdown page
delete %r{/.*\.(markdown|md)$} do
	begin
		FileIO::unlink @path
	rescue FileIO::Error => exc
		flash "There was a problem deleting the page ‘#{path_or_uri_to_title @uri}’: ‘#{exc.message}’", :error
		redirect @uri
	end

	VCS.commit current_user
	flash "Page ‘#{@title}’ deleted"
	redirect '/'
end


# Delete a directory
delete '/*' do
	begin
		FileIO::rmdir @path
	rescue FileIO::Error => exc
		flash "There was a problem deleting the directory ‘#{path_or_uri_to_title @uri}’: ‘#{exc.message}’", :error
		redirect @uri
	end

	flash "Directory ‘#{@title}’ removed"
	redirect '/'
end


# Get a directory listing
get '/*' do
	return erb :listing, locals: { path: @path, uri: @uri, title: @title, listing: get_listing(@path) }
end


# Make a new file or directory
put '/*' do
	params[:name].strip!
	if params[:name].strip == ''
		flash 'Page name is empty', :error
		redirect previous_page
	end

	new_path, new_url = user_input_to_path params[:name], "#{PATH_DATA}/#{params[:dir]}", params[:type] == 'dir'

	# New file
	if params[:type] == 'file'
		if File.exist? "#{new_path}"
			flash 'Page already exists; here it is', :error
		else
			begin
				FileIO.touch new_path
			rescue FileIO::Error => exc
				flash "There was a problem writing to the page ‘#{path_or_uri_to_title new_path}’: ‘#{exc.message}’", :error
			end
		end
		redirect new_url
	# New dir
	else
		begin
			FileIO.mkdir new_path
		rescue FileIO::Error => exc
			flash "There was a problem creating the directory ‘#{path_or_uri_to_title new_path}’: ‘#{exc.message}’", :error
		end
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
