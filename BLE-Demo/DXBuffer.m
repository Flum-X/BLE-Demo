//
//  DXBuffer.m
//  BLE-Demo
//
//  Created by DaXiong on 17/3/27.
//  Copyright © 2017年 DaXiong. All rights reserved.
//

#import "DXBuffer.h"
#import <libkern/OSAtomic.h>

@interface DXBuffer()
{
    NSMutableData * _reciveData;
    
    NSData *_headData;                          // 帧头
    NSData *_soundHeadData;                     // 声音数据头
    NSData *_heartHeadData;                     // 胎心数据头
}
/** 模型数组 */
//@property (nonatomic, strong) NSMutableArray * bufferArray;
@end

@implementation DXBuffer

- (instancetype)init
{
    if (self = [super init])
    {
        _reciveData = [NSMutableData data];
        
        Byte headByte[] = {0xFE, 0xA0};
        _headData = [NSData dataWithBytes:headByte length:2];
        
        Byte soundByte[] = {0xFE, 0xA0, 0x05};
        _soundHeadData = [NSData dataWithBytes:soundByte length:3];
        
        Byte heartByte[] = {0xFE, 0xA0, 0x0A};
        _heartHeadData = [NSData dataWithBytes:heartByte length:3];
    }
    return self;
}

- (void)appendData:(NSData *)data
{
    [_reciveData appendData:data];
    [self analysisData];
}

/**
 数据分析
 */
- (void)analysisData
{
    /**
     不丢包数据格式
     FE AO 05 ** ** ...... 01       (声音数据01 107B)
     FE AO 05 ** ** ...... 02       (声音数据02 107B)
     FE AO 05 ** ** ...... 03       (声音数据03 107B)
     FE AO 05 ** ** ...... 04       (声音数据04 107B)
     FE AO 05 ** ** ...... 05       (声音数据05 107B)
     FE AO 0A ** ** ......          (胎心数据 10B)
     */
    
    NSRange range = [_reciveData rangeOfData:_headData options:0 range:NSMakeRange(0, [_reciveData length])];
    
    // 存在 FE A0
    if (range.location != NSNotFound)
    {
        if (range.location == 0) {
            // FE A0 ** ** ** 应寻找到下一个帧头再做截取
            NSRange subRange = NSMakeRange(range.length, _reciveData.length - range.length);
            
            // 去掉FE A0 寻找下一帧的帧头
            NSData * subData = [_reciveData subdataWithRange:subRange];
            NSRange nextRange = [subData rangeOfData:_headData options:0 range:NSMakeRange(0, [subData length])];
            
            // 存在下一帧头
            if (nextRange.location != NSNotFound) {
                // FE A0 ** ** ...... FE A0 **      数据截取
                NSRange cutRange = NSMakeRange(0, nextRange.location + 2);
                NSData * rangeData = [_reciveData subdataWithRange:cutRange];
                
                if ([rangeData rangeOfData:_soundHeadData options:0 range:NSMakeRange(0, [rangeData length])].location != NSNotFound) {
                    
                    // 声音数据
                    NSUInteger soundDataLength = rangeData.length;
                    if (soundDataLength == 107) {
                        NSLog(@"声音数据 🐶 ***** %@",rangeData);
                    } else {
                        NSLog(@"声音数据 😅 error: 存在数据头 %@",rangeData);
                    }
                    
                } else if ([rangeData rangeOfData:_heartHeadData options:0 range:NSMakeRange(0, [rangeData length])].location != NSNotFound) {
                    
                    // 胎心数据
                    NSUInteger heartDataLength = rangeData.length;
                    if (heartDataLength == 10) {
                        NSLog(@"胎心数据 💖 ***** %@",rangeData);
                    } else {
                        NSLog(@"胎心数据 😅 error: 存在数据头 %@",rangeData);
                    }
                } else {
                    NSLog(@"😅 error: 存在数据头 %@",rangeData);
                }
                
                // 调整到正确的帧头
                NSInteger true_location = nextRange.location + 2;
                _reciveData = [_reciveData subdataWithRange:NSMakeRange(true_location, _reciveData.length - true_location)].mutableCopy;
            }
        } else {
            // ** ** FE A0 ** ** **
            NSInteger index = range.location;
            NSRange subRange = NSMakeRange(index, _reciveData.length - index);
            
            // 错误数据
            NSData * errorData = [_reciveData subdataWithRange:NSMakeRange(0, range.location)];
            NSLog(@"😅 error: 不存在数据头  %@",errorData);
            
            // 调整到正确的帧头
            _reciveData = [_reciveData subdataWithRange:subRange].mutableCopy;
        }
    }
}

@end
