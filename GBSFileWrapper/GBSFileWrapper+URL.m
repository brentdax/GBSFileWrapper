//
//  GBSFileWrapper+URL.m
//  GBSFileWrapper
//
//  Created by Brent Royal-Gordon on 9/26/13.
//  Copyright (c) 2013 Groundbreaking Software. All rights reserved.
//

#import "GBSFileWrapper+URL.h"
#import "GBSFileWrapper+NSFileWrapper.h"

NSString * const GBSFileWrapperURLInvalidException = @"GBSFileWrapperURLInvalid";
#define GBSAssertSucceeded(operation, error) if(!(operation)) { \
@throw [NSException exceptionWithName:GBSFileWrapperURLInvalidException reason:[NSString stringWithFormat:@"The file at %@ cannot be accessed: %@.", self.URL.absoluteString, error.localizedDescription] userInfo:@{ @"NSError": error }]; \
}

@interface GBSFileWrapperURLDataSource : NSObject <GBSFileWrapperDataSource>

@property NSURL * URL;
@property BOOL withoutMapping;

- (id)initWithURL:(NSURL*)URL withoutMapping:(BOOL)mapping;

@end

@implementation GBSFileWrapper (URL)

- (id)initWithURL:(NSURL *)URL options:(GBSFileWrapperReadingOptions)options error:(NSError *__autoreleasing *)error {
    if(![URL checkResourceIsReachableAndReturnError:error]) {
        return nil;
    }
    
    GBSFileWrapperURLDataSource * dataSource = [[GBSFileWrapperURLDataSource alloc] initWithURL:URL withoutMapping:(options & GBSFileWrapperReadingWithoutMapping)];
    
    if((self = [self initWithDataSource:dataSource])) {
        if(options & GBSFileWrapperReadingImmediate) {
            @try {
                [self loadContents];
            }
            @catch (NSException *exception) {
                if(![exception.name isEqualToString:GBSFileWrapperURLInvalidException]) {
                    @throw;
                }
                
                if(error) {
                    *error = exception.userInfo[@"NSError"];
                }
                return nil;
            }
        }
    }
    
    return self;
}

- (void)loadContents {
    [self contents];
    
    if(self.type == GBSFileWrapperTypeDirectory) {
        for(GBSFileWrapper * wrapper in [self.contents allValues]) {
            [wrapper loadContents];
        }
    }
}

- (BOOL)writeToURL:(NSURL *)URL options:(GBSFileWrapperWritingOptions)options error:(NSError *__autoreleasing *)error {
    NSFileWrapper * wrapper = [self NSFileWrapper];
    return [wrapper writeToURL:URL options:(NSFileWrapperWritingOptions)options originalContentsURL:nil error:error];
}

@end

@implementation GBSFileWrapperURLDataSource

- (id)initWithURL:(NSURL *)URL withoutMapping:(BOOL)mapping {
    if((self = [super init])) {
        _URL = URL;
        _withoutMapping = mapping;
    }
    return self;
}

- (GBSFileWrapperType)typeForFileWrapper:(GBSFileWrapper *)fileWrapper {
    NSError * error;
    NSString * type;
    
    GBSAssertSucceeded([self.URL getResourceValue:&type forKey:NSURLFileResourceTypeKey error:&error], error);
    
    return [@{ NSURLFileResourceTypeDirectory: @(GBSFileWrapperTypeDirectory), NSURLFileResourceTypeRegular: @(GBSFileWrapperTypeRegularFile), NSURLFileResourceTypeSymbolicLink: @(GBSFileWrapperTypeSymbolicLink) }[type] integerValue];
}

- (GBSFileWrapperMemoryDataSource*)substituteIntoFileWrapper:(GBSFileWrapper*)fileWrapper withContents:(id <GBSFileWrapperContents>)contents {
    GBSFileWrapperMemoryDataSource * dataSource = [[GBSFileWrapperMemoryDataSource alloc] initWithContents:contents];
    
    [fileWrapper substituteEquivalentDataSource:dataSource];
    
    return dataSource;
}

- (NSData *)regularFileContentsForFileWrapper:(GBSFileWrapper *)fileWrapper {
    NSDataReadingOptions options = self.withoutMapping ? 0 : NSDataReadingMappedIfSafe;
    NSError * error;
    NSData * data = [[NSData alloc] initWithContentsOfURL:self.URL options:options error:&error];
    
    GBSAssertSucceeded(data, error);
        
    return [[self substituteIntoFileWrapper:fileWrapper withContents:data] regularFileContentsForFileWrapper:fileWrapper];
}

- (NSDictionary *)directoryContentsForFileWrapper:(GBSFileWrapper *)fileWrapper {
    NSMutableDictionary * contents = [NSMutableDictionary new];
    
    __block BOOL ok = YES;
    __block NSError * error;
    
    for(NSURL * childURL in [[NSFileManager new] enumeratorAtURL:self.URL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:^BOOL(NSURL *url, NSError *inError) {
        ok = NO;
        error = inError;
        return NO;
    }]) {
        GBSFileWrapper * wrapper = [(GBSFileWrapper*)[fileWrapper.class alloc] initWithURL:childURL options:self.withoutMapping ? GBSFileWrapperReadingWithoutMapping : 0 error:&error];
        
        if(wrapper) {
            contents[childURL.lastPathComponent] = wrapper;
        }
        else {
            ok = NO;
            break;
        }
    }
    
    GBSAssertSucceeded(ok, error);
    
    return [[self substituteIntoFileWrapper:fileWrapper withContents:contents] directoryContentsForFileWrapper:fileWrapper];
}

- (NSURL *)symbolicLinkContentsForFileWrapper:(GBSFileWrapper *)fileWrapper {
    NSError * error;
    NSString * path = [[NSFileManager new] destinationOfSymbolicLinkAtPath:self.URL.path error:&error];
    
    GBSAssertSucceeded(path, error);
    
    NSURL * url = [NSURL URLWithString:path relativeToURL:self.URL];
    
    return [[self substituteIntoFileWrapper:fileWrapper withContents:url] symbolicLinkContentsForFileWrapper:fileWrapper];
}

- (id<GBSFileWrapperDataSource>)copyFromFileWrapper:(GBSFileWrapper *)fileWrapper {
    return [[GBSFileWrapperURLDataSource alloc] initWithURL:self.URL withoutMapping:self.withoutMapping];
}

- (void)setNilContentsForFileWrapper:(GBSFileWrapper *)fileWrapper {
    [self substituteIntoFileWrapper:fileWrapper withContents:nil];
}

- (void)setRegularFileContents:(NSData *)contents forFileWrapper:(GBSFileWrapper *)fileWrapper {
    [self substituteIntoFileWrapper:fileWrapper withContents:contents];
}

- (void)setSymbolicLinkContents:(NSURL *)contents forFileWrapper:(GBSFileWrapper *)fileWrapper {
    contents = [NSURL URLWithString:contents.relativePath relativeToURL:self.URL];
    [self substituteIntoFileWrapper:fileWrapper withContents:contents];
}

- (void)makeDirectoryContentsForFileWrapper:(GBSFileWrapper *)fileWrapper {
    [self substituteIntoFileWrapper:fileWrapper withContents:@{}];
}

- (void)addDirectoryContents:(NSDictionary *)dictionaryOfNamesAndFileWrappersOrNulls {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)removeAllDirectoryContents {
    [self doesNotRecognizeSelector:_cmd];
}

@end
