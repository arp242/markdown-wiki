ENV['RACK_ENV'] = 'test'

require 'tmpdir'

PATH_DATA = Dir.mktmpdir

require './mdwiki'
require 'rspec'
require 'rack/test'

RSpec.configure do |config|
	config.include Rack::Test::Methods
	config.warnings = false #true
	config.order = :random
	Kernel.srand config.seed
end
