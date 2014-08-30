Really simple document system.

- Documents are written in markdown (markdown parser used is
  [kramdown][kramdown])
- All documents are stored on the filesystem, you can edit them through the
  webinterface, or directly on the filesystem.
- Version is tracked with a VCS; curently `hg` and `git` are supported.
- It's just ~400 lines of code. Simple. Just works™

The author of the program uses it to keep track of TODO lists, recipes, personal
documentation/cheatsheets on various things... You can use it for anything,
really.


Installation
------------
- Install dependencies with  [bundler][bundler]:

      bundle install

- You can optionally configure some settings on `config.rb`

- You will need to initialize a `user` file and a VCS repository in `data/`;
  running `./install.rb` is the easiest way to initialize a repo; you can add
  users with `./adduser.rb`

- Start it:

     ./mdweb.rb

  Or with a port number:

	 ./mdweb.rb -p 4568


Markdown flavour
----------------
[See the Kramdown docs](http://kramdown.gettalong.org/syntax.html).


Changelog
---------
1.0 version it to-be-released.



[kramdown]: http://kramdown.gettalong.org/
[sinatra]: http://www.sinatrarb.com/
[bundler]: http://bundler.io/
