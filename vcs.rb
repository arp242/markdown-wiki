class Vcs
	def commit_message
		Time.now.to_s
	end
end


class Hg < Vcs
	def commit
		`cd data && hg add`
		`cd data && hg ci -m '#{commit_message}'`
	end
end


class Git < Vcs
	def commit
		`git add -A`
		`git commit -m #{commit_message}'`
	end
end
