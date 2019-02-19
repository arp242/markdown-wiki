TITLE = 'mdwiki: '

# This default should be fine for most people, but for better security put a
# real random string here
secret = Digest::SHA2.new
SESSION_SECRET = secret.update(File.open('users', 'r').read).to_s if File.exists?('users')

# Lower cost value, since we use HTTP auth for now (meaning password
# verification & hash calculation on every request)
BCrypt::Engine.cost = 4

# Where our data is stored
PATH_DATA ||= "#{File.realpath(File.dirname($0))}/data"

# User file
PATH_USERS ||= "#{File.realpath(File.dirname($0))}/users"

# You can use Dummym, which is not a VCS and just stubs stuff out (you won't
# have history).
VCS = [Git.new, Hg.new, Dummy.new].select { |vcs| vcs.present? PATH_DATA }[0]

# Which markdown flavour to use
#
# - :kramdown
#    The Kramdown syntax (Markdown + more).
#
# - :gfm
#    Same as :kramdown, except that newlines are always preserved as-is, and
#    that ``` blocks are recognized.
#
# - :markdown
#    The original markdown syntax.
MARKDOWN_FLAVOUR = :kramdown

# Additional options, see http://kramdown.gettalong.org/documentation.html
KRAMDOWN_OPTIONS = {
	syntax_highlighter: :coderay,
	syntax_highlighter_opts: {
		line_numbers: false,
	}
}

# Minimum password score needed for adduser.rb
MIN_PASSWORD_SCORE = 3
