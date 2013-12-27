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

def replaceinwisp(code, string, replacement):
    """Replace the given string with the replacement, but only in
    indentation sensitive parts of the code.
    
    Essentially replace everywhere except in brackets or strings.
    
    :param code: Arbitrary wisp code to process.
    :param string: A string to replace.
    :param replacement: The replacement string.
    
    :return: (code, count): The new code and a count of replacements.
    """
    count = 0
    instring = False
    incomment = False
    inbrackets = 0
    strlen = len(string)
    for n in range(len(code) - strlen):
        i = code[n]
        # comments start with a ; - but only in regular wisp code or in brackets.
        if not incomment and not instring and i == ";" and not code[n-2:n] == "#\\":
            incomment = not incomment
        # a linebreak ends the comment
        if incomment:
            if i == "\n":
                incomment = not incomment
            # all processing stops in comments
            continue
        # FIXME: This still breaks at "\\"
        if i == '"' and (not code[n-1:n] == "\\" or (code[n-2:n] == "\\\\" and not code[n-3:n] == "\\\\\\")):
            instring = not instring
        # all processing stops in strings
        if instring:
            continue
        if i == "(" and not code[n-2:n] == "#\\":
            inbrackets += 1
        elif i == ")" and not code[n-2:n] == "#\\":
            inbrackets -= 1
        # all processing stops in brackets
        if inbrackets:
            continue
        # here we do the actual replacing
        if code[n:n+strlen] == string:
            count += 1
            code = code[:n] + replacement + code[n+strlen:]
    return code, count


class UndefinedIndentationLevel(IndentationError):
    """Unindent does not match any outer indentation level."""


class Line:
    def __init__(self, line):
        """Parse one line in which linebreaks within strings and
        brackets already got replaced by a temporary placeholder."""
        # Visible indentation: If the line starts with any number of
        # _, followed by a space, treat those _ as spaces.
        if line.startswith("_"):
            for i,letter in enumerate(line):
                if letter != "_":
                    # rewind the index to the last underscore
                    i -= 1
                    break
            # increment the index to the first
            # non-underscore. Required to treat end of string and end
            # of underscores the same
            i += 1
            # here line[i-1] is _. Check if line[i+1] is a space or if
            # the line ends after the last underscore
            if line[i:i+1] == " " or not line[i:]:
                line = (i)*" " + line[i:]
        # \_ escapes the underscore at the beginning of a line, so you
        # can use identifiers which only consist of underscores.
        elif line.startswith("\_"):
            line = "_" + line[2:]
            
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
                   self.content.startswith("` ") or 
                   self.content.startswith("#, ") or # scheme macros
                   self.content.startswith("#` ") or 
                   self.content.startswith("#' ") or 
                   self.content.startswith("#,@, ")):
                self.prefix += self.content.split(" ")[0]
                self.content = self.content[2:]
        
        # care for lines starting with ": " (a colon followed by a space and more chars)
        self.indent = len(line) - len(line.lstrip())
        if self.content.startswith(": ") and self.content[2:].lstrip():
            # just add a space in front of the " : ". Then it will be
            # captured by as inline : later.  With this, the following are almost equal:
            # ": a b" and 
            # ":
            #    a b"
            
            # The only difference between both is that ": a b" cannot
            # have siblings in subsequent lines: The function call
            # ends on this line.
            self.content = " " + self.content

        if self.content.strip() == ":" or self.content.strip() == "":
            self.content = ""

        # split a possible comment
        self.comment = ""
        instring = False
        for n, i in enumerate(self.content):
            if i == '"' and not self.content[n-1:n] == "\\": 
                instring = not instring
            if not instring and i == ";" and not self.content[n-2:n] == "#\\":
                self.comment = self.content[n+1:]
                self.content = self.content[:n]
                break
        
        # treat inline " : " as opening a bracket which gets closed at
        # the end of the line if the : is at the end of the line, add
        # () to avoid being dependent on whitespace at the end of the
        # line.
        bracketstoclose = 0
        instring = False
        inbrackets = 0
        # go backwards through the content to be able to leave out the
        # space after a colon without breaking later colons.
        for n, i in reversed(list(enumerate(self.content))):
            if i == '"' and not self.content[n-1:n] == "\\":
                instring = not instring
            if not instring and i == ")" and not self.content[n-2:n] == "#\\":
                inbrackets += 1
            elif not instring and i == "(" and not self.content[n-2:n] == "#\\":
                inbrackets -= 1
            if (not instring and 
                not inbrackets and 
                i == ":" and # optimization to be able to avoid string
                             # slicing when there can be no hit.
                n # avoid content[-1:2] (which is an unnecessary
                  # slicing, since it is always ""
                ):
                if self.content[n-1:n+2] == " : " or self.content[n-1:] == " :":
                    bracketstoclose += 1
                    # treat ' : as '(
                    if self.content[n-3:n+1] == " ' :":
                        self.content = self.content[:n-2] + "'(" + self.content[n+2:]
                    else:
                        # we have to keep the space after the colon (" : "
                        # → " ( "), otherwise we cannot use two
                        # consecutive colons (" : : ") which would be surprising.
                        self.content = self.content[:n] + "(" + self.content[n+2:]
        
        # after the full line processing, replace " \\: " "\n\\: " and
        # " \\:\n" (inside line, start of a line, end of a line) by "
        # : ", "\n: " and " :\n" respectively to allow escaping : as
        # expression.
        self.content, count = replaceinwisp(self.content, " \\: ", " : ")
        if self.content.startswith("\\: "):
            self.content = ": " + self.content[3:]
        elif self.content.endswith(" \\:"):
            self.content = self.content[:-3] + " :"
        elif self.content == "\\:": # empty function or variable call
            self.content = ":"
        
        # add closing brackets
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
    for n, char in enumerate(code):
        if char == '"' and not code[n-1:n] == "\\":
            instring = not instring
        if instring and char == "\n":
            nostringbreaks.append("\\LINEBREAK")
        else:
            nostringbreaks.append(char)
    return "".join(nostringbreaks)


def nobracketbreaks(code):
    """remove linebreaks inside brackets (will be readded at the end)."""
    instring = False
    incomment = False
    inbracket = 0
    nostringbreaks = []
    for n, char in enumerate(code):
        # comments start with a ; - but only in regular wisp code or in brackets.
        if not incomment and not instring and char == ";" and not code[n-2:n] == "#\\":
            incomment = not incomment
        # a linebreak ends the comment
        if incomment:
            if char == "\n":
                incomment = not incomment
            # all processing stops in comments
            nostringbreaks.append(char)
            continue
        if char == '"' and not code[n-1:n] == "\\":
            instring = not instring
        if char == '(' and not instring and not code[n-2:n] == "#\\":
            inbracket += 1
        elif char == ')' and not instring and not code[n-2:n] == "#\\":
            inbracket -= 1
        if inbracket and char == "\n":
            nostringbreaks.append("\\LINEBREAK")
        else:
            nostringbreaks.append(char)
    return "".join(nostringbreaks)


def processlines(lines, prev, codestartindex, levels, lisplines, emptylines):
    """Process all lines after the first."""
    # process further lines: adjust the content of the current line, but only append 
    for n, line in enumerate(lines[codestartindex+1:]):
        n += codestartindex + 2
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
            if not line.indent in levels[-bracketstoclose:]:
                raise UndefinedIndentationLevel("Unindent of line " + str(n) + " does not match any outer indentation level.\n" + line.indent*" " + "|\n" + line.indent*" " + "v\n" + line.indent*" " + line.content)
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
    
    # postprocessing the loop.
    if prev and prev.continues:
        levels.pop()
    if prev:
        lisplines.append(prev.indent * " " + prev.content + ")" * (len(levels)))
    lisplines.extend(emptylines)
    return prev, lisplines, emptylines, levels


def wisp2lisp(code):
    """Turn wisp code to lisp code."""
    # TODO: extract the shebang before preprocessing the code.

    # if the code is empty, just return an empty string
    if not code:
        return code
    
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
    #: The index of the first code line
    codestartindex = 0
    
    # process the first lines in the file.
    
    # Shebang lines must be used verbatim
    if not prev.indent and prev.content.startswith("#!"):
        codestartindex += 1
        if prev.comment:
            prev.content += ";" + prev.comment
        lisplines.append(prev.content)
        if codestartindex < len(lines):
            prev = lines[codestartindex]
        else:
            prev = None
    
    # initial comment lines need special treatment to avoid starting
    # them with () (implementation detail)
    while prev and prev.empty:
        codestartindex += 1
        if prev.comment:
            prev.content += ";" + prev.comment
        lisplines.append(prev.indent * " " + prev.content)
        if codestartindex < len(lines):
            prev = lines[codestartindex]
        else:
            prev = None
    if prev and not prev.continues:
        prev.content = prev.prefix + "(" + prev.content

    # run the linereader loop. This does the main work - aside from
    # the preprocessing in the Line class.
    if prev:
        prev, lisplines, emptylines, levels = processlines(lines, prev, codestartindex, 
                                                           levels, lisplines, emptylines)
    
    # postprocessing the resulting lisplines: the loop is not perfect…
    # get rid of brackets around empty lines
    for n,i in enumerate(lisplines):
        if i.lstrip() == "()":
            lisplines[n] = ""
    
    return "\n".join(lisplines).replace("\\LINEBREAK", "\n")


if __name__ == "__main__":
    import sys
    import optparse
    parser = optparse.OptionParser("[-o outfile] [file | -]")
    parser.add_option("-o", "--output", default="")
    opts, args = parser.parse_args()
    if args:
        sourcefile = args[0]
    else:
        sourcefile = "example.w"
    # accept stdin as input
    if sourcefile == "-":
        wisp = sys.stdin.read()
    else:
        with open(sourcefile) as f:
            wisp = f.read()
    if opts.output:
        with open(opts.output, "w") as f:
            f.write(wisp2lisp(wisp) + "\n")
    else:
        print(wisp2lisp(wisp))
