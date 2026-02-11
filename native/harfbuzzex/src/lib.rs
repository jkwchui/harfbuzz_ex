use rustler::NifStruct;
use rustybuzz::{Face, UnicodeBuffer, Direction};
use std::fs;

#[derive(NifStruct)]
#[module = "HarfbuzzEx.Glyph"]
pub struct Glyph {
    pub name: String,
    pub x_advance: i32,
    pub y_advance: i32,
    pub x_offset: i32,
    pub y_offset: i32,
}

#[rustler::nif]
fn shape(text: String, font_path: String) -> Vec<Glyph> {
    // 1. Load the font data
    let font_data = fs::read(font_path).expect("Could not read font file");
    
    // 2. Initialize the Shaper (Rustybuzz)
    let face = Face::from_slice(&font_data, 0).expect("Invalid font data");
    
    // 3. Prepare Buffer
    let mut buffer = UnicodeBuffer::new();
    buffer.push_str(&text);
    buffer.set_direction(Direction::LeftToRight);
    
    // 4. Shape!
    // rustybuzz::shape returns a GlyphBuffer containing the results
    let glyph_buffer = rustybuzz::shape(&face, &[], buffer);

    let positions = glyph_buffer.glyph_positions();
    let infos = glyph_buffer.glyph_infos();

    // 5. Initialize Parser for Names
    // Rustybuzz focuses on shaping. To get names, we use ttf-parser directly on the same data.
    let parser_face = ttf_parser::Face::parse(&font_data, 0).unwrap();

    infos.iter().zip(positions.iter()).map(|(info, pos)| {
        // Look up the name. If not found, fall back to "gid123"
        let name = parser_face.glyph_name(ttf_parser::GlyphId(info.glyph_id as u16))
            .map(|n| n.to_string())
            .unwrap_or_else(|| format!("gid{}", info.glyph_id));

        Glyph {
            name,
            x_advance: pos.x_advance,
            y_advance: pos.y_advance,
            x_offset: pos.x_offset,
            y_offset: pos.y_offset,
        }
    }).collect()
}

rustler::init!("Elixir.HarfbuzzEx");
