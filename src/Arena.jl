module Arena
using Base.Checked

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
    first::Ptr{TypedArenaChunk{T}}
end

mutable struct TypedArenaChunk{T}
    next::Ptr{TypedArenaChunk{T}}
    capacity::UInt64
end

function calculate_size(capacity::UInt64, T)
    size = sizeof(TypedArenaChunk{T})
    elem_size = sizeof(T)
    elems_size = checked_mul(capacity, elem_size)
    size = checked_add(elems_size, size)
end
end
