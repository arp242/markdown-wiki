#!/usr/bin/env ruby

require './helpers.rb'
require './vcs.rb'
require './config.rb'

while true
	while true
		print "Username: "
		user = gets.chomp
		break if user.length > 0
	end

	while true
		print "Password (will not echo): "
		`stty -echo`
		pass = gets.chomp
		`stty echo`
		break if pass.length > 0
	end
	puts ''

	File.open(PATH_USERS, 'a+') { |fp| fp.write "#{user}:::#{hash_password pass}\n" }

	print "Okay, add another user? [y/N] "
	more = gets.chomp
	break unless ['y', 'yes', 'Yes', 'YES'].include? more
end
