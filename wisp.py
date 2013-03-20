#!/usr/bin/env python3

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
                self.prefix.append(self.content[0])
                self.content = self.content[2:]
        
        self.indent = len(line) - len(line.lstrip())
        while self.content.startswith(": ") and self.content[2:].lstrip():
            self.indent += len(self.content) - len(self.content[2:].lstrip())
            self.content = self.content[2:].lstrip()
        if self.content.strip() == ":" or self.content.strip() == "":
            self.content = ""


def nostringbreaks(code):
    """remove linebreaks inside strings"""
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


def wisp2lisp(code):
    """Turn wisp code to lisp code."""
    # first get rid of linebreaks in strings
    code = nostringbreaks(code)
    
    # now read the indentation
    lines = []
    for line in code.splitlines():
        lines.append(Line(line))

    # finally emit matching lisp code
    # write into the lisp lines with a delay of 1 line
    lisplines = []
    levels = []
    prev = lines[0]
    # process the first line in the file
    if not prev.continues:
        prev.content = prev.prefix + "(" + prev.content
    # process further lines
    for line in lines[1:]:
        
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
            lisplines.append(prev.indent * " " + prev.content + ")")
        # lower indent: parent funtion or variable. Find the number of brackets to close
        if prev.indent > line.indent:
            bracketstoclose = len([level for level in levels if level >= line.indent])
            levels = levels[:-bracketstoclose + 1]
            if prev.continues:
                bracketstoclose -= 1
            lisplines.append(prev.indent * " " + prev.content + ")" * bracketstoclose)
        
        prev = line
    
    lisplines.append(prev.indent * " " + prev.content + ")" * (len(levels)))
    
    return "\n".join(lisplines).replace("\\LINEBREAK", "\n")
            


if __name__ == "__main__":
    print()
    import sys
    if sys.argv[1:]:
        sourcefile = sys.argv[1]
    else:
        sourcefile = "example.w"
    with open(sourcefile) as f:
        wisp = f.read()
    print(wisp2lisp(wisp))
