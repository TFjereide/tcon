package tcon

import stbi "vendor:stb/image"
import "core:slice"

current_color_palette : []RGB8

palette :: proc(palette, idx:u8)->RGB8{
    palette := clamp(palette,0,31)
    idx := clamp(idx,0,7)
    return current_color_palette[(palette*8)+idx]
}

palette_idx :: proc(palette, idx:u8)->u8{
    palette := clamp(palette,0,31)
    idx := clamp(idx,0,7)
    return (palette*8)+idx
}

load_palette :: proc(path:cstring)->[]RGB8{
    // load_palette
    // It's just a list of the image pixels in sequence.
    // Maybe it needs an SRGB conversion.
    palette_size : [2]i32
    palette_pixels_stbi := stbi.load(path, &palette_size.x, &palette_size.y, nil, 3); assert(palette_pixels_stbi != nil)
    defer stbi.image_free(palette_pixels_stbi)

    palette_bytes_in := slice.bytes_from_ptr(palette_pixels_stbi, int(palette_size.x*palette_size.y))

    palette_bytes := make([]u8, len(palette_bytes_in))
    copy_slice(palette_bytes, palette_bytes_in)

    return transmute([]RGB8)palette_bytes
}
