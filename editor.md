# Thoughts on the Image 128 text editor:

1. Quoting:

At end-of-bulletin prompt, `"` (Q for "quit reading thread" is taken) to prompt for a range of lines to quote, and import them into the editor buffer

Something like:

End of bulletin. Command? "

`["?" for help, Return when done]`

Range of lines: 1,3,6-9,16-

Range of lines:

Quoting Pinacolada:

> Ray Kelm is a brilliant programmer.
> I strive to understand all the & functions he implemented at some point.
[...]

2. Immutable lines:

There should be a table for an "immutable line" flag, i.e., this line cannot be edited by the text editor.

If a user quotes another user, nothing prevents them from editing the quoted line and commiting libel.

Perhaps more bits for left, center, right justification so that the line can be displayed properly given differences in individual users' terminal widths.

Perhaps something like this:

%1....... = immutable line
%.....1.. = left-justified
%......1. = centered
%.......1 = right-justified

3. Undo/Redo (may be limited)

May have to be an extension of `.E`dit, since `.Y` is Move and `.Z` is Copy.

Something like:

`.E`dit `U`ndo

`.E`dit `R`edo

4. Prompt for confirmation of `.N`ew Text or `.A`bort

5. Visual `Ctrl-I` / `Shift-Del` (insert character) and `Ctrl-D` / `Del` (delete character) feedback

We have the ability to visually show characters being inserted and deleted.
This goes for Ctrl-W (move backward one word) and other such editing control keys.
