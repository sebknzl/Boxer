/* 
 Copyright (c) 2013 Alun Bestor and contributors. All rights reserved.
 This source file is released under the GNU General Public License 2.0. A full copy of this license
 can be found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */

#import "BXBinCueImage.h"
#import "BXISOImagePrivate.h"
#import "RegexKitLite.h"


//Matches the following lines with optional leading and trailing whitespace:
//FILE MAX.gog BINARY
//FILE "MAX.gog" BINARY
//FILE "Armin van Buuren - A State of Trance 179 (16-12-2004) Part2.wav" WAV
//FILE 01_armin_van_buuren_-_in_the_mix_(asot179)-cable-12-16-2004-hsalive.mp3 MP3
NSString * const BXCueFileDescriptorSyntax = @"FILE\\s+(?:\"(.+)\"|(\\S+))\\s+[A-Z]+";

//The maximum size in bytes that a cue file is expected to be, before we consider it not a cue file.
//This is used as a sanity check by +isCueAtPath: to avoid scanning large files unnecessarily.
#define BXCueMaxFileSize 10240


@implementation BXBinCueImage


#pragma mark -
#pragma mark Helper class methods

+ (NSArray *) rawPathsInCueContents: (NSString *)cueContents
{
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity: 1];
	
	NSRange usefulComponents = NSMakeRange(1, 2);
	NSArray *matches = [cueContents arrayOfCaptureComponentsMatchedByRegex: BXCueFileDescriptorSyntax];
	
	for (NSArray *components in matches)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSString *fileName in [components subarrayWithRange: usefulComponents])
		{
			if (fileName.length)
			{
                //Normalize escaped quotes
                NSString *normalizedName = [fileName stringByReplacingOccurrencesOfString: @"\\\"" withString: @"\""];
				[paths addObject: normalizedName];
				break;
			}
		}
		[pool release];
	}
	
	return paths;
}

+ (NSArray *) rawPathsInCueAtPath: (NSString *)cuePath error: (NSError **)outError
{
    NSString *cueContents = [[NSString alloc] initWithContentsOfFile: cuePath
                                                        usedEncoding: NULL
                                                               error: outError];
	
    if (!cueContents) return nil;
    
    NSArray *paths = [self rawPathsInCueContents: cueContents];
    [cueContents release];
    
    return paths;
}

+ (NSArray *) resourcePathsInCueAtPath: (NSString *)cuePath error: (NSError **)outError
{
    NSArray *rawPaths = [self rawPathsInCueAtPath: cuePath error: outError];
    if (!rawPaths) return nil;
    
    //The path relative to which we will resolve the paths in the CUE
    NSString *basePath = [cuePath stringByDeletingLastPathComponent];
    
    NSMutableArray *resolvedPaths = [NSMutableArray arrayWithCapacity: [rawPaths count]];
    for (NSString *rawPath in rawPaths)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        //Rewrite Windows-style paths
        NSString *normalizedPath = [rawPath stringByReplacingOccurrencesOfString: @"\\" withString: @"/"];
        
        //Form an absolute path with all symlinks and ../ components fully resolved.
        NSString *resolvedPath	= [[basePath stringByAppendingPathComponent: normalizedPath] stringByStandardizingPath];
        
        [resolvedPaths addObject: resolvedPath];
        
        [pool drain];
    }
    return resolvedPaths;
}

+ (NSString *) binPathInCueAtPath: (NSString *)cuePath error: (NSError **)outError
{
    NSArray *resolvedPaths = [self resourcePathsInCueAtPath: cuePath error: outError];
    if (![resolvedPaths count]) return nil;
    
    //Assume the first entry in the CUE file is always the binary image.
    //(This is not always true, and we should do more in-depth scanning.)
    return [resolvedPaths objectAtIndex: 0];
}

+ (BOOL) isCueAtPath: (NSString *)cuePath error: (NSError **)outError
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDir, exists = [manager fileExistsAtPath: cuePath isDirectory: &isDir];
    //TODO: populate outError
    if (!exists || isDir) return NO;
    
    unsigned long long fileSize = [[manager attributesOfItemAtPath: cuePath error: outError] fileSize];
    
    //If the file is too large, assume it can't be a file and bail out
    if (!fileSize ||  fileSize > BXCueMaxFileSize) return NO;
    
    //Otherwise, load it in and see if it appears to contain any usable paths
    NSString *cueContents = [[NSString alloc] initWithContentsOfFile: cuePath
                                                        usedEncoding: NULL
                                                               error: outError];
    
    if (!cueContents) return NO;
    
    BOOL isCue = [cueContents isMatchedByRegex: BXCueFileDescriptorSyntax];
    [cueContents release];
    return isCue;
}


- (id) init
{
    if ((self = [super init]))
    {
        rawSectorSize = BXBINCUERawSectorSize;
        leadInSize = BXBINCUELeadInSize;
    }
    return self;
}
@end
