//
//  DXBuffer.h
//  BLE-Demo
//
//  Created by DaXiong on 17/3/27.
//  Copyright © 2017年 DaXiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DXBuffer : NSObject

/**
 拼接数据
 @param data 特征值收到数据
 */
- (void)appendData:(NSData *)data;

@end
