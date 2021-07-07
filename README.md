Nimnes
------

This is a little project for me since I got fascinated by
the 6502 processor lately, so I thought why not get my feet 
wet and emulate it so that I can write some assembly and test
it out...

One of the few systems that I used to use in my time that is based
on the 6502 is the NES, so I thought why not, it's also a well documented
system, with loads of nice help, this is the first time I'm playing 
with writing an emulator for anything, so starting with something
that is well documented should be a good first step

I've been using [this tutorial for a rust nes emulator](https://bugzmanov.github.io/nes_ebook/chapter_1.html) to base my
thing on, and it has been very helpful, I'll try to add other sources that I've been using as well.

[Easy6502](https://skilldrick.github.io/easy6502/) has really been a great resource
since I haven't written an assembler yet, and stepping through running programs,
and using it to make test programs has been really helpful.

[6502 Reference](http://www.obelisk.me.uk/6502/reference.html) has also been really helpful to
understand what the different opcodes and assembler words actually do.

I'm not sure if I'll finish this, but I have a lot of fun working on it so it might be that
it's something I'll be playing with for a while, for now at least all the standard 6502 
opcodes are implemented, I also intend to write a disassembler, an assembler and to write
in rom loading, so that we can use some test cartridges and then implement the NES specific
opcodes as well.

I'm not that fond of graphics programming and stuff like that, but I may be able to use something
like SDL and create the PPU as well, I really hope that I'll get that far :)
