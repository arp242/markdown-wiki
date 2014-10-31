# TODO: Detect links
class MdwebHtml < Kramdown::Converter::Html
	def convert_codeblock el, indent
		FileUtils.mkdir_p PATH_TMP
		FileUtils.mkdir_p PATH_CACHE

		attr = el.attr.dup
		lang = extract_code_language! attr
		source = el.value

		method = SYNTAX_HIGHLIGHT

		return source if method.nil?

		cache = "#{PATH_CACHE}/code-#{(Digest::SHA2.new.update "#{method} #{lang} #{source}").hexdigest}"
		return File.open(cache, 'r').read() if File.exists? cache
		
		return send "highlight_#{method}", source, cache
	end

	private

		# Do the syntax highlighting with Vim
		# This is a bit strange, but it's the best way to get the same colours
		# as I have in Vim, which I rather like :-)
		def highlight_vim source, cache
			html = ''
			Tempfile.create 'src_', PATH_TMP do |srcfp|
				srcfp.write source
				srcfp.flush

				Tempfile.create 'dst_', PATH_TMP do |dstfp|
					# TODO: escape lang
					pid = Process.spawn({
						'HOME' => PATH_TMP,
						'PATH' => ENV['PATH'],
					}, "vim -u vimrc -c 'syntax on | set t_Co=16 term=xterm-color background=light syntax=ruby \
						| color default | runtime syntax/2html.vim | sleep 5 | w! #{dstfp.path} | qa!' #{srcfp.path}", {
						unsetenv_others: true,
					})
					Process.wait pid

					# Using dstfp.read doesn't seem to work reliably
					html = File.open(dstfp.path, 'r').read()
				end
			end

			id = "vimCodeElement_#{(Random.rand * 100000000000).to_i}"
			style = html.match(/^<style type="text\/css">\n<!--(.*)-->\n^<\/style>$/ms)[1]
			style = style.split("\n")
				.reject { |l| l.strip == '' }
				.map { |l| "##{id} #{l}" }
				.join("\n")

			html = html.match(/^<body>$(.*)^<\/body>$/ms)[1].sub('vimCodeElement', id)
			#html = html.gsub(/\n<\/code><\/pre>/, '</code></pre>')

			# TODO: Check out scoped
			# The scoped attribute is a boolean attribute. If present, it indicates
			# that the styles are intended just for the subtree rooted at the style
			# element's parent element, as opposed to the whole Document.
			#
			# TODO: HTML validator gives error:
			#   Element style is missing required attribute scoped.
			# But this makes no sense? You can't set a bool to False...
			html = "<style>\n#{style}\n</style>\n#{html}"
			File.open(cache, 'w+') { |fp| fp.write html }

			return html
		end
end
