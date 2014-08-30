#!/usr/bin/env ruby

require './helpers.rb'
require './vcs.rb'
require './config.rb'


vcs_list = [Hg.new, Git.new].select { |v| v.on_system? }

if vcs_list.length == 0
	puts 'Error: No VCS on the system; you need either Mercurial or Git'
	exit 1
end

vcs_list.each do |v|
	if v.present? PATH_DATA
		puts "#{v.name} repo detected in `#{PATH_DATA}'; stopping"
		exit 0
	end
end

while true
	puts "No repo detected in `#{PATH_DATA}', would you like to initialize it?"
	vcs_list.each_with_index { |v, i| puts "#{i + 1}) Yes, with #{v.name}" }
	puts "#{vcs_list.length + 1}) No, not right now; exit"

	while true
		print "> "
		answer = gets.chomp.to_i

		if answer == 0 || answer > vcs_list.length + 1
			puts 'That is not a valid choice'
			next
		end

		break
	end
	exit 0 if answer == vcs_list.length + 1

	vcs = nil
	vcs_list.each_with_index do |v, i|
		vcs = v if answer == i + 1 || answer == v.name
	end

	break
end

vcs.init
