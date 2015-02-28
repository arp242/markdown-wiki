#!/usr/bin/env ruby
# encoding: utf-8
#
# http://code.arp242.net/markdown-web
#
# Copyright © 2014-2015 Martin Tournoij <martin@arp242.net>
# See below for full copyright
#

require 'bundler/setup'
require 'gettext'
require 'kramdown'
require 'sinatra'
require 'rack/csrf'

require 'better_errors' # TODO: dev only
configure :development do
	use BetterErrors::Middleware
	BetterErrors.application_root = __dir__
end

require './helpers.rb'
require './vcs.rb'
require './config.rb'

users = read_users
use Rack::Auth::Basic, _('Restricted Area')  do |u, p|
	begin
		BCrypt::Password.new(users[u]) == p if defined? users[u]
	rescue BCrypt::Errors::InvalidHash
		false
	end
end
use Rack::Session::Cookie, secret: SESSION_SECRET
use Rack::Csrf, raise: true


before '/*' do
	@uri = "#{params[:splat].join '/'}"
	@path = "#{PATH_DATA}/#{@uri}"
	@title = path_or_uri_to_title @uri

	session[:previous] = @uri

	if !VCS.on_system?
		flash "The selected VCS ‘#{VCS.name}’ is not found; mdwiki will work, but \
		will *not* keep a history. If you don’t want to use a VCS & want this \
		warning to disapear, then set VCS to ‘Dummy.new’ in config.rb", :error
	end
end


# Show special page
get(/\/special:/i) do
	file = File.basename(@path).sub(/special:/i, '').to_sym

	if file == :recent
		recent = VCS.log PATH_DATA, 50
		erb file, locals: { path: @path, uri: @uri, title: @title, recent: recent }
	else
		erb file, locals: { path: @path, uri: @uri, title: @title }
	end
end

# Redirect 'page.' to 'page.markdown' (allows for easier linking)
get(%r{/.*@$}) { redirect "#{@uri[0..-2]}.markdown" }

# Show markdown page
get %r{/.*\.(markdown|md)$} do
	markdown = html = ''
	writable = true

	if File.exist? @path
		markdown = File.open(@path, 'r').read
		hash = hash_page markdown

		# TODO: Make this an option
		markdown = markdown.gsub(/\t/, ' ' * 4)
		html = Kramdown::Document.new(markdown, KRAMDOWN_OPTIONS.merge(input: MARKDOWN_FLAVOUR)).to_html
	end

	new_content = nil
	if session[:new_content]
		new_content = session[:new_content]
		session[:new_content] = nil
	end

	erb :page, locals: { path: @path, uri: @uri, title: @title, writable: writable,
		markdown: markdown, html: html, hash: hash, new_content: new_content }
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
			flash _('Page name is empty'), :error
			redirect previous_page
		end

		if params['new-name'].end_with? '/'
			params['new-name'] = "#{params['new-name']}/#{File.basename @path}"
		end

		new_path, new_url = user_input_to_path params['new-name'], File.dirname(@path)
		if File.exist? "#{new_path}"
			flash _('The page ‘%{new_url}’ already exists.') % {new_url: new_url}, :error
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
		current_hash = hash_page nil, @path
		if current_hash != params[:hash]
			flash _('The page has been edited since you last opened it. Your changes are *not* saved, and displayed at the bottom of the page.'), :error
			# TODO: We probably want to do a diff(1)
			# TODO: Fails if page size >4k
			session[:new_content] = params[:content]
			redirect @uri
			return
		end

		begin
			FileIO::write @path, sanitize_page(params['content'])
		rescue FileIO::Error => exc
			flash "There was a problem writing the page ‘#{path_or_uri_to_title @uri}’: ‘#{exc.message}’", :error
			redirect @uri
		end

		begin
			VCS.commit current_user
			flash _('Page ‘%{title}’ saved') % {title: @title}
		rescue FileIO::Error => exc
			flash "Error saving page ‘#{@title}’. Error reported: ‘#{exc}’", :error
		end

		redirect "#{@uri}?r" # We need the ?r or lynx won't redirect; 
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


# Upload
# TODO: Finish this
post '/upload' do
	tmpfile = params[:file][:tempfile]
	name = params[:file][:filename]
	FileIO.copy(tmpfile.path, "#{PATH_DATA}/../public/uploads/#{name}")

	flash _('File ‘%{filename}’ uploaded.') % {filename: name}
	redirect '/Special:upload'
end


# The MIT License (MIT)
#
# Copyright © 2014-2015 Martin Tournoij
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
