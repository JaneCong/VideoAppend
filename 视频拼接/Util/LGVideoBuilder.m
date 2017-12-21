//
//  LGVideoBuilder.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGVideoBuilder.h"
#import "LGCustomVideoCompositionInstruction.h"
#import "LGCustomVideoCompositor.h"
@interface LGVideoBuilder()
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@end
@implementation LGVideoBuilder
+ (instancetype)sharedBuilder {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

-(void)buildVideoWithModels:(NSArray<LGVideoEditModel *> *)models
{
    LGVideoEditModel *firstModel  = models.firstObject;
    LGVideoEditModel *secondModel = models.lastObject;
    
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.videoComposition.customVideoCompositorClass = [LGCustomVideoCompositor class];
    
    AVAssetTrack *track0 = [[firstModel.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *track1 = [[secondModel.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVMutableCompositionTrack *firstTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [firstTrack insertTimeRange:track0.timeRange ofTrack:track0 atTime:kCMTimeZero error:nil];
    [firstTrack insertTimeRange:track1.timeRange ofTrack:track1 atTime:track0.timeRange.duration error:nil];
    
    LGCustomVideoCompositionInstruction *videoInstruction = [[LGCustomVideoCompositionInstruction alloc] initTransitionWithSourceTrackIDs:@[[NSNumber numberWithInt:firstTrack.trackID], [NSNumber numberWithInt:firstTrack.trackID]] forTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(track0.timeRange.duration, track1.timeRange.duration))];
    videoInstruction.foregroundTrackID = firstTrack.trackID;
    
    self.videoComposition.renderSize = track0.naturalSize;
    self.videoComposition.frameDuration = CMTimeMake(1, 15);
    self.videoComposition.instructions = @[videoInstruction];
}

-(AVPlayerItem *)buildPlayerItem
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
    playerItem.videoComposition = self.videoComposition;
    return playerItem;
    
}

@end
