# Confirm for remove page/directory
document.body.addEventListener 'submit', (e) ->
	if e.target.className is 'remove-page'
		c = confirm 'Remove this page?'
		e.preventDefault() if not c
	else if e.target.className is 'remove-dir'
		c = confirm 'Remove this directory?'
		e.preventDefault() if not c


# Show/hide preview
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


# Make the textarea easily resizable
document.addEventListener 'DOMContentLoaded', ->
	textarea = document.getElementsByTagName('textarea')[0]
	return unless textarea?

	drag = false
	handle = document.getElementsByClassName('resize-handle')[0]
	start = 0
	original = textarea.clientHeight
	textarea.style.resize = 'none'

	handle.addEventListener 'mousedown', (e) ->
		e.preventDefault()
		document.body.focus()
		drag = true
		start = e.clientY
		original = textarea.clientHeight

	document.body.addEventListener 'mousemove', (e) ->
		return unless drag
		textarea.style.height = "#{original + e.clientY - start - 13}px"

	document.body.addEventListener 'mouseup', (e) -> drag = false
