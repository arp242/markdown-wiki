require 'bcrypt'


def hash_password pw
	BCrypt::Password.create pw
end


def read_users
	unless File.exists? 'users'
		puts 'Error: file ./users not found; you need to create this file and add least one user'
		puts 'The format is:'
		puts 'username:::password'
		puts ''
		puts 'install.rb can also create users for you'
		exit(1)
	end

	users = {}
	File.open('users', 'r').readlines.each do |line|
		line = line.chomp.split ':::'
		unless line[0].match(/^\w*$/)
			puts 'Usernames are restricted to \w (a-zA-Z0-9_])'
			exit(1)
		end

		unless line[1].length >= 4
			puts 'Passwords must be at least 4 characters'
			exit(1)
		end
		users[line[0]] = line[1]
	end

	return users
end


def current_user
	request.env['REMOTE_USER']
end


def get_listing full_path
	Dir["#{full_path}/**/*"].sort
		.map { |f| [File.directory?(f), File.realpath(f).sub(/^#{PATH_DATA}/, '')] }
		.select { |f| f[0] || f[1].end_with?('.markdown') }
end


def path_or_uri_to_title path
	path
		.sub(/^[.\/]?data\/?/, '')
		.sub(/^#{PATH_DATA}\/?/, '')
		.sub(/\.markdown$/, '')
		.gsub('_', ' ')
end


def e str
	Rack::Utils.escape_html str.to_s
end


def flash m, type=:success
	session[:flash] = [m, type]
end
