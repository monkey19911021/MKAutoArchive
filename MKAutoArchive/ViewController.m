//
//  ViewController.m
//  MKAutoArchive
//
//  Created by Liujh on 16/4/21.
//  Copyright © 2016年 mk.mk. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
    NSMutableString *outInfoBackup;
    
    NSString *rootPath;
    NSString *appPath;
    
    NSString *appAbsoluteRootPath;
    NSString *ipaAbsoluteRootPath;
    
    NSString *userName;
    
    //本地信息列表
    NSArray *localInfoWithDicArray;
    //现场版本名
    NSMutableArray *localNameArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    appAbsoluteRootPath = nil;
    ipaAbsoluteRootPath = nil;
    
    outInfoBackup = [NSMutableString stringWithCapacity:1];
    
    localInfoWithDicArray = [NSMutableArray arrayWithCapacity:1];
    localNameArray = [NSMutableArray arrayWithCapacity:1];
    
    
    [self addObserver:self forKeyPath:@"path" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"appVersion" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"appName" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"localVersionName" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"ipaFilePath" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *newValue = [change objectForKey:@"new"];
    NSString *oldValue = [change objectForKey:@"old"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    if([keyPath isEqualToString:@"path"]){
        [localNameArray removeAllObjects];
        //从配置文件获得的本地版本英文名
        NSMutableString *localFromPrefix = [NSMutableString stringWithCapacity:1];
        
        rootPath = newValue;
        appPath = [[rootPath componentsSeparatedByString:@"/"] lastObject];
        if([[[rootPath componentsSeparatedByString:@"/"] firstObject] isEqualToString:@"~"]){
            rootPath = [rootPath substringFromIndex:1];
            NSArray *pathArray = [fileManager contentsOfDirectoryAtPath:@"/Users" error:nil];
            for(int i = 0; i<pathArray.count; i++){
                userName = [pathArray objectAtIndex:i];
                NSString *tempPath = [NSString stringWithFormat:@"/Users/%@%@/%@.xcodeproj", userName, rootPath, appPath];
                appAbsoluteRootPath = [NSString stringWithFormat:@"/Users/%@%@", userName, rootPath];
                if([fileManager fileExistsAtPath: tempPath]){
                    self.ipaFilePath = [NSString stringWithFormat:@"/Users/%@/Desktop", userName];
                    ipaAbsoluteRootPath = [NSString stringWithFormat:@"/Users/%@/Desktop", userName];
                    rootPath = [NSString stringWithFormat:@"/Users/%@%@/%@", userName, rootPath, appPath];
                    [outInfoBackup appendFormat:@"成功找到项目文件:%@.xcodeproj\n", appPath];
                    break;
                }
                if(i == (pathArray.count - 1)){
                    rootPath = nil;
                    [outInfoBackup appendFormat:@"找不到项目文件:%@.xcodeproj\n", appPath];
                }
            }
        }
        
        if(rootPath != nil){
            //寻找-Prefix.pch文件
            NSString *tempConfigFilePath = [NSString stringWithFormat:@"%@/%@-Prefix.pch", rootPath, appPath];
            if([fileManager fileExistsAtPath: tempConfigFilePath]){
                self.configFilePath = tempConfigFilePath;
                [outInfoBackup appendFormat:@"成功找到项目的配置文件:%@-Prefix.pch\n", appPath];
                
                //获取本地英文名
                NSMutableString *info = [NSMutableString stringWithContentsOfFile:tempConfigFilePath encoding:NSUTF8StringEncoding error:nil];
                NSRange preRange = [info rangeOfString:@"#define VERSIONNAME "];
                for(unsigned long i = preRange.location + preRange.length; i<info.length; i++){
                    NSString *tempStr = [info substringWithRange:NSMakeRange(i, 1)];
                    if([tempStr isEqualToString:@"\n"]){
                        break;
                    }else{
                        [localFromPrefix appendString:tempStr];
                    }
                }
                
                
            }else{
                self.configFilePath = nil;
                rootPath = nil;
                appPath = nil;
                [outInfoBackup appendFormat:@"找不到项目的配置文件:%@-Prefix.pch\n", appPath];
            }
            
            //寻找-Info.plist文件
            NSDictionary *infoPlistDic  = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@-Info.plist", rootPath, appPath]];
            if(infoPlistDic != nil){
                NSString *CFBundleDisplayName = [infoPlistDic objectForKey:@"CFBundleDisplayName"];
                NSString *CFBundleShortVersionString = [infoPlistDic objectForKey:@"CFBundleShortVersionString"];
                self.projectName = [NSString stringWithFormat:@"%@_%@_v%@", CFBundleDisplayName, dateStr, CFBundleShortVersionString];
                self.appVersion = CFBundleShortVersionString;
                self.appName = CFBundleDisplayName;
            }
            
            //寻找本地信息文件LocalInfo.plist
            localInfoWithDicArray  = [[NSArray alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/LocalInfo.plist", rootPath]];
            if(localInfoWithDicArray != nil){
                [outInfoBackup appendString:@"成功找到本地信息文件LocalInfo.plist\n"];
                NSString *tempLocalVersionName = @"";
                for(NSDictionary *dic in localInfoWithDicArray){
                    [localNameArray addObject:[dic objectForKey:@"local"]];
                    
                    if([[dic objectForKey:@"versionName"] isEqualToString:localFromPrefix]){
                        tempLocalVersionName = [dic objectForKey:@"local"];
                    }
                    
                }
                self.localInfoArray = localNameArray;
                self.localVersionName = tempLocalVersionName;
                
            }else{
                [outInfoBackup appendString:@"找不到本地信息文件LocalInfo.plist\n"];
            }
            
        }else{
            rootPath = nil;
            appPath = nil;
            userName = nil;
            ipaAbsoluteRootPath = nil;
            appAbsoluteRootPath = nil;
            self.projectName = @"";
            self.configFilePath = @"";
            self.localVersionName = nil;
            self.localInfoArray = @[@""];
            self.appVersion = @"";
            self.appName = @"";
        }
        
        
    }
    
    if([keyPath isEqualToString:@"appVersion"] && ![newValue isEqualTo:oldValue]){
        NSString *infoListPath = [NSString stringWithFormat:@"%@/%@-Info.plist", rootPath, appPath];
        NSDictionary *infoPlistDic  = [[NSDictionary alloc] initWithContentsOfFile:infoListPath];
        if(infoPlistDic != nil){
            NSString *tempVersion = newValue;
            self.projectName = [NSString stringWithFormat:@"%@_%@_v%@", [infoPlistDic objectForKey:@"CFBundleDisplayName"], dateStr, tempVersion];
            [infoPlistDic setValue:tempVersion forKey:@"CFBundleShortVersionString"];
            [infoPlistDic setValue:tempVersion forKey:@"CFBundleVersion"];
            [infoPlistDic writeToFile:infoListPath atomically:YES];
        }
    }
    
    if([keyPath isEqualToString:@"localVersionName"] && ![newValue isEqualTo:oldValue]){
        NSString *infoListPath = [NSString stringWithFormat:@"%@/%@-Info.plist", rootPath, appPath];
        NSDictionary *infoPlistDic  = [[NSDictionary alloc] initWithContentsOfFile:infoListPath];
        if(infoPlistDic != nil){
            NSString *str = newValue;
            NSString *disName = [[localInfoWithDicArray objectAtIndex:[localNameArray indexOfObject:str]] objectForKey:@"appName"];
            self.projectName = [NSString stringWithFormat:@"%@_%@_v%@", disName, dateStr, [infoPlistDic objectForKey:@"CFBundleShortVersionString"]];
            
            self.appName = disName;
            [infoPlistDic setValue:disName forKey:@"CFBundleDisplayName"];
            [infoPlistDic writeToFile:infoListPath atomically:YES];
            
            
            if([oldValue isNotEqualTo:[NSNull null]]){
                //修改配置文件
                NSString *tempConfigFilePath = [NSString stringWithFormat:@"%@/%@-Prefix.pch", rootPath, appPath];
                NSMutableString *info = [NSMutableString stringWithContentsOfFile:tempConfigFilePath encoding:NSUTF8StringEncoding error:nil];
                NSRange preRange = [info rangeOfString:@"#define VERSIONNAME "];
                NSString *oldVersionName = [[localInfoWithDicArray objectAtIndex:[localNameArray indexOfObject:oldValue]] objectForKey:@"versionName"];
                NSRange rewriteRange = NSMakeRange(preRange.location + preRange.length, oldVersionName.length);
                [info replaceCharactersInRange:rewriteRange withString:[[localInfoWithDicArray objectAtIndex:[localNameArray indexOfObject:str]] objectForKey:@"versionName"]];
                [info writeToFile:tempConfigFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
            }
        }
    }
    
    if([keyPath isEqualToString:@"appName"] && ![newValue isEqualTo:oldValue]){
        NSString *infoListPath = [NSString stringWithFormat:@"%@/%@-Info.plist", rootPath, appPath];
        NSDictionary *infoPlistDic  = [[NSDictionary alloc] initWithContentsOfFile:infoListPath];
        if(infoPlistDic != nil){
            self.projectName = [NSString stringWithFormat:@"%@_%@_v%@", newValue, dateStr, [infoPlistDic objectForKey:@"CFBundleShortVersionString"]];
            [infoPlistDic setValue:newValue forKey:@"CFBundleDisplayName"];
            [infoPlistDic writeToFile:infoListPath atomically:YES];
        }
    }
    
    if([keyPath isEqualToString:@"ipaFilePath"] && ![newValue isEqualTo:oldValue]){
        ipaAbsoluteRootPath = newValue;
        if([[[ipaAbsoluteRootPath componentsSeparatedByString:@"/"] firstObject] isEqualToString:@"~"]){
            ipaAbsoluteRootPath = [ipaAbsoluteRootPath substringFromIndex:1];
            ipaAbsoluteRootPath = [NSString stringWithFormat:@"/Users/%@%@", userName, ipaAbsoluteRootPath];
        }
    }
    
    self.outInfo = @"";
    self.outInfo = outInfoBackup;
}


//打包
- (IBAction)packageClick:(id)sender {
    self.outInfo = @"";
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"打包中......" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:(NSRect){100,50,250,50}];
    [progressIndicator startAnimation:nil];
    [[[alert window] contentView] addSubview:progressIndicator];
    NSButton *btn = [[alert buttons] objectAtIndex:0];
    [btn setEnabled:NO];
//    [alert beginSheetModalForWindow:[NSWindow windowWithContentViewController:self] completionHandler:^(NSModalResponse returnCode) {}];
    
    
    NSString *ipaBuildPath = [[NSBundle mainBundle] pathForResource:@"ipa-build" ofType:nil];
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: ipaBuildPath];
    [task setTerminationHandler:^(NSTask *_task) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *ipaFilePath = [NSString stringWithFormat:@"%@/build/ipa-build/target.ipa", appAbsoluteRootPath];
        if([fileManager fileExistsAtPath:ipaFilePath]){
            [fileManager copyItemAtPath:ipaFilePath toPath:[NSString stringWithFormat:@"%@/%@.ipa", ipaAbsoluteRootPath, _projectName] error:nil];
        }
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/build",appAbsoluteRootPath] error:nil];
        alert.messageText = @"打包完成！！";
        alert.informativeText = @"";
        [btn setEnabled:YES];
        [progressIndicator removeFromSuperview];
    }];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: appAbsoluteRootPath, ipaAbsoluteRootPath, nil];
    [task setArguments: arguments];
    
    //NSPipe代表一个BSD管道，即一种进程间的单向通讯通道
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    //使用执行外部命令方法
    //    NSString *command = [NSString stringWithFormat:@"%@ %@ AdHoc %@", ipaBuildPath, appAbsoluteRootPath, ipaAbsoluteRootPath];
    //    system([command UTF8String]);
    
    self.outInfo = string;
}

@end
