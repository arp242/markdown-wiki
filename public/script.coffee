document.body.addEventListener 'submit', (e) ->
	if e.target.className is 'remove-page'
		c = confirm 'Remove this page?'
		e.preventDefault() if not c
	else if e.target.className is 'remove-dir'
		c = confirm 'Remove this directory?'
		e.preventDefault() if not c


document.body.addEventListener 'click', (e) ->
	if e.target.id is 'show-preview'
		e.preventDefault()

		preview = document.getElementById 'wmd-preview'
		if preview.offsetWidth is 0
			preview.style.display = 'block'
			document.getElementById('page').style.display = 'none'
			e.target.innerHTML = 'Disable preview'
		else
			preview.style.display = 'none'
			document.getElementById('page').style.display = 'block'
			e.target.innerHTML = 'Enable preview'
	else if e.target.id is 'mv-page'
		e.preventDefault()
		document.getElementsByClassName('mv-page')[0].style.display = 'inline-block'


document.addEventListener 'DOMContentLoaded', ->
	textarea = document.getElementsByTagName('textarea')[0]
	return unless textarea?

	drag = false
	handle = document.getElementsByClassName('resize-handle')[0]
	start = 0
	original = textarea.clientHeight
	textarea.style.resize = 'none'

	handle.addEventListener 'mousedown', (e) ->
		drag = true
		start = e.clientY
		original = textarea.clientHeight
		document.body.focus()
		e.preventDefault()

	document.body.addEventListener 'mousemove', (e) ->
		return unless drag
		textarea.style.height = "#{original + e.clientY - start - 13}px"

	document.body.addEventListener 'mouseup', (e) -> drag = false


# Chrome (& Webkit?) doesn't support Auth over WebSockets... :-/
# https://code.google.com/p/chromium/issues/detail?id=123862
document.addEventListener 'DOMContentLoaded', ->
	req = null
	timer = null
	poll = ->
		return if req?
		loc = window.location.href
		if loc.substr(-9) isnt '.markdown' and loc.substr(-3) isnt '.md'
			clearInterval timer
			return

		#req = jQuery.ajax
		#	url: loc
		#	success: (data) ->
		#		alert data
		#	done: -> req = null

	timer = setInterval poll, 3000
