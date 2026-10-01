package tcon

import "core:fmt"
import stbi "vendor:stb/image"
import "core:slice"

RGB8 :: [3]u8
RGBA8 :: [4]u8
ABGR8 :: [4]u8
BGRA8 :: [4]u8


COLOR_MODE_TYPE :: enum{
    RGB8,
    RGBA8,
    ABGR8,
    BGRA8,
}

COLOR_MODE :: COLOR_MODE_TYPE.RGBA8 

when COLOR_MODE == .RGB8{
    Color :: RGB8
}else when COLOR_MODE == .RGBA8{
    Color :: RGBA8
}else when COLOR_MODE == .ABGR8{
    Color :: ABGR8
}else when COLOR_MODE == .BGRA8{
    Color :: BGRA8
}

current_color_palette : []Color

palette :: proc(palette, idx:u8)->Color{
    palette := clamp(palette,0,31)
    idx := clamp(idx,0,7)
    
    return current_color_palette[(palette*8)+idx]
}

palette_idx :: proc(palette, idx:u8)->u8{
    palette := clamp(palette,0,31)
    idx := clamp(idx,0,7)
    return (palette*8)+idx
}

load_palette :: proc(path:cstring)->[]Color{
    // load_palette
    // It's just a list of the image pixels in sequence.
    // Maybe it needs an SRGB conversion.
    palette_size : [2]i32
    color_width :: len(Color)
    palette_pixels_stbi := stbi.load(path, &palette_size.x, &palette_size.y, nil, color_width); assert(palette_pixels_stbi != nil)
    defer stbi.image_free(palette_pixels_stbi)
    
    byte_length := int(palette_size.x*palette_size.y)*color_width
    palette_bytes_in := slice.bytes_from_ptr(palette_pixels_stbi, byte_length)

    palette_bytes := make([]u8, byte_length)
    copy_slice(palette_bytes, palette_bytes_in)
    
    // colors :=  transmute([]Color)palette_bytes
    colors := slice.reinterpret([]Color,palette_bytes)
    fmt.printf("img-size:x:%v y:%v, pixelcount:%v\n", palette_size.x, palette_size.y,palette_size.x*palette_size.y )
    fmt.printf("Colors:%v supposed_length:%v\n", len(colors), byte_length/color_width)
    assert(len(colors) == byte_length/color_width, "Color extraction corruption. colorbuffer not the right byte-length.")

    for &col, _ in colors{
        when COLOR_MODE == .RGB8{
        }else when COLOR_MODE == .RGBA8{
        }else when COLOR_MODE == .ABGR8{
            col.abgr = col.rgba
        }else when COLOR_MODE == .BGRA8{
            col.bgra = col.rgba
        }
    }
    fmt.println("colors loaded")
    return colors
}
