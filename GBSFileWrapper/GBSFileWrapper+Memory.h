//
//  GBSFileWrapper+Memory.h
//  GBSFileWrapper
//
//  Created by Brent Royal-Gordon on 9/26/13.
//  Copyright (c) 2013 Groundbreaking Software. All rights reserved.
//

#import <GBSFileWrapper/GBSFileWrapper.h>

@interface GBSFileWrapper (Memory)

- (id)initWithContents:(id <GBSFileWrapperContents>)contents resourceValues:(id <GBSFileWrapperResourceValues>)resourceValues;
- (id)init;

@end

@interface GBSFileWrapperMemoryDataSource : NSObject <GBSFileWrapperDataSource>

- (id)initWithContents:(id <GBSFileWrapperContents>)contents;

@end

