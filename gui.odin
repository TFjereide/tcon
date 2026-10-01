package tcon


BorderStyle :: enum{
    Thin,
    Fat
}


GUIElement :: struct{
    parent: int, // Refers to element to inherit position from
    active:bool,
    rect : IRect,
    fg_col, bg_col: byte,
    data : union{
        GuiPanel,
        GuiLabel
    }
}

GuiPanel :: struct{

}

GuiLabel :: struct{
    text:string,
}
