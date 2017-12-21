//
//  LGVideoEditModel.h
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class LGVideoEditModel;
typedef void(^CompletionBlock)(LGVideoEditModel *model);
@interface LGVideoEditModel : NSObject
@property (nonatomic) AVURLAsset  *asset;
@property (nonatomic) CMTimeRange timeRange;
+(void)loadResoureWithURL:(NSString *)URL completion:(CompletionBlock)completion;
@end
