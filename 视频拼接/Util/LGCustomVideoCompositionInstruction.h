//
//  LGCustomVideoCompositionInstruction.h
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface LGCustomVideoCompositionInstruction :  NSObject <AVVideoCompositionInstruction>
@property CMPersistentTrackID foregroundTrackID;
@property CMPersistentTrackID backgroundTrackID;

- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange;
- (id)initTransitionWithSourceTrackIDs:(NSArray*)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange;
@end
