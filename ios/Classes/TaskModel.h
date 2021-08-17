
#import <Foundation/Foundation.h>
#import "GLSLRender.h"

@interface TaskModel : NSObject
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) GLSLRender *render;
@property (nonatomic, assign) long textureId;
@end


