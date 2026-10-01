package tcon


BorderSymbol :: struct{
    ver, hor:byte,
    tl,tr,bl,br:byte,
}

WindowStylings :: struct{
    using border_symbols : BorderSymbol,
    fg_col, bg_col : byte,
    empty:bool,
}

@private currcon_default : Console
currcon :^Console


console_draw_title :: proc( rect: IRect, fg_col, bg_col: u8, title:string){
    rect := rect 
    rect.w-=1
    rect.h-=1
    tl := len(title)
    console_draw_string({rect.x+(rect.w/2)-(tl/2),rect.y,tl, 1},fg_col,bg_col,title)
}

console_draw_rect_ex :: proc( rect: IRect, fg_col, bg_col: u8, border_style:= BorderStyle.Fat, empty := false) {
    if border_style == .Fat{
        console_draw_rect(
            rect, 
            {
                ver=186,
                hor=205,
                tl=201,
                tr=187,
                bl=200,
                br=188,
                fg_col = fg_col,
                bg_col = bg_col,
                empty = empty,
            },
        )
    }else if border_style == .Thin{
        console_draw_rect(
        rect, 
        {
            ver=179,
            hor=196,
            tl=218,
            tr=191,
            bl=192,
            br=217,
            fg_col = fg_col,
            bg_col = bg_col,
            empty = empty,
        },
    )    
    }
}


console_draw_hor_line :: proc( rect: IRect, fg_col, bg_col: u8){
    rect := rect
    rect.w-=1
    rect.h-=1
    rsym :u8= 185
    lsym :u8= 204
    for i:= 1; i < rect.w; i+=1{
        console_draw_tile( {205, fg_col, bg_col }, rect.x + i, rect.y) 
    }
    console_draw_tile( {lsym, fg_col, bg_col }, rect.x , rect.y) 
    console_draw_tile( {rsym, fg_col, bg_col }, rect.x + rect.w , rect.y) 

}

console_draw_ver_line :: proc( rect: IRect, fg_col, bg_col: u8){
     rect := rect
    rect.w-=1
    rect.h-=1   
    up_sym :u8= 203
    low_sym :u8= 202
    for i:= 1; i < rect.h; i+=1{
        console_draw_tile( {186, fg_col, bg_col }, rect.x , rect.y + i) 
    }
    console_draw_tile( {up_sym, fg_col, bg_col }, rect.x, rect.y) 
    console_draw_tile( {low_sym, fg_col, bg_col }, rect.x, rect.y + rect.h) 

}


console_draw_rect :: proc( rect: IRect, window_stylings :WindowStylings) {
    rect := rect

    if rect.x >= currcon.size.x do return
    if rect.y >= currcon.size.y do return

    rect.w-=1
    rect.h-=1

    if rect.x+rect.w > currcon.size.x{
        rect.w = currcon.size.x-rect.x-1
    }

    if rect.y+rect.h > currcon.size.y{
        rect.h = currcon.size.y-rect.y-1
    }
 
    if !window_stylings.empty{
        for i:= 0; i < rect.w*rect.h; i+=1{
            console_draw_tile( {0,0,window_stylings.bg_col}, rect.x +(i%rect.w), rect.y+(i/rect.w))
        }
    }

    for i:= 0; i < rect.w; i+=1{
        console_draw_tile( {window_stylings.hor, window_stylings.fg_col, window_stylings.bg_col }, rect.x + i, rect.y) // top
        console_draw_tile( {window_stylings.hor, window_stylings.fg_col, window_stylings.bg_col }, rect.x + i, rect.y + rect.h) // bottom
    }

    for i:= 0; i < rect.h; i+=1{
        console_draw_tile( {window_stylings.ver, window_stylings.fg_col, window_stylings.bg_col }, rect.x, rect.y + i) // left
        console_draw_tile( {window_stylings.ver, window_stylings.fg_col, window_stylings.bg_col }, rect.x + rect.w, rect.y + i) // right
    }
    console_draw_tile( {window_stylings.tl, window_stylings.fg_col, window_stylings.bg_col }, rect.x, rect.y) // tl
    console_draw_tile( {window_stylings.tr, window_stylings.fg_col, window_stylings.bg_col }, rect.x + rect.w, rect.y)// tr
    console_draw_tile( {window_stylings.bl, window_stylings.fg_col, window_stylings.bg_col }, rect.x, rect.y+rect.h)//bl
    console_draw_tile( {window_stylings.br, window_stylings.fg_col, window_stylings.bg_col }, rect.x + rect.w, rect.y+rect.h)//br
}

draw_bitmap_font::proc( pos: IVec2){ // show whole glyph set...

    set_width :: 16
    for i in 0..<256{
        x := pos.x + (i % set_width)
        y := pos.y + (i / 16)
        console_draw_tile({byte(i),3,0},x,y)
    }
} 


draw_palette :: proc( pos: IVec2){
    set_width :: 16
    for i in 0..<256{
        x := pos.x + (i % set_width)
        y := pos.y + (i / 16)
        console_draw_tile({219,byte(i),0},x,y)
    }
}

console_draw_string_string :: proc( rect: IRect, fg_col, bg_col :u8, text: string){
    console_draw_string_bytes(rect,fg_col,bg_col, transmute([]u8)text)
}

console_draw_string_bytes :: proc( rect: IRect, fg_col, bg_col :u8, text: []u8){
    w:=rect.w
    h:=rect.h
    x:=rect.x
    y:=rect.y

    if x > currcon.size.x do return
    if y > currcon.size.y do return

    if x+w > currcon.size.x{
        w = currcon.size.x-x
    }

    if y+h > currcon.size.y{
        h = currcon.size.y-y
    }
    fg_col := fg_col
    if len(text) == 1{
        // fg_col = 2
        console_draw_tile({text[0], fg_col, bg_col}, x, y)
    }else{
        // fg_col = 4
        for i := 0; i < len(text); i+=1{
            _x := i % w
            _y := i / w
            if y + _y >= currcon.size.y do continue
            if x + _x >= currcon.size.x do continue
            console_draw_tile({text[i], fg_col, bg_col}, x +_x, y +_y)
        }
    }
}

console_draw_string :: proc{console_draw_string_bytes, console_draw_string_string}

console_draw_tile :: proc(tile:Tile, x, y: int){
    if x < 0 || x >= currcon.size.x || y < 0 || y >= currcon.size.y do return
    currcon.tiles[x + (y*currcon.size.x)] = tile
}

console_clear :: proc(){
    for i:= 0; i < len(currcon.tiles); i+=1{
        currcon.tiles[i] = {}
    }
}

console_draw_start :: proc( console:^Console){
    currcon = console
}

console_draw_end :: proc(){
    currcon = &currcon_default
}

