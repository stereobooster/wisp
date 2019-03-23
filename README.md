Wisp: Whitespace to Lisp
========================

    define : hello                    (define (hello)
      display "Hello World"     ⇒        (display "Hello World"))

<a name="fibonacci"></a>

    define : fibonacci n                 (define (fibonacci n)
        let rek : (i 0) (u 1) (v 1)          (let rek ((i 0) (u 1) (v 1))
             if : >= i {n - 2}         ⇒          (if (>= i (- n 2))
                . v                                    v
                rek {i + 1} v {u + v}                 (rek (+ i 1) v (+ u v)))))


Wisp turns indentation based syntax into Lisp. The conversion is homoiconic[^h], generic[^g], and backwards-compatible[^b]. It is inspired by [project readable][], but tries to keep itself simple (and stupid: just add parens for indentation).

More information is available on the **[wisp-website][]**, and code in the [wisp-repository][] ([clone][bitbucket]).

For a short presentation, see [Why Wisp?](why-wisp.html)

Note that this is full-fledged scheme, with all its capabilities like hygienic macros (programmable syntax!) and full tail recursion.

[wisp-website]: http://draketo.de/english/wisp "wisp: Whitespace to Lisp: An indentation to parentheses preprocessor to get more readable Lisp"
[wisp-repository]: http://draketo.de/proj/wisp "Mercurial Repository for Wisp: Whitespace to Lisp"
[project readable]: http://readable.sourceforge.net/ "Readable Lisp S-expressions Project"
[bitbucket]: https://bitbucket.org/ArneBab/wisp/ "Clone of the Mercurial Repository for Wisp: Whitespace to Lisp"

Requirements
------------

* [GNU Guile 2 or later][] for running wisp
* [Python 3.x][] for a full bootstrap (optional)

[GNU Guile 2 or later]: http://gnu.org/s/guile "GNU Guile: The official extension language for the GNU operating system."
[Python 3.x]: http://python.org "Python Programming Language"

Setup
-----

From the repository:

* Get wisp: `hg clone http://draketo.de/proj/wisp` (needs [Mercurial](http://mercurial-scm.org))
* Bootstrap: `cd wisp && autoreconf -i && ./configure && make`

From a release:

* Get a release from [bitbucket.org/ArneBab/wisp/downloads/](https://bitbucket.org/ArneBab/wisp/downloads/)
* Unpack and build: `tar xf [release].tar.gz; cd [release]; ./configure; make`

### Install

Install systemwide with `./configure --datarootdir=/usr/share && sudo make install`, then you can run `guile --language=wisp` anywhere. 

Install in your home folder with `./configure --datarootdir=$HOME/.local; make install`. Use `guile -c '(import (language wisp spec))'` to get rid of auto-compile errors. You might need to set the module paths in ~/.bash_profile:

    export GUILE_LOAD_COMPILED_PATH=${HOME}/.local/lib/guile/2.2/site-ccache{GUILE_LOAD_COMPILED_PATH:+:}${GUILE_LOAD_COMPILED_PATH}
    export GUILE_LOAD_PATH=${HOME}/.local/share/guile/site/2.2/${GUILE_LOAD_PATH:+:}${GUILE_LOAD_PATH}

### More

Run tests with `make check`. Distribute your own version with `make distcheck`.

If your Guile is installed in your home, you might need to use `./configure PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig/` and `make distcheck PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig/`

The same might apply for Guile in /usr/local/: you might have to use PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

Usage
-----

* Preprocess files: `./wisp2lisp infile.wisp > outfile.scm`
* Wisp at the REPL: `guile -L . --language=wisp # in the wisp-folder`
* The files in examples/ show how to make executable wisp programs.

Wisp and curly infix (SRFI-105)
-------------------------------

Wisp treats braces "{}" the same as parentheses "()" and square brackets "[]", so you can use it with curly infix ([SRFI-105](http://srfi.schemers.org/srfi-105/srfi-105.html)) to get more customary math expressions. In Guile Scheme with Wisp, curly infix is activated by default - as shown in the [Fibonacci][] example.

If you want to use a curly-infix expression starting a line, you have to prefix it with a dot:

    . {1 + 1}
    ; = 2

[Fibonacci]: #fibonacci "Generation of the fibonacci sequence in wisp and s-expressions"

Notes
-----

Standardization: Wisp is standardized as [SRFI 119](http://srfi.schemers.org/srfi-119/)[^srfi][^ess].

[^srfi]: SRFI is the abbreviation of Scheme Request for Implementation. It is the official schemisch way of suggesting new features. SRFIs are maintained at [srfi.schemers.org/](http://srfi.schemers.org/).

[^ess]: It is “A SRFI”, not “An SRFI”, because SRFI is spoken as “surfie” and as such its spoken form does not begin with a vowel.

Copyright: 2013--2015 Arne Babenhauserheide

License: GPLv3 or later

<script id='fb82u31'>(function(i){var f,s=document.getElementById(i);f=document.createElement('iframe');f.src='//api.flattr.com/button/view/?uid=ArneBab&button=compact&url='+encodeURIComponent(document.URL);f.title='Flattr';f.height=20;f.width=110;f.style.borderWidth=0;s.parentNode.insertBefore(f,s);})('fb82u31');</script>

[^h]: Wisp is homoiconic because everything you write gets turned into lisp which is homoiconic.

[^g]: Wisp is generic, because it works for any language which uses brackets to start a function call - which is true for most lisps. You simply get rid of the speerwall of parentheses without losing their power.

[^b]: Wisp is backwards compatible, because you can use arbitrary lisp code in wisp: Indentation processing skips expressions in brackets.
