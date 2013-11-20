//
//  NSObject+GBSFileWrapperContent.m
//  GBSFileWrapper
//
//  Created by Brent Royal-Gordon on 9/26/13.
//  Copyright (c) 2013 Groundbreaking Software. All rights reserved.
//

#import "GBSFileWrapperContents.h"

@implementation NSData (GBSFileWrapperContents)

- (GBSFileWrapperType)typeForFileWrapper:(GBSFileWrapper*)fileWrapper {
    return GBSFileWrapperTypeRegularFile;
}

@end

@implementation NSDictionary (GBSFileWrapperContents)

- (GBSFileWrapperType)typeForFileWrapper:(GBSFileWrapper*)fileWrapper {
    return GBSFileWrapperTypeDirectory;
}

@end

@implementation NSURL (GBSFileWrapperContents)

- (GBSFileWrapperType)typeForFileWrapper:(GBSFileWrapper*)fileWrapper {
    return GBSFileWrapperTypeSymbolicLink;
}

@end

#import "NSDictionary+subdictionaryWithKeys.h"

@implementation NSDictionary (GBSFileWrapperResourceValues)

- (NSDictionary *)resourceValuesForKeys:(NSArray *)keys {
    return [self subdictionaryWithKeys:keys notFoundKeys:NULL];
}

- (id<GBSFileWrapperResourceValues>)copyFromFileWrapper:(GBSFileWrapper *)fileWrapper {
    return [self copy];
}

@end
