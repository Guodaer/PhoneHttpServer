//
//  GD_CustomCenter.h
//  CheJiBao
//
//  Created by xiaoyu on 15/11/24.
//  Copyright © 2015年 guoda. All rights reserved.
//

#ifndef GD_CustomCenter_h
#define GD_CustomCenter_h


/**3
 *  屏幕的大小
 */
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width

#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
/**
 *  加在本地图片
 *
 *  @param x 图片名称
 *
 *  @return UIImage
 */
#define XUILocalImage(x) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:x ofType:@"png"]]
/**
 *  颜色0x------
 *
 *  @param rgbValue
 *
 *  @return UIColor
 */
#define XUIColor(rgbValue,alp) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alp]

/**
 *  默认颜色
 *
 *  @param alpha 透明度
 *
 *  @return 默认颜色
 */
#define rgbdefaultValue 0x47ba99

/**
 *  判断设备型号
*/
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define SCREEN_MAX_LENGTH (MAX(SCREENWIDTH, SCREENHEIGHT))
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6p (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)


#ifdef DEBUG
#define XC_DebugLog( s, ... ) NSLog( @"^_^[%@:(%d)] %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define XC_DebugLog( s, ... )
#endif

#ifdef DEBUG
#define XCLog(format, ...) printf("%s ^_^[%s (%d)] %s\n", [[SingleOperationManager GetLogNowTime]UTF8String], [[[NSString stringWithUTF8String:__FILE__] lastPathComponent]UTF8String], __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
#else
#define XC_DebugLog( s, ... )
#endif



#define LabelText(content) NSLocalizedString(content,@"")

/**
 *  沙盒路径-缓存/Library/XZSP
 */
#define Local_Home_Library_Path ([NSString stringWithFormat:@"%@/Library/XZSP",NSHomeDirectory()])

//#define Modify__Directory true//FALSE

#define Documets_Path ([NSString stringWithFormat:@"%@/Documents/",NSHomeDirectory()])

/**
 数据
 */
#define Data_Local_Directory ([NSString stringWithFormat:@"%@/%@",Local_Home_Library_Path,@"Data"])

/**Caches
 *  沙盒路径-表
 */
#define Local_Home_Documents_Path ([NSString stringWithFormat:@"%@/Library",NSHomeDirectory()])

//角度转弧度
#define DEGREES_TO_RADIANS(d) (d * M_PI / 180)

/**
 *  判断系统版本是否大于9.0
 */
#define iOS_VERSION_9_OR_LATER (([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)? (YES):(NO))

#define iOS_VERSION_8_OR_LATER __IPHONE_OS_VERSION_MAX_ALLOWED>=__IPHONE_8_0

#define iOS_VERSION_10_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)





#endif /* GD_CustomCenter_h */
