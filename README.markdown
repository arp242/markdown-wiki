**markdown-web** or **mdweb** is a simple wiki-like system.

Some features:

- Documents are written in markdown.
- All documents are stored on the filesystem, you can edit them through the
  webinterface, or directly on the filesystem.
- Version is tracked with a VCS; currently `hg` and `git` are supported;
- Simple interface.
- It's just ~400 lines of code. Simple. Just works™.

The author of the program uses it to keep track of TODO lists, recipes, personal
documentation/cheatsheets on various things… You can use it for anything,
really.


Installation
------------
- Install dependencies with  [bundler][bundler]: `bundle install`.

- You can optionally configure some settings in `config.rb`.

- You will need to initialize a `user` file and a VCS repository in `data/`;
  running `./install.rb` is the easiest way to initialize a repo; you can add
  users with `./adduser.rb`.

- Start it with: `./mdweb.rb`, or with a port number: `./mdweb.rb -p 4568`.


Markdown flavour
----------------
[See the Kramdown docs](http://kramdown.gettalong.org/syntax.html). You can
configure this in `config.rb` with `MARKDOWN_FLAVOUR`.


Editing documents manually
--------------------------
- Spaces are stored as an underscore (`_`).
- Files must end with `.markdown` or `.md`; all other files are ignored.


Known issues
------------
- The ‘preview’ functionality is imperfect, since Kramdown & the PageDown
  markdown flavours differ.


Changelog
---------
1.0 version is to-be-released.



[kramdown]: http://kramdown.gettalong.org/
[sinatra]: http://www.sinatrarb.com/
[bundler]: http://bundler.io/
