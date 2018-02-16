module klaodg.buffer;

import imf = imageformats;
import klaodg.vector;
import std.stdio : writeln, writefln;

interface OutBuffer {
  size_t RWidth ( );
  size_t RHeight ( );
  void Apply ( int2 p, float4 RGBA );
}

class PNGFile : OutBuffer {
  size_t width, height;
  ubyte[] data;

  this ( int _width, int _height ) {
    width = _width;
    height = _height ;
    data.length = width*height*4;
  }

  override size_t RWidth ( ) { return width; }
  override size_t RHeight ( ) { return height; }

  override void Apply ( int2 p, float4 RGBA ) {
    import std.algorithm, std.array;
    if ( RGBA.w == 0.0f ) return;
    if ( p.x < 0 || p.x >= width || p.y < 0 || p.y >= height ) return;
    p.y = cast(int)height - p.y-1;
    ubyte[4] pdata = RGBA.v[].map!(n => cast(ubyte)(n*255)).array;
    size_t pos = width*p.y*4 + p.x*4;
    data[pos .. pos + 4] = pdata;
  }

  void Save ( string filename ) {
    try {
      imf.write_image(filename, width, height, data, imf.ColFmt.RGBA);
    } catch ( Exception e ) {
      writefln("Error saving image: %s (%s, %s)", filename, width, height);
    }
  }
}

import derelict.opengl;
class GLBuffer : OutBuffer {
  size_t width, height;
  float[] img;
  uint gl_texture;

  this ( size_t _width, size_t _height ) {
    width  = _width;
    height = _height;
    img.length = width*height*4;
    Allocate_Texture(gl_texture, width, height);
    Clear();
  }
  override size_t RWidth  ( ) { return width; }
  override size_t RHeight ( ) { return height; }

  void Clear ( float4 RGBA = float4(0.0f, 0.5f, 0.0f, 1.0f) ) {
    foreach ( i; 0 .. width )
    foreach ( j; 0 .. height )
      Apply(int2(cast(int)i, cast(int)j), RGBA);
  }

  override void Apply ( int2 p, float4 RGBA ) {
    if ( !(p.x >= 0 && p.y >= 0 && p.x < width && p.y < height) ) return;
    size_t pos = width*p.y*4 + p.x*4;
    img[pos .. pos + 4] = RGBA.v[];
  }

  private void Allocate_Texture ( ref uint gl_texture,
                                  size_t width, size_t height ) {
    glGenTextures(1, &gl_texture);
    glBindTexture(GL_TEXTURE_2D, gl_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast(int)width, cast(int)height,
                                0, GL_RGBA, GL_FLOAT, null);
    glBindTexture(GL_TEXTURE_2D, 0);
  }
  void Update ( ) {
    glBindTexture(GL_TEXTURE_2D, gl_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast(int)RWidth, cast(int)RHeight,
                 0, GL_RGBA, GL_FLOAT, cast(void*)img.ptr);
    glBindTexture(GL_TEXTURE_2D, 0);
  }
  void Render ( bool update = true ) {
    if ( update ) Update();
    import klaodg.glrender : Render;
    Render(gl_texture);
  }
}
