package tcon

import stbi "vendor:stb/image"
import "core:slice"

BitmapFont :: struct{
    pixel_size : IVec2,
    cell_size : IVec2,
    data: []u8 // grayscale values, 0-255
}


// NOTE: Referring to a byte array here for single byte references. Just for ergonomics
// I guess you can't just declare a slice of bytes and shuffle it over to
// a procedure to use it, you must obviously allocate the backing array first.
// So for now, since I'm tired, I'll just do this to avoid constant allocations for single bytes
// FIXME: Super hacky..
ascii := [256]u8{}

load_bitmap_font :: proc(path: cstring) -> BitmapFont{
    for i in 0..<256{
        ascii[i] = byte(i)
    }

    //  Load bitmapfont that will be used with the console
    bitmap_size : [2]i32
    img_pixels := stbi.load(path, &bitmap_size.x, &bitmap_size.y, nil, 1) ; assert(img_pixels != nil)
    defer stbi.image_free(img_pixels)
    
    bytes_in := slice.bytes_from_ptr(img_pixels, int(bitmap_size.x*bitmap_size.y))
    bytes := make([]u8, len(bytes_in))
    copy_slice(bytes, bytes_in)

    return {
        pixel_size = {int(bitmap_size.x), int(bitmap_size.y)},
        cell_size = {int(bitmap_size.x/16),int(bitmap_size.y/16)},
        data = bytes,
    }
}
