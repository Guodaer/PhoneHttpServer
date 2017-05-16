//
//  MyHttpConnection.m
//  HttpServer
//
//  Created by X-Designer on 17/3/17.
//  Copyright © 2017年 Guoda. All rights reserved.
//

#import "MyHttpConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"

#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPFileResponse.h"
#import "GDHeaderCenter.h"
//#import "SocketManager.h"

@class MultipartFormDataParser;
// Log levels : off, error, warn, info, verbose
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;

@interface MyHttpConnection (){
    MultipartFormDataParser*        parser;
    NSFileHandle*					storeFile;
    
    NSMutableArray*					uploadedFiles;
    
    NSString *deleteFileName;
}


@end

@implementation MyHttpConnection
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    HTTPLogTrace();
    
    // Add support for POST
    if ([method isEqualToString:@"POST"])
    {
        if ([path isEqualToString:@"/upload.html"]||[path isEqualToString:@"/refresh"]||[path isEqualToString:@"/upload"]||[path isEqualToString:@"/delete"])
        {
            return YES;
        }
    }
    if ([method isEqualToString:@"GET"]) {
        if ([path isEqualToString:@"/list?path=%2F"])
        {
            return YES;
        }

    }
    
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    HTTPLogTrace();
//            XC_DebugLog(@"🍌🍌🍌%@-%@",method,path);

    if ([path isEqualToString:@"/delete"]&&[method isEqualToString:@"POST"]) {
//        XC_DebugLog(@"🍌🍌🍌%@",deleteFileName);
        return YES;
    }
    
    // Inform HTTP server that we expect a body to accompany a POST request
    if([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }
        
        // enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    HTTPLogTrace();
//    XC_DebugLog(@"🍎-- %@ %@",method,path);
    
    if ([path isEqualToString:@"/delete"]&&[method isEqualToString:@"POST"]) {
//        XC_DebugLog(@"🍌🍌🍌%@",deleteFileName);

        NSString *fileName = [self webHttp_DeleteFile:deleteFileName];
        
        NSString *decodeFileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        NSString *newfilename = [fileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *newdecodeFileName = [decodeFileName stringByReplacingOccurrencesOfString:@"+" withString:@" "];

//        XC_DebugLog(@"%@----=========----%@",decodeFileName,newfilename);
        
        NSMutableArray *muArr = [NSMutableArray array];
        NSMutableDictionary *mudic = [NSMutableDictionary dictionary];
        [mudic setValue:fileName forKey:@"path"];
        [mudic setValue:fileName forKey:@"name"];
        [mudic setValue:@([self fileSizeAtPath:[NSString stringWithFormat:@"%@/%@",Documets_Path,fileName]]) forKey:@"size"];
        [muArr addObject:mudic];
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:muArr options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSData *data1 = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        

        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",Documets_Path,newdecodeFileName] error:nil];
//        XC_DebugLog(@"b=================%d",b);
        return [[HTTPDataResponse alloc] initWithData:data1];

    }
    
    if ([method isEqualToString:@"GET"]&&[path isEqualToString:@"/list?path=%2F"]) {

        
        NSArray *array = [self getlocal_DirectoryContentswithdir:Documets_Path];
        NSMutableArray *muArr = [NSMutableArray array];
        for (NSString *fileName in array) {
            NSMutableDictionary *mudic = [NSMutableDictionary dictionary];
            [mudic setValue:fileName forKey:@"path"];
            [mudic setValue:fileName forKey:@"name"];
            [mudic setValue:@([self fileSizeAtPath:[NSString stringWithFormat:@"%@/%@",Documets_Path,fileName]]) forKey:@"size"];
            [muArr addObject:mudic];
        }
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:muArr options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        NSData *data1 = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        return [[HTTPDataResponse alloc] initWithData:data1];
        
    }
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload"])
    {
        
        NSString *fileName = [[uploadedFiles lastObject] lastPathComponent];
        NSMutableArray *muArr = [NSMutableArray array];
        NSMutableDictionary *mudic = [NSMutableDictionary dictionary];
        [mudic setValue:fileName forKey:@"path"];
        [mudic setValue:fileName forKey:@"name"];
        [mudic setValue:@([self fileSizeAtPath:[NSString stringWithFormat:@"%@/%@",Documets_Path,fileName]]) forKey:@"size"];
        [muArr addObject:mudic];
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:muArr options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSData *data1 = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        return [[HTTPDataResponse alloc] initWithData:data1];

        
    }
    if ([method isEqualToString:@"GET"]&&[path hasPrefix:@"/"]) {
        
    }
    if( [method isEqualToString:@"GET"] && [path hasPrefix:@"/upload/"] ) {
        // let download the uploaded files
//        return [[HTTPFileResponse alloc] initWithFilePath: [[config documentRoot] stringByAppendingString:path] forConnection:self];
//        XCLog(@"不让下载呢");
        return nil;
    }
    
    return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    HTTPLogTrace();
    // set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    parser.delegate = self;
    
    uploadedFiles = [[NSMutableArray alloc] init];
}

- (void)processBodyData:(NSData *)postDataChunk
{
    HTTPLogTrace();
    // append data to the parser. It will invoke callbacks to let us handle
    // parsed data.
    [parser appendData:postDataChunk];
    NSString *str = [[NSString alloc] initWithData:postDataChunk encoding:NSUTF8StringEncoding];
    deleteFileName = str;
    
}


//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
    // in this sample, we are not interested in parts, other then file parts.
    // check content disposition to find out filename
    
    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
        
    NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];
    
    if ( (nil == filename) || [filename isEqualToString: @""] ) {
        // it's either not a file part, or
        // an empty form sent. we won't handle it.
        return;
    }
//    NSString* uploadDirPath = [[config documentRoot] stringByAppendingPathComponent:@"upload"];
    NSString *uploadDirPath = Documets_Path;

    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager]fileExistsAtPath:uploadDirPath isDirectory:&isDir ]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString* filePath = [uploadDirPath stringByAppendingPathComponent: filename];
    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {//如果没有就创建文件夹下面接收
        storeFile = nil;
    }
    else {
//        HTTPLogVerbose(@"Saving file to %@", filePath);
        if(![[NSFileManager defaultManager] createDirectoryAtPath:uploadDirPath withIntermediateDirectories:true attributes:nil error:nil]) {
//            HTTPLogError(@"Could not create directory at path: %@", filePath);
        }
        if(![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
//            HTTPLogError(@"Could not create file at path: %@", filePath);
        }
        storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
//        [uploadedFiles addObject: [NSString stringWithFormat:@"/upload/%@", filename]];
        [uploadedFiles addObject:[NSString stringWithFormat:@"%@/%@",Documets_Path,filename]];
    }
}


- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header
{
    // here we just write the output from parser to the file.
    if( storeFile ) {
        [storeFile writeData:data];
    }
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
    // as the file part is over, we close the file.
    [storeFile closeFile];
    storeFile = nil;
}

- (void) processPreambleData:(NSData*) data 
{
    // if we are interested in preamble data, we could process it here.
    
}

- (void) processEpilogueData:(NSData*) data 
{
    // if we are interested in epilogue data, we could process it here.
    
}
- (double) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
- (NSString *)webHttp_DeleteFile:(NSString *)string{
    NSArray *subarr1 = [string componentsSeparatedByString:@"="];
    NSMutableString *muStr = [[NSMutableString alloc] init];
    for (int i=1; i<subarr1.count; i++) {
        [muStr appendString:subarr1[i]];
    }
    return muStr;
}
#pragma mark - 获取文件目录下的所有文件名
- (NSArray *)getlocal_DirectoryContentswithdir:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];
    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:contents];
    [mutableArray removeObject:@".DS_Store"];
    return mutableArray;
}


@end
