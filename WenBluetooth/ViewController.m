//
//  ViewController.m
//  WenBluetooth
//
//  Created by LHWen on 2018/8/28.
//  Copyright © 2018年 LHWen. All rights reserved.
//

#import "ViewController.h"
// 导入蓝牙头文件
#import <CoreBluetooth/CoreBluetooth.h>

/**
 iOS开发中，谈到蓝牙现在基本最常使用的框架就是CoreBluetooth框架了，使用该框架可以iOS设备与蓝牙设备或者iOS设备与其他非蓝牙设备的交互。
 
 蓝牙开发分为两种：中心者模式和管理者模式
 
 中心者模式
 我们的手机作为中心设备，连接蓝牙设备（这也是最常用的一种模式，比如使用我们的手机连接小米手环、空气净化器等；我们以下的开发也是基于这种模式。）
 
 管理者模式
 我们的手机作为外设，自己创建服务于特征，供其他设备连接我们的手机
 
 1. 中心设备：用于扫描周边蓝牙外设的设备，比如我们上面所说的中心者模式，此时我们的手机就是中心设备。
 2. 外设：被扫描的蓝牙设备，比如我们上面所说的用我们的手机连接小米手环，这时候小米手环就是外设。
 3. 广播：外部设备不停的散播的蓝牙信号，让中心设备可以扫描到，也是我们开发中接收数据的入口。
 4. 服务(Service)：外部设备在与中心设备连接后会有服务，可以理解成一个功能模块，中心设备可以读取服务，筛选我们想要的服务，并从中获取出我们想要特征。（外设可以有多个服务）
 5. 特征(Characteristic)：服务中的一个单位，一个服务可以多个特征，而特征会有一个value，一般我们向蓝牙设备写入数据、从蓝牙设备读取数据就是这个value
 6. UUID：区分不同服务和特征的唯一标识，使用该字端我们可以获取我们想要的服务或者特征。
 */

static NSString *const kCell = @"BlueTableCell";

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CBCentralManager *manager; // 中央设备 中心管理者
@property (nonatomic, strong) CBPeripheral *peripheral; // 周边设备
@property (nonatomic, strong) CBCharacteristic *characteristic; // 周边设备服务特性
@property (nonatomic, strong) NSMutableArray *bleViewPerArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor orangeColor];
    _bleViewPerArr = [NSMutableArray new];
    
    // 创建实例,设置代理,创建数组管理外设
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    _manager.delegate = self;
    _bleViewPerArr = [[NSMutableArray alloc] initWithCapacity:1];
    
    [self p_setTableView];
    
    [self scan];
}

// 开始扫描
- (void)scan {
    //判断状态开始扫瞄周围设备 第一个参数为空则会扫瞄所有的可连接设备  你可以
    //指定一个CBUUID对象 从而只扫瞄注册用指定服务的设备
    //scanForPeripheralsWithServices方法调用完后会调用代理CBCentralManagerDelegate的
    //- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI方法
    [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    
    //清空所有外设数组
    [_bleViewPerArr removeAllObjects];
}

- (void)p_setTableView {
    
    if (!_tableView) {
        
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [UIView new];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            
            if ([UIScreen mainScreen].bounds.size.height == 812.0) { // iPhone X
                _tableView.contentInset = UIEdgeInsetsMake(0, 0, 34.0f, 0);
            }
        }
        
        _tableView.separatorColor = [UIColor orangeColor];
        _tableView.separatorInset = UIEdgeInsetsMake(0, 13.0, 0, 0);
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCell];
        _tableView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:_tableView];
    }
}

#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _bleViewPerArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCell];
    }
    
    // 将蓝牙外设对象接出，取出name，显示
    //蓝牙对象在下面环节会查找出来，被放进BleViewPerArr数组里面，是CBPeripheral对象
    CBPeripheral *per = (CBPeripheral *)_bleViewPerArr[indexPath.row];
//    NSString *bleName = [per.name substringWithRange:NSMakeRange(0, 9)];
    cell.textLabel.text = per.name;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /**
     点击链接外部蓝牙设备
     */
    CBPeripheral *per = (CBPeripheral *)_bleViewPerArr[indexPath.row];
    _peripheral = nil;
    _peripheral = per;
//    [_manager connectPeripheral:per options:nil];
    
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown"); // 设备类型位置
            break;
        case CBManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting"); // 设备初始化中
            break;
        case CBManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnauthorized"); // 不支持蓝牙
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized"); // 设备未授权
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");  // 蓝牙未开启
            break;
        case CBManagerStatePoweredOn:{
            NSLog(@"CBCentralManagerStatePoweredOn"); // 蓝牙已开启
            // 搜索外设
            [_manager scanForPeripheralsWithServices:nil options:nil];
            break;
        }
            
        default:
            break;
    }
    
}

/**
 发现外设后调用
 cetral 中心管理者
 peripheral 外设
 advertisementData 外设携带数据信息
 RSSI 信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (peripheral == nil || peripheral.identifier == nil) {
        return;
    }
    
    NSLog(@"---peripheral name is %@", [NSString stringWithFormat:@"%@", peripheral.name]);
    
    NSString *pername = [NSString stringWithFormat:@"%@", peripheral.name];
    
    /**
    if ([peripheral.name hasPrefix:@"HT"]) {  // 判断是否存在HT名称的蓝牙设备 筛选
        NSLog(@"%@",peripheral.name);//能够进来的 都是我们想要的设备了
        //我们的逻辑是，搜索到一个设备（peripheral）放到一个集合，然后给用户进行选择
    }
     */
    
    // 判断是否存在@"你的设备名"
//    NSRange range = [pername rangeOfString:@"MI Band 2"];
    // 如果从搜索到的设备中找到指定设备名，和_bleViewPerArr数组没有它的地址
    // 加入_bleViewPerArr数组
    // range.location != NSNotFound &&
    if([_bleViewPerArr containsObject:peripheral] == NO && ![pername isEqualToString:@"(null)"]){
        [_bleViewPerArr addObject:peripheral];
    }
    [_tableView reloadData];
}

/**
  中心管理者链接外设成功
  central 中心管理者
  peripheral 外设
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"%s, line = %d, %@=连接成功", __FUNCTION__, __LINE__, peripheral.name);
    // 连接成功之后,可以进行服务和特征的发现
    // 设置外设代理
    _peripheral.delegate = self;
    
    // 外设服务，传nil表示不过滤
    // 会触发外设代理方法 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [_peripheral discoverServices:nil];
}

// 外设链接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
}

// 丢失链接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
   
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
}

// 发现外设服务里的特征的时候调用的代理方法(这个是比较重要的方法，你在这里可以通过事先知道UUID找到你需要的特征，订阅特征，或者这里写入数据给特征也可以)
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    for (CBCharacteristic *cha in service.characteristics) {
        
        NSLog(@"%s, line = %d, char = %@", __FUNCTION__, __LINE__, cha);
    }
}

// 更新特征的value的时候会调用 （凡是从蓝牙传过来的数据都要经过这个回调，简单的说这个方法就是你拿数据的唯一方法） 你可以判断是否
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
//    if (characteristic == @"你要的特征的UUID或者是你已经找到的特征") {
//        //characteristic.value就是你要的数据
//    }
}

/**
 给外围设备发送数据（也就是写入数据到蓝牙）
 这个方法你可以放在点击事件的响应里面，也可以在找到特征的时候就写入，具体看业务需求
 1.第一个参数是已连接的蓝牙设备
 2.第二个参数是要写入到哪个特征
 3.第三个参数是通过此响应记录是否成功写入
 [self.peripherale writeValue:_batteryData forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
 */

#pragma mark - 需要注意的是特征的属性是否支持写数据 私有方法
- (void)yf_peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic {
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                              = 0x01,
     CBCharacteristicPropertyRead                                                   = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                   = 0x04,
     CBCharacteristicPropertyWrite                                                  = 0x08,
     CBCharacteristicPropertyNotify                                                 = 0x10,
     CBCharacteristicPropertyIndicate                                               = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                              = 0x40,
     CBCharacteristicPropertyExtendedProperties                                     = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x200
     };
     
     打印出特征的权限(characteristic.properties),可以看到有很多种,这是一个NS_OPTIONS的枚举,可以是多个值
     常见的又read,write,noitfy,indicate.知道这几个基本够用了,前俩是读写权限,后俩都是通知,俩不同的通知方式
     */
    //    NSLog(@"%s, line = %d, char.pro = %d", __FUNCTION__, __LINE__, characteristic.properties);
    // 此时由于枚举属性是NS_OPTIONS,所以一个枚举可能对应多个类型,所以判断不能用 = ,而应该用包含&
}

/**
 因为蓝牙只能支持16进制，而且每次传输只能20个字节，所以要把信息流转成双方可识别的16进制 数据传输时需要处理
 手环数据参考文档: https://www.jianshu.com/p/ee4fef3762ef
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
