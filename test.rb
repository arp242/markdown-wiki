#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'

get '/' do
	cache_control 'no_cache'
	"<form method='post'>#{Time.now.to_s}<textarea name='test'></textarea><button>POST</button></form>"
end
post('/') {
	cache_control 'no_cache'
	redirect '/'
}
