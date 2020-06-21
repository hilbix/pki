# PKI

Simple Shell PKI tool

> Note that Ubuntu has a `pki` command in `pki-tools` package.
> However if you run this `pki` (as noted in it's `man` page)
> it just fails with some cryptic error.  Hence I think it is
> defunct and re-use the name for something completely different,
> which just works.


## Usage

	git clone https://github.com/hilbix/pki.git
	cd pki
	make install

This installs a softlink into `$HOME/bin/pki`.
To install into `/usr/local/bin/pki` use:

	sudo make install

Then:

	pki

Nothing more to remember, nothing more to read.  Just `pki`.


## FAQ

WTF why?

- Because I do not grok OpenSSL

License?

- Free as free beer, free speech, free baby

Contact?  Question?

- Issue on GitHub.  Eventually I listen.

Contrib?  Bugfix?

- PR on GH.  Eventually I listen.

