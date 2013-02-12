/* 
 Copyright (c) 2013 Alun Bestor and contributors. All rights reserved.
 This source file is released under the GNU General Public License 2.0. A full copy of this license
 can be found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */

#import "BXImageAwareFileScan.h"
#import "NSWorkspace+BXMountedVolumes.h"
#import "NSWorkspace+BXFileTypes.h"
#import "BXFileTypes.h"


@implementation BXImageAwareFileScan
@synthesize mountedVolumePath = _mountedVolumePath;
@synthesize ejectAfterScanning = _ejectAfterScanning;
@synthesize didMountVolume = _didMountVolume;

- (id) init
{
    if ((self = [super init]))
    {
        self.ejectAfterScanning = BXFileScanEjectIfSelfMounted;
    }
    return self;
}

- (void) dealloc
{
    self.mountedVolumePath = nil;
    
    [super dealloc];
}

- (NSString *) fullPathFromRelativePath: (NSString *)relativePath
{
    //Return paths relative to the mounted volume instead, if available.
    NSString *filesystemRoot = (self.mountedVolumePath) ? self.mountedVolumePath : self.basePath;
    return [filesystemRoot stringByAppendingPathComponent: relativePath];
}

//If we have a mounted volume path for an image, enumerate that instead of the original base path
- (id <BXFilesystemEnumeration>) enumerator
{
    if (self.mountedVolumePath)
        return (id <BXFilesystemEnumeration>)[_manager enumeratorAtPath: self.mountedVolumePath];
    else return [super enumerator];
}

- (void) willPerformOperation
{
    NSString *volumePath = nil;
    _didMountVolume = NO;
    
    //If the target path is on a disk image, then mount the image for scanning
    if ([_workspace file: self.basePath matchesTypes: [NSSet setWithObject: @"public.disk-image"]])
    {
        //First, check if the image is already mounted
        volumePath = [_workspace volumeForSourceImage: self.basePath];
        
        //If it's not mounted yet, mount it ourselves
        if (!volumePath)
        {
            NSError *mountError = nil;
            volumePath = [_workspace mountImageAtPath: self.basePath
                                             readOnly: YES
                                            invisibly: YES
                                                error: &mountError];
            
            //If we couldn't mount the image, give up in failure
            if (!volumePath)
            {
                self.error = mountError;
                return;
            }
            else _didMountVolume = YES;
        }
        
        self.mountedVolumePath = volumePath;
    }    
}

- (void) didPerformOperation
{
    //If we mounted a volume ourselves in order to scan it,
    //or we've been told to always eject, then unmount the volume
    //once we're done
    if (self.mountedVolumePath)
    {
        if ((self.ejectAfterScanning == BXFileScanAlwaysEject) ||
            (_didMountVolume && self.ejectAfterScanning == BXFileScanEjectIfSelfMounted))
        {
            [_workspace unmountAndEjectDeviceAtPath: self.mountedVolumePath];
            self.mountedVolumePath = nil;
        }
    }    
}

@end
