use ouroboros::self_referencing;
use rustler::{Env, NifResult, NifStruct, Resource, ResourceArc, Term, Error};
use std::fs;
use std::path::Path;

// 1. Define the Glyph struct for Elixir
#[derive(Debug, NifStruct)]
#[module = "HarfbuzzEx.Shaper.Glyph"]
pub struct Glyph {
    pub name: String,
    pub x_advance: i32,
    pub y_advance: i32,
    pub x_offset: i32,
    pub y_offset: i32,
}

// 2. Define the Self-Referencing Struct
#[self_referencing]
pub struct Shaper {
    font_data: Vec<u8>,

    #[borrows(font_data)]
    #[covariant]
    rb_face: rustybuzz::Face<'this>,

    #[borrows(font_data)]
    #[covariant]
    ttf_face: ttf_parser::Face<'this>,
}

// 3. Define the Resource Wrapper
// We wrap the Shaper in a struct to implement the Resource trait.
pub struct ShaperResource(Shaper);

// Implement the Resource trait (it's empty by default in newer Rustler versions)
impl Resource for ShaperResource {}

// 4. Load Function
fn load(env: Env, _info: Term) -> bool {
    env.register::<ShaperResource>().is_ok()
}

// --- NIF Functions ---

#[rustler::nif]
fn shaper_new(font_path: String) -> NifResult<ResourceArc<ShaperResource>> {
    let data = fs::read(Path::new(&font_path))
        .map_err(|e| Error::Term(Box::new(format!("Failed to read font: {}", e))))?;

    let shaper_inner = ShaperBuilder {
        font_data: data,
        rb_face_builder: |data: &Vec<u8>| {
            rustybuzz::Face::from_slice(data, 0)
                .ok_or("Failed to parse rustybuzz face")
                .unwrap()
        },
        ttf_face_builder: |data: &Vec<u8>| {
            ttf_parser::Face::parse(data, 0)
                .map_err(|_| "Failed to parse ttf face")
                .unwrap()
        },
    }
    .build();

    Ok(ResourceArc::new(ShaperResource(shaper_inner)))
}

#[rustler::nif]
fn shaper_shape(resource: ResourceArc<ShaperResource>, text: String) -> Vec<Glyph> {
    // Dereference the ResourceArc to get ShaperResource, then access the 0th field
    let shaper = &(*resource).0;

    shaper.with(|fields| {
        let rb_face = fields.rb_face;
        let ttf_face = fields.ttf_face;

        let mut buffer = rustybuzz::UnicodeBuffer::new();
        buffer.push_str(&text);
        
        let glyph_buffer = rustybuzz::shape(rb_face, &[], buffer);

        let infos = glyph_buffer.glyph_infos();
        let positions = glyph_buffer.glyph_positions();

        infos
            .iter()
            .zip(positions.iter())
            .map(|(info, pos)| {
                let glyph_id = ttf_parser::GlyphId(info.glyph_id as u16);
                
                // Explicit type annotation added for `s`
                let name = ttf_face
                    .glyph_name(glyph_id)
                    .map(|s: &str| s.to_string()) 
                    .unwrap_or_else(|| format!("gid{}", info.glyph_id));

                Glyph {
                    name,
                    x_advance: pos.x_advance,
                    y_advance: pos.y_advance,
                    x_offset: pos.x_offset,
                    y_offset: pos.y_offset,
                }
            })
            .collect()
    })
}

#[rustler::nif]
fn shaper_destroy(_resource: ResourceArc<ShaperResource>) -> NifResult<String> {
    Ok("ok".to_string())
}

rustler::init!("Elixir.HarfbuzzEx.Native", load = load);
