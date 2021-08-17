

#import <Foundation/Foundation.h>

#import <Flutter/Flutter.h>

typedef void(^FrameUpdateCallback)(void);


@interface GLSLRender : NSObject<FlutterTexture>
- (instancetype)initWithWidth:(int)width Height:(int)height UpdateCallback:(FrameUpdateCallback)callback;


- (void)drawWithPiexBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)releaseGLAbout;

@end

