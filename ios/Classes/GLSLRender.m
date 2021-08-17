

#import "GLSLRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGLDrawable.h>

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface GLSLRender ()
@property (nonatomic, assign) SenceVertex *vertices;

@property (nonatomic, assign) int tag;   //Use this to imitate the different textures of the video

@end


@implementation GLSLRender{
    FrameUpdateCallback _callback;
    EAGLContext *_context;
    CGSize _size;
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _texture;
    CVPixelBufferRef _target;
    GLuint _frameBuffer;
    GLuint _program;
    GLuint _positionSlot;
    GLuint _textureSlot;  // 
    GLuint _textureCoordsSlot;
    GLuint _vertexBuffer;
    
    GLuint _textureID;
    
}


- (void)releaseGLAbout {
    [EAGLContext setCurrentContext:_context];
    glBindTexture(GL_TEXTURE_2D, 0);

    glDeleteBuffers(1, &_vertexBuffer);
    _vertexBuffer = 0;

    free(self.vertices);
    self.vertices = nil;

    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;

    glDeleteProgram(_program);
    NSLog(@"---------------------_textureCacheCount%ld",(long)CFGetRetainCount(_textureCache));
    NSLog(@"---------------------_textureCount%ld",(long)CFGetRetainCount(_texture));
    CFRelease(_textureCache);
    CFRelease(_texture);

    CFRelease(_target);
//    int targetCount = (int)CFGetRetainCount(_target);
//    for (int i = 0; i < targetCount; i++) {
//        NSLog(@"---------------------targetCount%ld",(long)CFGetRetainCount(_target));
//        CFRelease(_target);
//    }

}

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_target);
    return _target;
}











- (instancetype)initWithWidth:(int)width Height:(int)height UpdateCallback:(FrameUpdateCallback)callback;{
    if (self = [super init]) {
        _callback = callback;
        _size = CGSizeMake(width, height);
        self.tag = 0;
        [self initShareMemoryAboutTexture];
    }
    return self;
}


- (void)initShareMemoryAboutTexture{
   
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_context];
    [self createCVBufferWith:&_target withOutTexture:&_texture];

    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture), 0);

    glViewport(0, 0, _size.width, _size.height);

    self.vertices = malloc(sizeof(SenceVertex) * 4); //
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 0}}; // leftTop
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 1}}; // leftBottom
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 0}}; // rightTop
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 1}}; // rightBottom

    _program = [self programWithShaderName:@"glsl"]; // glsl.vsh & glsl.fsh
    _positionSlot = glGetAttribLocation(_program, "Position");
    _textureSlot = glGetUniformLocation(_program, "Texture");
    _textureCoordsSlot = glGetAttribLocation(_program, "TextureCoords");

    glUseProgram(_program);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));

    glEnableVertexAttribArray(_textureCoordsSlot);
    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));

    
}


- (void)createCVBufferWith:(CVPixelBufferRef *)target withOutTexture:(CVOpenGLESTextureRef *)texture {
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
    if (err) {
        return;
    }
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferCreate(kCFAllocatorDefault, _size.width, _size.height, kCVPixelFormatType_32BGRA, attrs, target);
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, *target, NULL, GL_TEXTURE_2D, GL_RGBA, _size.width, _size.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, texture);

    CFRelease(empty);
    CFRelease(attrs);
}






- (void)drawWithPiexBuffer:(CVPixelBufferRef)pixelBuffer {
    
    //In this  demo, use a picture instead of the video texture
    [EAGLContext setCurrentContext:_context];
    NSString *imagePath;
    if (self.tag == 0) {
        imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample.png"];
        self.tag = 1;
    }else {
        imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample2.png"];
        self.tag = 0;
    }
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    GLuint textureID = [self createTextureWithImage:image];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glUniform1i(_textureSlot, 0);  // textureSlot
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFlush();
    _callback();
   
    
}



- (GLuint)createTextureWithImage:(UIImage *)image {
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
   
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData); // 将图片数据写入纹理缓存
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    CGContextRelease(context);
    free(imageData);
   
    
    return _textureID;
}








- (GLuint)programWithShaderName:(NSString *)shaderName {
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    // link program
    glLinkProgram(program);
    
    // check success
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program link failed：%@", messageString);
        exit(1);
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    return program;
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
  
    NSString *shaderString;
    if (shaderType == GL_VERTEX_SHADER) {
        shaderString = @"attribute vec4 Position;attribute vec2 TextureCoords;varying vec2 TextureCoordsVarying;void main (void) {gl_Position = Position;TextureCoordsVarying = TextureCoords;}";
    }else {
        shaderString = @"precision mediump float;uniform sampler2D Texture;varying vec2 TextureCoordsVarying;void main (void) {vec4 mask = texture2D(Texture, TextureCoordsVarying);gl_FragColor = vec4(mask.rgb, 1.0);}";
    }
    
    GLuint shader = glCreateShader(shaderType);
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shader);
    
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader Compilation failed：%@", messageString);
        exit(1);
    }
    
    return shader;
}

- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return backingWidth;
}

- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return backingHeight;
}


@end
