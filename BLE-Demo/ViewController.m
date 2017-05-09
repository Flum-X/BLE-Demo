//
//  ViewController.m
//  BLE-Demo
//
//  Created by DaXiong on 17/3/27.
//  Copyright © 2017年 DaXiong. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "DXBuffer.h"

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCentralManager * _centralManager;
    CBPeripheral * _targetPeripheral;
    CBCharacteristic * _writeCharacteristic;
}
@property (nonatomic, strong) DXBuffer * buffer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

/**
 * 蓝牙状态发生改变
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self startScan];
            break;
        default:
            break;
    }
}

/**
 *  开始扫描
 */
- (void)startScan
{
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [_centralManager scanForPeripheralsWithServices:nil
                                            options:options];
}

/**
 *  发现外围设备
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //    NSArray * serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    NSData * data = advertisementData[CBAdvertisementDataManufacturerDataKey];
    NSString * local_name = advertisementData[CBAdvertisementDataLocalNameKey];
    if ([local_name isEqualToString:@"T2"]) {
        //        NSLog(@"名字: %@\n serviceUUIDs --> %@ \n 厂商自定义 --> %@ \n",local_name,serviceUUIDs,data);
        int len = 6;
        NSData * selfData =[data subdataWithRange:NSMakeRange(2, data.length - len -2)];
        NSLog(@"%@",selfData);
        
        NSRange range = NSMakeRange(4, 2);
        NSData * measureData3Data =[selfData subdataWithRange:range];
        
        const short * value3Bytes = [measureData3Data bytes];
        unsigned short value3 = value3Bytes[0];
        NSLog(@"温度 --> %.2f",value3 * 0.01f);
        
    }  else if ([local_name isEqualToString:@"JPDB0A893"]) {
        _targetPeripheral = peripheral;
        [_centralManager stopScan];
        [_centralManager connectPeripheral:_targetPeripheral options:nil];
        
    }
}


/**
 *  连接成功
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}


#pragma mark - CBPeripheralDelegate
/**
 *  发现服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService*server in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:server];
    }
}

/**
 *  发现特征
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic*characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0xFFF1"]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            _targetPeripheral = peripheral;
            _writeCharacteristic = characteristic;
        }
    }
}

/**
 *  特征值改变
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"ValueForCharacteristic --> %@",characteristic.value);
    //    [self.buffer appendData:characteristic.value];
}

- (DXBuffer *)buffer
{
    if (!_buffer) {
        _buffer = [[DXBuffer alloc] init];
    }
    return _buffer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
