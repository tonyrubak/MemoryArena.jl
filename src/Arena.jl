module Arena
using Base.Checked

# An immutable reference cell. Attempting to create a null
# reference will result in an ErrorException.
struct RefCell{T}
    ptr::Ptr{T}
    RefCell{T}(ptr::Ptr{T}) where {T} = ptr == C_NULL ?
        throw(ErrorException("Cannot create a null reference.")) :
        new{T}(ptr)
end 

function Base.getindex(rc::RefCell)
    unsafe_load(rc.ptr)
end

function Base.setindex(rc::RefCell{T}, value::T) where {T}
    unsafe_store!(rc.ptr, value)
end

struct TypedArenaChunk{T}
    next::Union{Nothing, TypedArenaChunk{T}}
    capacity::UInt64
    objects::Ptr{T}

    function TypedArenaChunk{T}(next::Union{Nothing, TypedArenaChunk{T}},
                             capacity::UInt64) where {T}
        size = checked_mul(sizeof(T) * capacity)
        chunk_ptr = Libc.malloc(size)
        objects = convert(Ptr{T}, chunk_ptr)
        new{T}(next, capacity, objects)
    end
end

function start(chunk::TypedArenaChunk)
    chunk.objects
end

function end_ptr(chunk::TypedArenaChunk{T}) where {T}
    size = checked_mul(chunk.capacity, sizeof(T))
    chunk.objects + size
end

function destroy(chunk::TypedArenaChunk)
    Libc.free(chunk.objects)
    if !(chunk.next === nothing)
        destroy(chunk.next)
    end
end

# A memory arena that can only hold one type of object
mutable struct TypedArena{T}
    # Pointer to the next object
    ptr::Ptr{T}
    # Pointer to the current end of the arena
    # Allocation past this point will cause a new
    # chunk of memory to be allocated
    end_ptr::Ptr{T}
    # Reference to the first memory chunk
    # allocated to the arena
    first::TypedArenaChunk{T}
end

TypedArena{T}() where {T} = TypedArena{T}(UInt64(8))

function TypedArena{T}(capacity::UInt64) where {T}
    chunk = TypedArenaChunk{T}(nothing, capacity)
    TypedArena{T}(start(chunk), end_ptr(chunk), chunk)
end

function alloc(arena::TypedArena{T}, object::T) where {T}
    if arena.ptr == arena.end_ptr
        grow(arena)
    end

    objptr = convert(Ptr{T}, arena.ptr)
    unsafe_store!(objptr, object)
    arena.ptr += sizeof(T)
    RefCell{T}(objptr)
end

function grow(arena::TypedArena{T}) where {T}
    old_chunk = arena.first
    capacity = checked_mul(old_chunk.capacity, UInt64(2))
    new_chunk = TypedArenaChunk{T}(old_chunk, capacity)
    arena.ptr = start(new_chunk)
    arena.end_ptr = end_ptr(new_chunk)
    arena.first = new_chunk
end

function destroy(arena::TypedArena)
    destroy(arena.first)
end

# Usage

struct EmptyTree end

struct TreeNode
    left::Union{EmptyTree, RefCell{TreeNode}}
    right::Union{EmptyTree, RefCell{TreeNode}}
end
