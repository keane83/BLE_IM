//
//  ViewController.m
//  BLEBackgroundMode
//
//  Created by Mario Zhang on 13-12-30.
//  Copyright (c) 2013年 Mario Zhang. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD830527"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FA830527"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManger;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableData *data;
- (void)readRSSI;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.centralManger = [[CBCentralManager alloc] initWithDelegate:self
                                                              queue:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)readRSSI
{
    DLog();
    if (self.peripheral) {
        [self.peripheral readRSSI];
    }
}

-(void)presentNotificationWithString:(NSString*)str{
    
    if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = str;
        localNotification.alertAction = @"Somebody Come^_^";
        //On sound
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        //increase the badge number of application plus 1
        localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Somebody Come^_^" message:str delegate:nil cancelButtonTitle:@"I Know" otherButtonTitles: nil];
        [alert show];
    }
    
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self logToFileWithString:[NSString stringWithFormat:@"centralManagerDidUpdateState state=%d",central.state]];
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralManger scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                   options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    DLog(@"peripheral name %@ id %@ rssi %d", peripheral.name, peripheral.identifier, [RSSI integerValue]);
    
    [self logToFileWithString:[NSString stringWithFormat:@"peripheral name %@ id %@ rssi %d", peripheral.name, peripheral.identifier, [RSSI integerValue]]];
    
    self.peripheral = peripheral;
    [self.centralManger connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self logToFileWithString:[NSString stringWithFormat:@"didConnectPeripheral peripheral name %@", peripheral.name]];
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
//    if (!self.timer) {
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
//                                                      target:self
//                                                    selector:@selector(readRSSI)
//                                                    userInfo:nil
//                                                     repeats:1.0];
//        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
//    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self logToFileWithString:[NSString stringWithFormat:@"didDisconnectPeripheral peripheral name %@", peripheral.name]];
    [self.centralManger connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    DLog(@"centralManager didFailToConnectPeripheral %@",error);
    [self logToFileWithString:[NSString stringWithFormat:@"centralManager didFailToConnectPeripheral %@",error]];
    [central cancelPeripheralConnection:peripheral];
    
    sleep(1);
    [self toStop];
    sleep(1);
    [self toScan];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (!error) {
        NSLog(@"rssi %d", [[peripheral RSSI] integerValue]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        DLog(@"Error discovering services: %@", [error localizedDescription]);
        [self logToFileWithString:[NSString stringWithFormat:@"Error discovering services: %@", [error localizedDescription]]];
        //[self cleanup];
        return;
    }
    DLog(@"peripheral didDiscoverServices");
    [self logToFileWithString:[NSString stringWithFormat:@"peripheral didDiscoverServices"]];
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        DLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self logToFileWithString:[NSString stringWithFormat:@"Error discovering characteristics: %@", [error localizedDescription]]];
        return;
    }
    DLog(@"peripheral didDiscoverCharacteristicsForService");
    [self logToFileWithString:[NSString stringWithFormat:@"peripheral didDiscoverCharacteristicsForService"]];
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        DLog(@"peripheral didDiscoverCharacteristicsForService FOR");

        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            
            // If it is, subscribe to it/Users/wenbc/Downloads/BLEBackgroundMode-master/BLEBackgroundModeTests/en.lproj/InfoPlist.strings
            DLog(@"peripheral didDiscoverCharacteristicsForService NOTIFY SET");
            [self logToFileWithString:[NSString stringWithFormat:@"peripheral didDiscoverCharacteristicsForService NOTIFY SET"]];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}


//peripheral service 中检测到characteristic发现变化
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        DLog(@"Error didUpdateValueForCharacteristic: %@", [error localizedDescription]);
        [self logToFileWithString:[NSString stringWithFormat:@"Error didUpdateValueForCharacteristic: %@", [error localizedDescription]]];
        return;
    }
    
    if(self.data == nil)
    {
        _data = [[NSMutableData alloc] init];
    }
    
    [self logToFileWithString:[NSString stringWithFormat:@"peripheral didUpdateValueForCharacteristic"]];
    DLog(@"peripheral didUpdateValueForCharacteristic");
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    //if ([stringFromData isEqualToString:@"EOM"]) {
    
    // We have, so show the data,
    NSString *dataStr = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    
    //[peripheral setNotifyValue:NO forCharacteristic:characteristic];
    
    //通知自己
    [self presentNotificationWithString:stringFromData];
    self.data = nil;
    //NSString *send = [NSString stringWithFormat:@"I have get Your Letter,this message come from %@",[[UIDevice currentDevice] name]];
    //告诉对方
    //[self writeChar:[send dataUsingEncoding:NSUTF8StringEncoding]];
    // }
    
    // Otherwise, just add the data on to what we already have
    // [self.data appendData:characteristic.value];
    
    // Log it
    DLog(@"Received: %@", stringFromData);
}
//test2
- (void)toScan
{
    [self.centralManger scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    //@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
    
}

- (void)toStop
{
    [self.centralManger stopScan];
    
}




- (void)logToFileWithString:(NSString*)str
{
    NSTimeZone *zone =[NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: [NSDate date]];
    NSDate *localDate =[[NSDate date]  dateByAddingTimeInterval: interval];
    
    NSString* s = [NSString stringWithFormat:@"\n[%@] %@",localDate,str];
    //    NSLog(@"\n[%@]locationManager: %f,%f",localDate,newLocation.coordinate.latitude,newLocation.coordinate.longitude);
    
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *testPath = [documentsDirectory stringByAppendingPathComponent:@"log.txt"];
    NSLog(@"app_home_doc: %@",testPath);
    if(![[NSFileManager defaultManager] fileExistsAtPath:testPath isDirectory:NO]){
        [[NSFileManager defaultManager] createFileAtPath:testPath contents:nil attributes:nil];
    }
    NSFileHandle* outFile = [NSFileHandle fileHandleForWritingAtPath:testPath];
    [outFile seekToEndOfFile];
    [outFile writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
