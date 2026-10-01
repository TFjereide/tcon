// sdl pixelbuffer based on:
// https://gist.github.com/superzazu/f24aaf202248440c6097b85105d0bbae
package example

import "base:runtime"
import "core:log"
import "core:fmt"
import rl "vendor:raylib"

import "core:strings"

import tcon ".."


IVec2 :: [2]int

FRAMEBUFFER_WIDTH :: 320*2
FRAMEBUFFER_HEIGHT :: 240*2

WINDOW_WIDTH :: 320*4
WINDOW_HEIGHT :: 240*4

debug_draw_palette :: true
debug_draw_glyphs :: true

main :: proc() {
    
    context.logger = log.create_console_logger()
    @static sdl_log_context : runtime.Context
    
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "example")    


    //  Create render target to write to, this is the frame that will be presented to the screen
    render_target := rl.LoadRenderTexture(FRAMEBUFFER_WIDTH, FRAMEBUFFER_HEIGHT)
    rl.SetTextureFilter(render_target.texture, .POINT)
    defer rl.UnloadRenderTexture(render_target)

    // In memory pixels that will be written to screen at rendertime
    screen_pixels := make([]tcon.Color, FRAMEBUFFER_HEIGHT * FRAMEBUFFER_WIDTH)

    // Make and initialise the console that'll be used to render to the screen
    console := tcon.make_console(
        {(FRAMEBUFFER_WIDTH/10),(FRAMEBUFFER_HEIGHT/10)},
        tcon.load_bitmap_font("assets/bitmapfonts/rexpaint_cp437_10x10.png"),
        tcon.load_palette("assets/palettes/default_palette_01.png"),
    )
    defer tcon.destroy_console(console)
    
    // FPS related
    last_ticks := rl.GetTime()
    fps_list : [30]f32
    fps_idx := 0

    for !rl.WindowShouldClose(){

        free_all(context.temp_allocator)

        new_ticks := rl.GetTime()
		delta_time := f32(new_ticks - last_ticks) / 1000.0

        { // Set FPS in window title
            fps := f32(1000.0 / f32(new_ticks - last_ticks))
            fps_list[fps_idx] = fps
            avg_fps :f32= 0.0
            for num, idx in fps_list{
                avg_fps += num
            }
            fps_idx = (fps_idx+1) % len(fps_list) 
            avg_fps /= len(fps_list)
            last_ticks = new_ticks
            window_string := fmt.aprint("example - fps:",int(avg_fps), allocator = context.temp_allocator)
            window_cstring := strings.clone_to_cstring(window_string, context.temp_allocator)
            
            rl.SetWindowTitle(window_cstring)
        }
                
        //  Start the drawing process on this particular console
        // You issue draw commands that are executed in order.
        tcon.console_draw_start(&console)
        tcon.console_clear()

        // Draw gui_Layer
        window_border_color_fg := tcon.palette_idx(5,4)
        window_border_color_bg := tcon.palette_idx(3,1)
        tcon.console_draw_rect_ex(
                {0,0,console.size.x, console.size.y}, 
                window_border_color_fg, window_border_color_bg,
                .Fat, true    
            )

        if debug_draw_glyphs do tcon.draw_bitmap_font({4,4})
        if debug_draw_palette do tcon.draw_palette({4+20,4})

        
        tcon.console_draw_end()
        tcon.console_draw_present(&console, screen_pixels)

        
        rl.UpdateTexture(render_target.texture, &screen_pixels[0])
        rl.BeginDrawing()
        rl.DrawTexturePro(render_target.texture, {0,0, FRAMEBUFFER_WIDTH,FRAMEBUFFER_HEIGHT},{0,0, WINDOW_WIDTH,WINDOW_HEIGHT}, {0,0},0, {255,255,255,255})
        rl.EndDrawing()

    }
}
