//
//  ViewController.h
//  MKAutoArchive
//
//  Created by Liujh on 16/4/21.
//  Copyright © 2016年 mk.mk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

/**
 要使用路径选择器要引进AutoMator框架
 */

//项目根目录
@property (strong, nonatomic) NSString *path;

//配置文件路径
@property (strong, nonatomic) NSString *configFilePath;

//ipa生成路径
@property (strong, nonatomic) NSString *ipaFilePath;

//生成项目名
@property (strong, nonatomic) NSString *projectName;

//生成应用名
@property (strong, nonatomic) NSString *appName;

//现场版本
@property (strong, nonatomic) NSString *localVersionName;

//应用版本号
@property (strong, nonatomic) NSString *appVersion;

//控制台信息
@property (strong, nonatomic) NSString *outInfo;

//现场版本列表
@property (strong, nonatomic) NSArray *localInfoArray;

@end

