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
		valid = valid_username? line[0]	
		unless valid == true
			puts valid
			exit 1
		end

		users[line[0]] = line[1]
	end

	return users
end


def valid_username? user
	# We do this because we add the username to shell commands in vcs.rb
	return 'Usernames are restricted to \w (a-zA-Z0-9_])' unless user.match(/^\w*$/)
	# Be conservative for safety
	return 'Maximum length is 32 characters ' unless user.length < 33
	return true
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
		elsif f.end_with?('.markdown') || f.end_with?('.md')
			files << f.gsub(/\/+/, '/').sub(/^#{PATH_DATA}/, '')
		end
	end
	files.each { |f| dirs[File.dirname(f)] << f }

	# Don't include the current dir if there are no files
	p = path.gsub(/\/+/, '/').sub(/^#{PATH_DATA}/, '')
	dirs = dirs.reject { |k, v| k == p && v.length == 0 }

	return dirs
end


def path_or_uri_to_title path
	'/' + path
		.sub(/^#{PATH_DATA}\/?/, '')
		.sub(/^[.\/]?data\/?/, '')
		.sub(/^\/*/, '')
		.sub(/\.(markdown|md)$/, '')
		.gsub('_', ' ')
end


def user_input_to_path filename, dir, is_dir=false
	unless is_dir
		filename += '.markdown' unless filename.end_with?('.markdown') || filename.end_with?('.md')
	end

	dir = "#{PATH_DATA}/#{dir}" unless dir.start_with? PATH_DATA
	full_path = "#{dir}/#{filename}".gsub(/\s/, '_').gsub(/\/+/, '/')

	return [full_path, path_to_url(full_path)]
end


def path_to_url path
	path.sub(/^#{PATH_DATA}/, '')
end


def e str
	Rack::Utils.escape_html str.to_s
end


def flash m, type=:success
	session[:flash] = [m, type]
end
