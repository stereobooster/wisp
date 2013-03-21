#!/usr/bin/env python3
# wisp.py --- Whitespace-to-Lisp preprocessor.

# Copyright (C) 2013 Arne Babenhauserheide <arne_bab@web.de>

# Author: Arne Babenhauserheide <arne_bab@web.de>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""whitespace to lisp converter.

Essentially it just adds brackets for indentation to allow writing
lisp with indentation senstitive syntax.

Currently it is written in Python, because I like Python as language,
but crave the power of lisp.
"""


class Line:
    def __init__(self, line):
        #: prefix to go around the outer bracket: '(, ,( or `(
        self.prefix = ""
        # check if this is a continuation of the parent line
        self.continues = line.lstrip().startswith(". ")
        if self.continues:
            self.content = line.lstrip()[2:].lstrip()
        else:
            self.content = line.lstrip()
        # check if the line is prefixed with any combination of ' ` and ,
        if not self.continues:
            while (self.content.startswith("' ") or 
                   self.content.startswith(", ") or
                   self.content.startswith("` ")):
                self.prefix += self.content[0]
                self.content = self.content[2:]
        
        self.indent = len(line) - len(line.lstrip())
        while self.content.startswith(": ") and self.content[2:].lstrip():
            self.indent += len(self.content) - len(self.content[2:].lstrip())
            self.content = self.content[2:].lstrip()

        if self.content.strip() == ":" or self.content.strip() == "":
            self.content = ""

        # split a possible comment
        self.comment = ""
        instring = False
        for n, i in enumerate(self.content):
            if i == '"': 
                instring = not instring
            if not instring and i == ";":
                self.comment = self.content[n+1:]
                self.content = self.content[:n]
                break
        
        # treat inline " : " as opening a bracket which gets closed at the end of the line
        bracketstoclose = 0
        instring = False
        inbrackets = 0
        for n, i in enumerate(self.content):
            if i == '"':
                instring = not instring
            if not instring and i == "(":
                inbrackets += 1
            elif not instring and i == ")":
                inbrackets -= 1
            if not instring and not inbrackets and i == ":" and self.content[n-1:n+2] == " : ":
                bracketstoclose += 1
                self.content = self.content[:n] + "(" + self.content[n+1:]
        self.content += ")" * bracketstoclose

        #: Is the line effectively empty?
        self.empty = False
        onlycomment = (line.split(";")[1:] and  # there is content after the comment sign
                       not line.split(";")[0].count('"') % 2 and # but the first comment sign is not in a string
                       not line.split(";")[0].strip()) # there is no content before the comment sign
        if line.strip() == "" or onlycomment:
            self.empty = True


def nostringbreaks(code):
    """remove linebreaks inside strings (will be readded at the end)"""
    instring = False
    nostringbreaks = []
    for char in code:
        if char == '"':
            instring = not instring
        if instring and char == "\n":
            nostringbreaks.append("\\LINEBREAK")
        else:
            nostringbreaks.append(char)
    return "".join(nostringbreaks)


def nobracketbreaks(code):
    """remove linebreaks inside brackets (will be readded at the end)."""
    inbracket = 0
    nostringbreaks = []
    for char in code:
        if char == '(':
            inbracket += 1
        elif char == ')':
            inbracket -= 1
        if inbracket and char == "\n":
            nostringbreaks.append("\\LINEBREAK")
        else:
            nostringbreaks.append(char)
    return "".join(nostringbreaks)


def wisp2lisp(code):
    """Turn wisp code to lisp code."""
    # first get rid of linebreaks in strings
    code = nostringbreaks(code)
    # and of linebreaks inside brackets
    code = nobracketbreaks(code)
    
    # now read the indentation
    lines = []
    for line in code.splitlines():
        lines.append(Line(line))

    # finally emit matching lisp code
    # write into the lisp lines with a delay of 1 line
    lisplines = []
    # effectively empty lines to be appended
    emptylines = []
    levels = [0]
    prev = lines[0]
    # process the first line in the file
    if not prev.continues:
        prev.content = prev.prefix + "(" + prev.content
    # process further lines: adjust the content of the current line, but only append 
    for line in lines[1:]:
        # ignore empty lines and comment-only lines
        if line.empty:
            # simply keep empty lines and ignore their indentation
            # readd a possible comment
            if line.comment:
                line.content += ";" + line.comment
            # keep the line, do not track it in any way
            emptylines.append(line.indent * " " + line.content)
            continue
        
        # care for leading brackets
        # continuing lines do not get a leading bracket.
        if not line.continues:
            line.content = line.prefix + "(" + line.content
        
        # care for closing brackets
        # rising indent: sibling function or variable
        if line.indent > prev.indent:
            levels.append(line.indent)
            lisplines.append(prev.indent * " " + prev.content)
        # same indent: neighbour function of variable: close the previour lines bracket
        if line.indent == prev.indent:
            if not prev.continues:
                lisplines.append(prev.indent * " " + prev.content + ")")
            else:
                lisplines.append(prev.indent * " " + prev.content)
        # lower indent: parent funtion or variable. Find the number of brackets to close
        if prev.indent > line.indent:
            bracketstoclose = len([level for level in levels if level >= line.indent])
            levels = levels[:-bracketstoclose + 1]
            if prev.continues:
                bracketstoclose -= 1
            lisplines.append(prev.indent * " " + prev.content + ")" * bracketstoclose)

        # add a possible comment
        if prev.comment:
            lisplines[-1] += ";" + prev.comment
        
        prev = line
        lisplines.extend(emptylines)
        emptylines = []
    
    if prev.continues:
        levels.pop()
    lisplines.append(prev.indent * " " + prev.content + ")" * (len(levels)))
    lisplines.extend(emptylines)
    
    # get rid of brackets around empty lines
    for n,i in enumerate(lisplines):
        if i.lstrip() == "()":
            lisplines[n] = ""
    
    return "\n".join(lisplines).replace("\\LINEBREAK", "\n")
            


if __name__ == "__main__":
    import sys
    if sys.argv[1:]:
        sourcefile = sys.argv[1]
    else:
        sourcefile = "example.w"
    with open(sourcefile) as f:
        wisp = f.read()
    print(wisp2lisp(wisp))
