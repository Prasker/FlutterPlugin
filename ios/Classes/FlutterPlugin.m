#import "FlutterPlugin.h"
#import "GLSLRender.h"
#import "TaskModel.h"

@interface FlutterPlugin ()

@property(strong, nonatomic) NSObject<FlutterPluginRegistrar> *registrar;
@property (nonatomic, strong) TaskModel *model;

@end



@implementation FlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_plugin"
            binaryMessenger:[registrar messenger]];
  FlutterPlugin* instance = [[FlutterPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];

    self.registrar = registrar;
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getTextureId" isEqualToString:call.method]) {
      [self getCutTextureIDWithMethodCall:call result:result];
  }else if ([@"stop" isEqualToString:call.method]){
      [self stopWithMethodCall:call result:result];
  }else {
    result(FlutterMethodNotImplemented);
  }
}


- (void)stopWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (self.model) {
        dispatch_source_cancel(self.model.timer);
        [self.model.render releaseGLAbout];
        [self.registrar.textures unregisterTexture:self.model.textureId];
        self.model.render = nil;
        self.model.timer = nil;
        self.model = nil;
    }
}


- (void)getCutTextureIDWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
//    NSDictionary* argsMap = call.arguments;
    self.model = [TaskModel new];
    __block int64_t textureId = 0;
    __weak __typeof(self)weakSelf = self;
    self.model.render = [[GLSLRender alloc] initWithWidth:1000 Height: 1000 UpdateCallback:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSLog(@"---------------drawPiex--------------");
        [strongSelf.registrar.textures textureFrameAvailable:textureId];
    }];
    textureId = [_registrar.textures registerTexture:self.model.render];
    result(@(textureId));
    NSLog(@"----------id-------%lld",textureId);
    self.model.textureId = textureId;
   
    NSTimeInterval period = 0.08;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.model.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.model.timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.model.timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.model.render drawWithPiexBuffer:nil];
        });
    });
    dispatch_resume(self.model.timer);

}




@end
