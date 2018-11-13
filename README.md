# MemoryArena
A Julia module that provides a type-safe memory arena based
on the TypedArena in the Rust library.

This allows fast allocation of large numbers of objects of the
same type. The memory arena does not allow deallocation of individual
objects, rather all objects are cleaned up when the memory arena is
manually destroyed.
