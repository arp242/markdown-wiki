#!/usr/bin/env ruby

require 'bundler/setup'
require 'gettext'
require 'zxcvbn'

require './helpers.rb'
require './vcs.rb'
require './config.rb'

while true
	while true
		print _('Username') + ': '
		user = gets.chomp
		
		valid = valid_username? user

		unless valid == true
			puts valid
			next
		end

		break if user.length > 0
	end

	while true
		print "#{_('Password')} (#{_('will not echo')}): "
		`stty -echo`
		pass = gets.chomp
		`stty echo`

		score = Zxcvbn.test(pass, [user]).score
		if score < MIN_PASSWORD_SCORE
			puts ''
			puts _('Password is not strong enough (score is %{score}, and should be at least %{MIN_PASSWORD_SCORE}') % {
				score: score, MIN_PASSWORD_SCORE: MIN_PASSWORD_SCORE }
			next
		end

		break
	end
	puts ''

	File.open(PATH_USERS, 'a+') { |fp| fp.write "#{user}:::#{hash_password pass}\n" }

	print _('Okay, add another user?') + ' [y/N] ' # TODO: localize yes/no
	more = gets.chomp
	break unless ['y', 'yes', 'Yes', 'YES'].include? more
end
