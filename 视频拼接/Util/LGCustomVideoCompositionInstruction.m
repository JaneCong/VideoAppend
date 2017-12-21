//
//  LGCustomVideoCompositionInstruction.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGCustomVideoCompositionInstruction.h"

@implementation LGCustomVideoCompositionInstruction
@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        _passthroughTrackID = passthroughTrackID;
        _requiredSourceTrackIDs = nil;
        _timeRange = timeRange;
        _containsTweening = FALSE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}

- (id)initTransitionWithSourceTrackIDs:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        _requiredSourceTrackIDs = sourceTrackIDs;
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _timeRange = timeRange;
        _containsTweening = TRUE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}
@end
