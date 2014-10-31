require 'fileutils'

class Vcs
	def commit_message
		Time.now.to_s
	end


	# Is this VCS present on the system?
	#def on_system?; end

	# Human readable name
	#def name; end

	# Check if a repo is present in path
	#def present? path; end

	# Init a new repo
	#def init; end

	# commit a repo with the username user
	#def commit user; end

	# Show logs
	# We expect the return value to be like:
	# [
	#   {
	#     id: Some sort of uniq id for this revision (changeset, commit hash, #     etc.)
	#     diff: text of the diff
	#   },
	#   {
	#     ...
	#   }
	# ]
	#def log path, limit; end
	

	private

		def run cmd
			begin
				`cd #{PATH_DATA} && #{cmd}`
				raise "Error code was non-zero" if $? != 0
			rescue Exception => exc
				# TODO: We want better error handling here
				raise exc
			end
		end
end


class Dummy < Vcs
	def commit_message
		Time.now.to_s
	end

	def on_system?
		true
	end

	def name
		'Dummy VCS'
	end

	def present? path
		true
	end

	def init; end

	def commit user; end

	def log path, limit
		[]
	end
end


class Hg < Vcs
	def on_system?
		`which hg > /dev/null 2>&1`
		return $?.exitstatus == 0
	end


	def name
		'Mercurial'
	end


	def present? path
		File.exists? "#{path}/.hg"
	end


	def init
		FileUtils.mkdir_p PATH_DATA
		run 'hg init'
	end


	def commit user
		run 'hg addremove'
		run "hg ci -m '#{commit_message}' -u '#{user}'"
	end


	def log path, limit=20
		log = run "hg log -pl#{limit} #{path}"

		ret = []
		cur = nil
		log.split("\n").each do |line|
			if line.start_with?('changeset:')
				unless cur.nil?
					cur[:diff].strip!
					ret << cur
				end
				cur = { id: line.split(':')[1..-1].join(':'), diff: '' }
			end

			cur[:diff] += "#{line}\n"
		end

		return ret
	end
end


class Git < Vcs
	def on_system?
		`which git > /dev/null 2>&1`
		return $?.exitstatus == 0
	end


	def name
		'Git'
	end


	def present? path
		File.exists? "#{path}/.git"
	end


	def init
		FileUtils.mkdir_p PATH_DATA
		run 'git init'
	end


	def commit user
		run 'git add -A'
		run "git commit -m '#{commit_message}' --author 'A U #{user} <#{user}@example.com>'"
	end


	def log path, limit=20
		p "git log -p -l#{limit} -- #{path}"
		log = run "git log -p -l#{limit} -- #{path}"

		p log

		ret = []
		cur = nil
		log.split("\n").each do |line|
			if line.start_with?('commit ')
				unless cur.nil?
					cur[:diff].strip!
					ret << cur
				end
				cur = { id: line.split(' ')[1..-1].join(' '), diff: '' }
			end

			cur[:diff] += "#{line}\n"
		end

		return ret
	end
end
