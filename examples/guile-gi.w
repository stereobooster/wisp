#!/usr/bin/env bash
# -*- wisp -*-
# REQUIREMENTS:
# - Guile-GI
# - libffi
# - GLib
# - GObject-Introspection aka GIRepository
# set Guile if unset
if [ -z ${GUILE+x} ]; then
	GUILE=guile
fi
# temporary workaround to find libguile-gi
export GUILE_SYSTEM_EXTENSIONS_PATH="$HOME/.guix-profile/lib/guile/3.0/"
"${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" "${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples guile-gi)' -c '' "$@"
; !#

define-module : examples guile-gi
   . #:export : main

import (gi) (gi repository)

require "Gio" "2.0"
require "Gtk" "3.0"

load-by-name "Gio" "Application" ;; activate, run
load-by-name "Gtk" "Application"
load-by-name "Gtk" "ApplicationWindow"
load-by-name "Gtk" "Button"
load-by-name "Gtk" "ButtonBox"
load-by-name "Gtk" "Widget" ;; show-all

define : print-hello widget
  display "Hello World\n"

define : activate-callback app
  let*
      : window (make <GtkApplicationWindow>
                #:application app
                #:default-height 200
                #:default-width 200
                #:title "Window")
        button-box (make <GtkButtonBox> #:parent window)
        button (make <GtkButton>
                   #:parent button-box
                   #:label "Hello world")
    connect button clicked print-hello
    connect button clicked : lambda _ : destroy window
    show-all window

define : main
  let : : app (make <GtkApplication> #:application-id "org.gtk.example")
    connect app activate activate-callback
    run app : command-line

main
