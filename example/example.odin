// sdl pixelbuffer based on:
// https://gist.github.com/superzazu/f24aaf202248440c6097b85105d0bbae
package example

import "core:mem"
import "base:runtime"
import "core:log"
import sdl "vendor:sdl3"
import stbi "vendor:stb/image"
import "core:slice"
import "core:fmt"

import "core:strings"
import "core:math/rand"

import tcon ".."


IVec2 :: [2]int
RGB8 :: [3]u8



LIMIT_FPS :: false


FRAMEBUFFER_WIDTH :: 320*2
FRAMEBUFFER_HEIGHT :: 240*2

WINDOW_WIDTH :: 320*4
WINDOW_HEIGHT :: 240*4

// NOTE: Mirrors sdl enum for this. I don't actually think that 0 index is needed though, but whatever for now.
MouseButtons :: enum {
    _       = 0,
    Left    = 1,
    Middle  = 2,
    Right   = 3,
    X1      = 4,
    X2      = 5,
    Count,
}

key_down : #sparse[sdl.Scancode]bool
key_released : #sparse[sdl.Scancode]bool
mouse_just_down : [MouseButtons]bool
mouse_down : [MouseButtons]bool
mouse_released : [MouseButtons]bool
mouse_pos : [2]f32
mouse_pos_local : IVec2

debug_draw_palette :: true
debug_draw_glyphs :: true


sdl_log :: proc "c" (userdata: rawptr, category: sdl.LogCategory, priority: sdl.LogPriority, message: cstring){
    context = (transmute(^runtime.Context)userdata)^
    level : log.Level
    switch priority{
        case .INVALID, .TRACE, . VERBOSE, .DEBUG : level = .Debug
        case .INFO: level = .Info
        case .WARN: level = .Warning
        case .ERROR: level = .Error
        case .CRITICAL: level = .Fatal
    }
    log.logf(level,"SDL {} : {}", category,  message)
}

sdl_assert :: proc(ok:bool){
    if !ok do log.panicf("SDL Error: {}", sdl.GetError())
}

main :: proc() {
    
    context.logger = log.create_console_logger()
    @static sdl_log_context : runtime.Context
    sdl_log_context = context
    sdl_log_context.logger.options -= {.Short_File_Path, .Line, .Procedure}
    sdl.SetLogPriorities(.VERBOSE)
    sdl.SetLogOutputFunction(sdl_log, &sdl_log_context)

    ok := sdl.Init({.VIDEO}); sdl_assert(ok)

    // create SDL window, renderer
    window := 
        sdl.CreateWindow(
            "Simulator - Terminal Emulator", 
            WINDOW_WIDTH, 
            WINDOW_HEIGHT,
            {}
    ); sdl_assert(window != nil)
    

    renderer := sdl.CreateRenderer(window, nil); sdl_assert(renderer != nil)

    //  Create render target to write to, this is the "framebuffer" that will be presented to the screen
    render_target := sdl.CreateTexture(renderer, .RGB24, .STREAMING, FRAMEBUFFER_WIDTH, FRAMEBUFFER_HEIGHT); sdl_assert(render_target != nil)
    sdl.SetTextureScaleMode(render_target, .NEAREST)
    defer sdl.DestroyTexture(render_target)

    // In memory pixels that will be written to screen at rendertime
    screen_pixels := make([]RGB8, FRAMEBUFFER_HEIGHT * FRAMEBUFFER_WIDTH)

    console := tcon.make_console(
        {(FRAMEBUFFER_WIDTH/10),(FRAMEBUFFER_HEIGHT/10)},
        tcon.load_bitmap_font("assets/bitmapfonts/rexpaint_cp437_10x10.png"),
        tcon.load_palette("assets/palettes/default_palette_01.png"),
    )
    defer tcon.destroy_console(console)
    
    // persistent data
    // FPS related
    
    last_ticks := sdl.GetTicks()
    fps_list : [30]f32
    fps_idx := 0

    main_loop: for{

        free_all(context.temp_allocator)

        new_ticks := sdl.GetTicks()
		delta_time := f32(new_ticks - last_ticks) / 1000.0

        when LIMIT_FPS{
            if delta_time < (1.0/60.0){
                continue
            }
        }

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
            window_string := fmt.aprint("Simulator - fps:",int(avg_fps), allocator = context.temp_allocator)
            window_cstring := strings.clone_to_cstring(window_string, context.temp_allocator)
            
            sdl.SetWindowTitle(window, window_cstring)
        }
        
        for i in MouseButtons{    
            mouse_released[i] = false
        }
        for i in sdl.Scancode{    
            key_released[i] = false
        }

        ev: sdl.Event
        for sdl.PollEvent(&ev){
            #partial switch ev.type{
                case .QUIT:
                    break main_loop
                case .KEY_DOWN:
                    if ev.key.scancode == .ESCAPE do break main_loop
                    key_down[ev.key.scancode] = true
                    
                case .KEY_UP:
                    key_down[ev.key.scancode] = false
                    key_released[ev.key.scancode] = true

                case .MOUSE_BUTTON_DOWN:
                    if !mouse_just_down[MouseButtons(ev.button.button)] && !mouse_down[MouseButtons(ev.button.button)] {
                        mouse_just_down[MouseButtons(ev.button.button)] = true
                    }
                    else{
                        mouse_just_down[MouseButtons(ev.button.button)] = false
                    }
                    mouse_down[MouseButtons(ev.button.button)] = true

                case .MOUSE_BUTTON_UP:
                    mouse_down[MouseButtons(ev.button.button)] = false
                    mouse_released[MouseButtons(ev.button.button)] = true
                    mouse_just_down[MouseButtons(ev.button.button)] = false
            }   
        }
        {
            mouse_flags := sdl.GetMouseState(&mouse_pos.x, &mouse_pos.y)

            mouse_pos_local = IVec2{
                int(mouse_pos.x / f32(WINDOW_WIDTH) * f32(console.size.x)),
                int(mouse_pos.y / f32(WINDOW_HEIGHT)* f32(console.size.y)),
            }
        }

        move_vec := IVec2{}
        if key_released[.UP] do move_vec.y -= 1
        if key_released[.DOWN] do move_vec.y += 1
        if key_released[.LEFT] do move_vec.x -= 1
        if key_released[.RIGHT] do move_vec.x += 1

        
        // ---------------------
        //  Draw GUI To Console
        // ---------------------

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


        // render on screen
        sdl.RenderClear(renderer)
        sdl_assert(sdl.UpdateTexture(render_target, nil,&screen_pixels[0], render_target.w * size_of(RGB8)))
        sdl.RenderTexture(renderer, render_target, nil, nil)
        sdl.RenderPresent(renderer)

    }
}
