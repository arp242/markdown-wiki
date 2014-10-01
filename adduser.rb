#!/usr/bin/env ruby

require './helpers.rb'
require './vcs.rb'
require './config.rb'

while true
	while true
		print "Username: "
		user = gets.chomp
		
		valid = valid_username? user

		unless valid == true
			puts valid
			next
		end

		break if user.length > 0
	end

	while true
		print "Password (will not echo): "
		`stty -echo`
		pass = gets.chomp
		`stty echo`

		# TODO: We would like to do a better check for password
		# complexity/quality
		if pass.length < 8
			puts 'Password must be at least 8 characters'
			next
		end

		break
	end
	puts ''

	File.open(PATH_USERS, 'a+') { |fp| fp.write "#{user}:::#{hash_password pass}\n" }

	print "Okay, add another user? [y/N] "
	more = gets.chomp
	break unless ['y', 'yes', 'Yes', 'YES'].include? more
end
