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
			# We do this because we add the username to shell commands in vcs.rb
			puts 'Usernames are restricted to \w (a-zA-Z0-9_])'
			exit(1)
		end
		users[line[0]] = line[1]
	end

	return users
end


def current_user
	request.env['REMOTE_USER']
end

# [
#     [dir1, [file1, file2]],
#     [dir2, [file1, file2]],
# ]
def get_listing path
	dirs = {path.gsub(/\/+/, '/').sub(/^#{PATH_DATA}/, '') => []}
	files = []
	Dir["#{path}/**/*"].sort.each do |f|
		if File.directory?(f)
			f = f.gsub(/\/+/, '/').sub(/^#{PATH_DATA}/, '')
			dirs[f] = []
		else
			files << f.gsub(/\/+/, '/').sub(/^#{PATH_DATA}/, '')
		end
	end
	files.each { |f| dirs[File.dirname(f)] << f }
	return dirs
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
