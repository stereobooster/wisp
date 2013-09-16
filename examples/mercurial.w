;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Nikita Karetnikov <nikita@karetnikov.org>
;;; Copyright © 2013 Cyril Roelandt <tipecaml@gmail.com>
;;; Copyright © 2013 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

define-module : mercurial
  . #:use-module : (guix licenses) #:select : asl2.0 gpl1+ gpl2+ gpl3+
  . #:use-module : guix packages
  . #:use-module : guix download
  . #:use-module : guix build-system gnu
  . #:use-module : guix build-system python
  . #:use-module : guix build utils
  . #:use-module : gnu packages libapr
  . #:use-module : gnu packages python
  . #:use-module : gnu packages system
  . #:use-module : gnu packages emacs
  . #:use-module : gnu packages compression

define-public hg
  package
    name "mercurial"
    version "2.7.1"
    source
      origin
        method url-fetch
        uri
          string-append "http://mercurial.selenic.com/release/mercurial-" 
              . version ".tar.gz"
        sha256
          base32
            . "121m8f7vmipmdg00cnzdz2rjkgydh28mwfirqkrbs5fv089vywl4"
    build-system python-build-system
    home-page "http://mercurial.selenic.com"
    synopsis "Decentralized version control system"
    description
      . "Mercurial is a free, distributed source control management tool. 
It efficiently handles projects of any size 
and offers an easy and intuitive interface."
    license gpl2+
