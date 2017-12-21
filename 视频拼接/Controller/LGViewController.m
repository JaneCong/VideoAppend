//
//  LGViewController.m
//  视频拼接
//
//  Created by L了个G on 2017/12/21.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGViewController.h"
#import "LGPlayerView.h"
#import "LGVideoBuilder.h"
@interface LGViewController ()
@property (weak, nonatomic) IBOutlet LGPlayerView *playerView1;
@property (weak, nonatomic) IBOutlet LGPlayerView *playerView2;
@property (weak, nonatomic) IBOutlet LGPlayerView *playerView3;
@end

@implementation LGViewController

- (IBAction)playAction:(id)sender {
    
    __block NSMutableArray *array = [NSMutableArray array];
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    dispatch_group_enter(dispatchGroup);
    [LGVideoEditModel loadResoureWithURL:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp4"] completion:^(LGVideoEditModel *model) {
        
        [array addObject:model];
        dispatch_group_leave(dispatchGroup);
    }];
    dispatch_group_enter(dispatchGroup);
    [LGVideoEditModel loadResoureWithURL:[[NSBundle mainBundle] pathForResource:@"2" ofType:@"mp4"] completion:^(LGVideoEditModel *model) {
        
        [array addObject:model];
        dispatch_group_leave(dispatchGroup);
    }];
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
        [[LGVideoBuilder sharedBuilder] buildVideoWithModels:array];
        [self preparePlayBackWithPreview:self.playerView3 PlayerItem:[[LGVideoBuilder sharedBuilder] buildPlayerItem]];
    });
    
    
    [self preparePlayBackWithPreview:self.playerView1 PlayerItem:[[AVPlayerItem alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"]]];
    
    [self preparePlayBackWithPreview:self.playerView2 PlayerItem:[[AVPlayerItem alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"2" withExtension:@"mp4"]]];
}


- (void)preparePlayBackWithPreview:(LGPlayerView *)preview PlayerItem:(AVPlayerItem *)item{
    [preview attachPlayItem:item];
    [preview attachSyncLayer:item.syncLayer bounds:CGRectMake(0, 0,540, 960)];
    [preview play];
}



@end
