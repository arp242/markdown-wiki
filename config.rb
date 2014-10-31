# This default should be fine for most people
secret = Digest::SHA2.new
SESSION_SECRET = secret.update(File.open('users', 'r').read).to_s if File.exists?('users')

# Lower cost value, since we use HTTP auth for now (meaning password
# verification & hash calculation on every request)
BCrypt::Engine.cost = 4

# Where our data is stored
PATH_DATA = "#{File.realpath(File.dirname($0))}/data"

# User file
PATH_USERS = "#{File.realpath(File.dirname($0))}/users"

# Temp files
PATH_TMP = "#{File.realpath(File.dirname($0))}/tmp"

# Cache files
PATH_CACHE = "#{PATH_TMP}/cache"

# Hg.new or Git.new
# You can use Dummy.new to disable history
VCS = [Hg.new, Git.new].select { |vcs| vcs.present? PATH_DATA }[0] || Hg.new

# Which markdown flavour to use
#
# - :kramdown - The Kramdown syntax (Markdown + more).
# - :gfm - Same as :kramdown, except that newlines are always preserved as-is,
#         and that ``` blocks are recognized.
# - :markdown - The original markdown syntax
MARKDOWN_FLAVOUR = :kramdown

# Additional options, see http://kramdown.gettalong.org/documentation.html
MARKDOWN_OPTIONS = {}
