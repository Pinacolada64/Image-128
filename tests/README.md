README.md

The compressed disk images (`test.d64.zip` and `test.d64.gz`) both contain the same files.

`wedge 128`: loads `wedge 128.obj` and adds a command character `&` which increments the screen color.

`bank init 0c00`:
* loads `bank init.obj` into `$0c00`
* reserves a common area of RAM from `$0000-1000`
* and raises the start of BASIC to `$2001`.

(`bank init.bas` tries to load code into the cassette buffer, and I think having JiffyDOS on my C128 makes this fail. Also, the assembly code has been relocated to `$0c00`, so it will probably stop with a `?file not found  error`)

The next two files won't work properly without running `bank init 0c00` first.

`string-input.bas` shows how to pass variables between BASIC and ML. It loads `string-input.obj` which uses banking to store string data in bank 1, then sets up the string descriptor to point to the newly created string. It displays the entered string and its length (which could be truncated to the maximum length specified in the `sys` call).
Making the cursor blink with the CIA timer would be nice.

`more input` is a lot like `string-input.bas` but allows more editing keys (shifted & unshifted alphabet, digits and space)

Other curiosities:

`cassbuff table` and `table 2`: calculate offsets from a given address and display them in decimal and hexadecimal.

`if then else`: tinkering with conditions.

`string stuff` is supposed to demonstrate creating integer, floating point and string variables in ML. It might work once the banking call is relocated to `$0c00`.
