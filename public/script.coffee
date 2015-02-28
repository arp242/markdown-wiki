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
