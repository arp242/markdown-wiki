#!/usr/bin/env ruby
#
# http://code.arp242.net/markdown-web
#
# Copyright © 2014 Martin Tournoij <martin@arp242.net>
# See below for full copyright


require 'kramdown'
require 'sinatra'

require './vcs.rb'


ROOT = "#{File.realpath(File.dirname($0))}/data"
VCS = Hg.new
auth = File.open('credentials').read().chomp.split ':::'
use(Rack::Auth::Basic, 'Restricted Area') { |u, p| u == auth[0] && p == auth[1] }


def get_listing path
	Dir["#{path}/**/*"].sort.map { |f| [File.directory?(f), File.realpath(f).sub(/^#{ROOT}/, '')] }
end


def path_to_title path
	e(path
		.sub(/^.\/data/, '')
		.sub(/\.markdown$/, '')
		.gsub('_', ' ')
	)
end


def safe_path path
	path = File.realdirpath path
	raise "Permission denied to `#{path}', it's outside of `#{ROOT}'" unless path.start_with? ROOT

	return './data/' + path.sub(/^#{ROOT}/, '')
end


def e str
	Rack::Utils.escape_html str.to_s
end


get '/' do
	erb :listing, locals: { path: './', listing: get_listing('./data') }
end


get '/*.markdown' do
	path = params[:splat].join('/')
	path = safe_path "./data/#{path}.markdown"

	if File.exists? "#{path}"
		markdown = File.open("#{path}", 'r').read
		html = Kramdown::Document.new(markdown).to_html
	else
		markdown = ''
		html = "Page doesn't exist yet"
	end

	erb :view, locals: { path: path, markdown: markdown, html: html }
end


get '/*' do
	path = params[:splat].join '/'

	if path == 'style.css'
		headers 'Content-Type' => 'text/css'
		return File.open('style.css').read()
	end

	if path == 'favicon.ico'
		headers 'Content-Type' => 'image/x-icon'
		return File.open('favicon.ico').read()
	end

	path = safe_path "./data/#{path}"
	return erb :listing, locals: { path: path, listing: get_listing(path) }
end


post '/*.markdown' do
	path = safe_path "./data/#{params[:splat].join '/'}.markdown"

	dir = File.dirname path
	FileUtils.mkdir_p dir unless dir

	File.open(path, 'w+') do |fp|
		fp.write params['content'].gsub "\r\n", "\n"
		fp.write "\n" unless params['content'].end_with? "\n"
	end

	VCS.commit
	redirect path.sub(/^\.\/data\/?/, '')
end


post '/*' do
	if params[:new_file]
		path = safe_path "./data/#{params[:dir]}/#{params[:new_file]}"
		path += '.markdown' unless path.end_with? '.markdown'
		path = safe_path path
		print "================ #{path} =========="
		FileUtils.touch path
		return redirect path.sub(/^\.\/data\/?/, '')
	end

	path = safe_path "./data/#{params[:splat].join '/'}"
	FileUtils.mkdir_p path
	redirect path.sub(/^\.\/data\/?/, '')
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
