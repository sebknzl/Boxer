/* 
 Boxer is copyright 2010 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXFilterGallery.h"
#import "NSView+BXDrawing.h"
#import <QuartzCore/QuartzCore.h>

@implementation BXFilterGallery
- (void) drawRect: (NSRect)dirtyRect
{
	NSImage *wallpaper	= [NSImage imageNamed: @"GalleryBkg.jpg"];
	NSColor *pattern	= [NSColor colorWithPatternImage: wallpaper];
	
	NSSize patternSize	= [wallpaper size];
	NSSize viewSize		= [self bounds].size;
	NSPoint patternOffset	= [self offsetFromWindowOrigin];
	
	NSPoint patternPhase = NSMakePoint(
		//Center the pattern horizontally
		patternOffset.x + ((viewSize.width - patternSize.width) / 2),
		//Lock the pattern to the bottom of the view
		patternOffset.y + 1.0f
	);

	//Also add a bevel line at the bottom of the view
	NSColor *bevelColor = [NSColor whiteColor];
	NSRect bevelRect = [self bounds];
	bevelRect.size.height = 1.0f;
	
	//Fill the view with the background pattern and draw the bevel
	[NSGraphicsContext saveGraphicsState];
		[pattern set];
		[[NSGraphicsContext currentContext] setPatternPhase: patternPhase];
		[NSBezierPath fillRect: dirtyRect];
	
		//Don't bother drawing the bevel if it's not dirty
		if (NSIntersectsRect(dirtyRect, bevelRect))
		{
			[bevelColor set];
			[NSBezierPath fillRect: bevelRect];
		}
	[NSGraphicsContext restoreGraphicsState];	
}
@end

@implementation BXFilterPortrait
@synthesize illumination;

+ (id)defaultAnimationForKey: (NSString *)key
{
    if ([key isEqualToString: @"illumination"])
		return [CABasicAnimation animation];

    return [super defaultAnimationForKey:key];
}

- (void) setState: (NSInteger)value
{
	[super setState: value];
	if (value)	[[self animator] setIllumination: 1.0f];
	else		[[self animator] setIllumination: 0.0f];
}

- (void) setIllumination: (CGFloat)newValue
{
	illumination = newValue;
	[self setNeedsDisplay: YES];
}
@end

@implementation BXFilterPortraitCell

- (void) awakeFromNib
{
	//Prevent the portrait from darkening when pressed in.
	[self setHighlightsBy: NSNoCellMask];
}

- (NSAttributedString *) attributedTitle
{
	NSFont *font;
	NSColor *textColor;
	
	//Render the text in white if this button is selected
	textColor = ([self state]) ? [NSColor whiteColor] : [NSColor lightGrayColor];
	//Render the text in bold if this button is selected or the user is pressing the button
	font = ([self state] || [self isHighlighted]) ? [NSFont boldSystemFontOfSize: 0] : [NSFont systemFontOfSize: 0];
	
	NSShadow *textShadow = [[NSShadow new] autorelease];	
	[textShadow setShadowOffset: NSMakeSize(0.0f, -1.0f)];
	[textShadow setShadowBlurRadius: 2.0f];
	[textShadow setShadowColor: [NSColor blackColor]];
	
	NSMutableAttributedString *title = [[super attributedTitle] mutableCopy];
	NSRange textRange = NSMakeRange(0, [title length]);
	
	[title addAttribute: NSFontAttributeName value: font range: textRange];
	[title addAttribute: NSForegroundColorAttributeName value: textColor range: textRange];
	[title addAttribute: NSShadowAttributeName value: textShadow range: textRange];
	
	return [title autorelease];
}

- (NSRect) titleRectForBounds: (NSRect)theRect
{
	//Position the title to occupy the bottom quarter of the button.
	theRect.origin.y = 72.0f;
	return theRect;
}

- (void) drawWithFrame: (NSRect)frame inView: (BXFilterPortrait *)controlView
{
	if ([controlView illumination] > 0.0f)
	{
		NSImage *spotlight = [NSImage imageNamed: @"GallerySpotlight.png"];
		[spotlight setFlipped: [controlView isFlipped]];
		[spotlight drawInRect: frame
					 fromRect: NSZeroRect
					operation: NSCompositePlusLighter
					 fraction: [controlView illumination]];
	}
	[super drawWithFrame: frame inView: controlView];
}

- (void) drawImage: (NSImage *)image	
		 withFrame: (NSRect)frame 
			inView: (BXFilterPortrait *)controlView
{
	if ([controlView illumination] < 0.9)
	{
		CGFloat shadeLevel = (1.0f - [controlView illumination]) * 0.25f;
		NSColor *shade = [NSColor colorWithCalibratedWhite: 0.0f alpha: shadeLevel];
		
		image = [[image copy] autorelease];
		[image lockFocus];
			[NSGraphicsContext saveGraphicsState];
				[[NSGraphicsContext currentContext] setCompositingOperation: NSCompositeSourceAtop];
				[shade set];
				[NSBezierPath fillRect: frame];
			[NSGraphicsContext restoreGraphicsState];
		[image unlockFocus];
	}
	[super drawImage: image withFrame: frame inView: controlView];
}

@end
