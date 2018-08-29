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

static NSString *const kCell = @"BlueTableCell";

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CBCentralManager *manager; // 中央设备
@property (nonatomic, strong) CBPeripheral *discoverPeripheral; // 周边设备
@property (nonatomic, strong) CBCharacteristic *characteristic; // 周边设备服务特性
@property (nonatomic, strong) NSMutableArray *bleViewPerArr;
@property (nonatomic, assign) CBManagerState bluetoothFailState;

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
    [_manager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    //记录目前是扫描状态
//    _bluetoothState = BluetoothStateScaning;
    //清空所有外设数组
    [_bleViewPerArr removeAllObjects];
    //如果蓝牙状态未开启，提示开启蓝牙
    if(_bluetoothFailState == CBManagerStatePoweredOff) {
        NSLog(@"%@",@"检查您的蓝牙是否开启后重试");
    }
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



#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnauthorized"); // 不支持蓝牙
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
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

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (peripheral == nil || peripheral.identifier == nil) {
        return;
    }
    NSString *pername = [NSString stringWithFormat:@"%@", peripheral.name];
    // 判断是否存在@"你的设备名"
    NSRange range = [pername rangeOfString:@"MI Band 2"];
    // 如果从搜索到的设备中找到指定设备名，和_bleViewPerArr数组没有它的地址
    // 加入_bleViewPerArr数组
    if(range.location != NSNotFound && [_bleViewPerArr containsObject:peripheral] == NO){
        [_bleViewPerArr addObject:peripheral];
    }
//    _bluetoothFailState = BluetoothFailStateUnExit;
//    _bluetoothState = BluetoothStateScanSuccess;
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
