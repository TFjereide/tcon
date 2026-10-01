package tcon

Tile :: struct{
    symbol: u8,
    fg_color, bg_color: u8,
}

Console :: struct{
    size : IVec2,
    tiles : []Tile,
    font : BitmapFont,
    color_palette: []RGB8
}


make_console :: proc(size : IVec2, font : BitmapFont, color_palette: []RGB8) -> Console{
    return {
        size = size,
        tiles = make([]Tile, size.x*size.y),
        font = font,
        color_palette = color_palette,
    }
}


// Render to screentexture
console_draw_present:: proc( console:^Console, buffer : []RGB8){
    num_tiles := [2]int{console.font.pixel_size.x / console.font.cell_size.x, console.font.pixel_size.y / console.font.cell_size.y}
    pixel_coord :[2]int
    tile_coord :[2]int
    tile_uv :[2]int

    buffer_width := console.size.x *console.font.cell_size.x
    buffer_height := console.size.y *console.font.cell_size.y

    for i :=0; i< len(buffer); i+=1{
        // Remap to x and y within screenspace
        pixel_coord.x = i % buffer_width
        pixel_coord.y = i / buffer_width
        // Remap within console space
        tile_coord = pixel_coord / console.font.cell_size
        // What tile would this pixel be in, to get info from?
        tile_idx := tile_coord.x+(tile_coord.y*console.size.x)
        tile := console.tiles[tile_idx]
        
        // What pixels of the bitmap tile should we get?
        tile_uv = pixel_coord % console.font.cell_size


        //  What tile offset of the bitmap should we get?
        tile_x := int(i32(tile.symbol) % i32(num_tiles.x))
        tile_y := int(i32(tile.symbol) / i32(num_tiles.y))
        
        tile_uv.x += tile_x*console.font.cell_size.x
        tile_uv.y += tile_y*console.font.cell_size.y
        
        bitmap_value := console.font.data[tile_uv.x + (tile_uv.y * int(console.font.pixel_size.x))]
        pixel_col := console.color_palette[tile.fg_color] if bitmap_value > 0 else console.color_palette[tile.bg_color]
        buffer[i] = pixel_col
    }
}

destroy_console :: proc(console:Console){
    delete(console.tiles)
    delete(console.font.data)
}


