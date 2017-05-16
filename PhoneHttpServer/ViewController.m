//
//  ViewController.m
//  PhoneHttpServer
//
//  Created by 郭达 on 2017/5/15.
//  Copyright © 2017年 Guoda. All rights reserved.
//

#import "ViewController.h"
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>
#import "GDHeaderCenter.h"

#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "MyHttpConnection.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface ViewController ()
{
   	HTTPServer *httpServer;

}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createPathWithPath:Local_Home_Library_Path];
    NSString *dataPath = [NSString stringWithFormat:@"%@/%@",Local_Home_Library_Path,@"Data"];
    [self createPathWithPath:dataPath];

    NSLog(@"%@",Local_Home_Library_Path);
    
    [self initHttpServer];
    [self openSuccess];
    
}

- (void)createPathWithPath:(NSString *)path {
    //    NSString *path1 = [NSString stringWithFormat:@"%@/Library/XZSP",NSHomeDirectory()];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL yes;
    if (![manager fileExistsAtPath:path isDirectory:&yes]) {
        BOOL b=[manager createDirectoryAtPath:path withIntermediateDirectories:yes attributes:nil error:nil];
        XC_DebugLog(@"b=%d",b);
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openSuccess{
    NSError *error = nil;
    if ([httpServer start:&error]) {
        XC_DebugLog(@"开启成功");
        NSString *address = [self localWiFiIPAddress];
        NSString *addPortText = [NSString stringWithFormat:@"%@:%hu",address,httpServer.running_Port];
        XC_DebugLog(@"服务器输入%@",addPortText);
    }else {
        XC_DebugLog(@"开始失败");

    }
}


- (void)initHttpServer {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    httpServer = [[HTTPServer alloc] init];
    [httpServer setType:@"_http._tcp."];
    [httpServer setPort:6789];//端口号自己可以改
    
    //设置总的路径 css js之类的调用
    NSString *docRoot = [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:@"webServer-xc"];
    
#if 1
    
//    LabelText()  这个是多语言环境的，根据手机系统语言改html显示的语言，多语言这个配置大家可以上网查  把下面的固定也行
    
    //设置html中的值为自己想要的，具体可以看 indextest.html文件
    NSString *str  = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"indextest" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    //title
    NSString *change_title = [str stringByReplacingOccurrencesOfString:@"%title%" withString:LabelText(@"Title")];
    //device
    NSString* userPhoneName = [[UIDevice currentDevice] name];
    NSString *change_phoneName = [change_title stringByReplacingOccurrencesOfString:@"%device%" withString:userPhoneName];
    //header
    NSString *change_header = [change_phoneName stringByReplacingOccurrencesOfString:@"%header%" withString:LabelText(@"Header")];
    //prologue主页
    NSString *change_prologue = [change_header stringByReplacingOccurrencesOfString:@"%prologue%" withString:LabelText(@"PROLOGUE")];
    //upload
    NSString *upload = [change_prologue stringByReplacingOccurrencesOfString:@"%upload%" withString:LabelText(@"UPLOAD")];
    //refresh
    NSString *refresh = [upload stringByReplacingOccurrencesOfString:@"%refresh%" withString:LabelText(@"REFRESH")];
    //epilogue
    NSString *epilogue = [refresh stringByReplacingOccurrencesOfString:@"%epilogue%" withString:LabelText(@"EPILOGUE")];
    //footer
    NSString *footer = [epilogue stringByReplacingOccurrencesOfString:@"%footer%" withString:LabelText(@"Footer")];
    
    NSString *localPath = [Data_Local_Directory stringByAppendingPathComponent:@"index.html"];
    [footer writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
#endif
    
    [httpServer setDocumentRoot:docRoot];
    [httpServer setConnectionClass:[MyHttpConnection class]];
}

#pragma mark - ip地址
- (NSString *) localWiFiIPAddress
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return nil;
}
@end
