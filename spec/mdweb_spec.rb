require 'spec_helper'

RSpec.describe 'Mdweb tests' do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end


	it 'requires http auth' do
		get '/'
		expect(last_response.status).to eq(401)

		authorize 'wrong', 'credentials'
		get '/'
		expect(last_response.status).to eq(401)

		authorize 'test', 'test'
		get '/'
		expect(last_response.status).to eq(200)
		expect(last_response.body).to have('markdown-web')
	end



	context 'directory listing' do
		context 'root dir' do
			it 'does not have a rmdir button' do
			end

			it 'cannot be removed (even if empty)' do
			end
		end


		context 'non-root dir' do
			it 'has a rmdir button' do
			end

			it 'cannot be removed if there are still files' do
			end

			it 'can be removed if it is empty' do
			end
		end


		contet 'all dirs' do
			it 'list all files' do
			end

			it 'list all directories' do
			end

			it 'has a crumb' do
			end

			it 'allows creating a subdir' do
			end

			it 'allows creating a new page' do
			end
		end
	end


	context 'markdown file' do
		it 'shows the file' do
		end

		it 'has syntax highlights' do
		end

		it 'can be edited' do
		end

		it 'can be created' do
		end

		it 'has a log' do
		end

		it 'can be renamed' do
		end
	end


	context 'vcs' do
		context 'hg' do
		end


		context 'git' do
		end


		context 'dummy' do
		end
	end
end
