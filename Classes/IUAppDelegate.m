// Copyright (c) 2010-2011, Nate Stedman <natesm@gmail.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#import "IUAppDelegate.h"
#import "IUStatusItem.h"
#import "IUDropView.h"
#import "IUUpload.h"

#define THUMB_SIZE 100

#define JPEG_KEYS [NSArray arrayWithObjects:NSImageCompressionFactor, nil]
#define JPEG_OBJECTS [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.9f],\
                                               nil]
#define JPEG_PROPERTIES [NSDictionary dictionaryWithObjects:JPEG_OBJECTS \
                                                    forKeys:JPEG_KEYS]

#define HISTORY_FILE [NSString stringWithFormat:@"%@/history.plist", \
                      [self applicationSupportDirectory]]

#define PREF_FILE [NSString stringWithFormat:@"%@/pref.plist", \
                    [self applicationSupportDirectory]]

#define LOCAL_COPY [NSString stringWithFormat:@"%@/SavedImages", \
                    [self applicationSupportDirectory]]

@implementation IUAppDelegate

@synthesize preferencesArray;
@synthesize history;
@synthesize recentUploads;
@synthesize allUploads;
@synthesize saveLocal;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // random seed
    srand(time(NULL));
    
    // create a drop view
    dropView = [[IUDropView alloc] initWithFrame:
                NSMakeRect(0, 0, SIZE, SIZE)];
    
    item = IUStatusItemWithViewAndMenu(dropView, menu);
    
    // load the old history
    if ([[NSFileManager defaultManager] fileExistsAtPath:HISTORY_FILE] == YES) {
        history = [NSMutableArray arrayWithContentsOfFile:HISTORY_FILE];
    }
    // or create a new array if it isn't there
    else {
        history = [[NSMutableArray alloc] init];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:PREF_FILE] == YES) {
        preferencesArray = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
        keepFile = [[preferencesArray objectForKey:@"save"] boolValue];
        if (keepFile)
        {
            [saveLocal setState:NSOnState];
        }
        else
        {
            [saveLocal setState:NSOffState];
        }
    }
    else {
        preferencesArray = [[NSDictionary alloc] init];
    }
    
    
    // register global hotkeys
    hotkeyCenter = [[DDHotKeyCenter alloc] init];
    [hotkeyCenter registerHotKeyWithKeyCode:18
                              modifierFlags:NSCommandKeyMask | NSShiftKeyMask
                                     target:self
                                     action:@selector(uploadScreenshot:)
                                     object:nil];
    
    hotkeyCenter = [[DDHotKeyCenter alloc] init];
    [hotkeyCenter registerHotKeyWithKeyCode:19
                              modifierFlags:NSCommandKeyMask | NSShiftKeyMask
                                     target:self
                                     action:@selector(uploadSnippedScreenshot:)
                                     object:nil];
    
    //For full screen recording 
    hotkeyCenter = [[DDHotKeyCenter alloc] init];
    [hotkeyCenter registerHotKeyWithKeyCode:22
                              modifierFlags:NSCommandKeyMask | NSShiftKeyMask
                                     target:self
                                     action:@selector(recordFullScreen:)
                                     object:nil];
    
    //For part of screen recording
    hotkeyCenter = [[DDHotKeyCenter alloc] init];
    [hotkeyCenter registerHotKeyWithKeyCode:23
                              modifierFlags:NSCommandKeyMask | NSShiftKeyMask
                                     target:self
                                     action:@selector(recordScreenSelection:)
                                     object:nil];
    
}

-(IBAction)onAbout:(NSMenuItem*)sender
{
    [NSApp orderFrontStandardAboutPanel:self];
    
    // find the window and set it to the actual front, since we're not a "real" app, that doesn't happen automatically
    for (NSWindow* window in [NSApp windows])
    {
        if ([window isKindOfClass:[NSPanel class]])
        {
            window.level = NSFloatingWindowLevel;
        }
    }
}

-(IBAction)onSave:(NSMenuItem*)sender
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    
    // track the image
    
    if (keepFile)
    {
        keepFile = FALSE;
        [dict setValue:[NSNumber numberWithBool:NO] forKey:@"save"];
        //[dict setValue:[NSNumber numberWithBool:keepFile] forKey:@"save"];
        [saveLocal setState:NSOffState];
    }
    else
    {
        keepFile = TRUE;
        [dict setValue:[NSNumber numberWithBool:YES] forKey:@"save"];
        //[dict setValue:[NSNumber numberWithBool:keepFile] forKey:@"save"];
        [saveLocal setState:NSOnState];
    }
    [dict writeToFile:PREF_FILE atomically:YES];
}

-(IBAction)onOpenDir:(NSMenuItem*)sender
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:LOCAL_COPY] == YES)  {
        [[NSWorkspace sharedWorkspace] openFile:LOCAL_COPY];
    }
}

-(IBAction)onPreferences:(NSMenuItem*)sender
{    
}

-(IBAction)onAllUploads:(NSMenuItem*)sender
{
    if (!allUploads)
    {
        allUploads = [[IUWindowController alloc] initWithImages:history];
    }
    [[allUploads window] makeKeyAndOrderFront:self];
}

-(IBAction)onUploadClipboard:(NSMenuItem *)sender
{
    // write to a temp file
    
    // upload!
    /*IUUpload* upload = [[IUUpload alloc] init];
    [upload setFiles:[NSArray arrayWithObject:file];
    [upload setReddit:commandDown()];
    [[dropView uploads] addOperation:upload];*/
}

-(IBAction)onQuit:(NSMenuItem *)sender
{
    [NSApp terminate:nil];
}

-(void)uploadScreenshot:(NSEvent*)event
{
    [self uploadScreenshotWithArguments:[NSArray array]];
}

-(void)uploadSnippedScreenshot:(NSEvent*)event
{
    [self uploadScreenshotWithArguments:[NSArray arrayWithObject:@"-i"]];
}

-(void)recordFullScreen:(NSEvent*)event
{
    [self startFullScreenRecord];
}

-(void)recordScreenSelection:(NSEvent*)event
{
    [self startSnippitScreenRecord];
}


-(void)startFullScreenRecord
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"StartScreenScript" ofType:@"scpt"];
    NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
    [appleScript executeAndReturnError:nil];
}

-(void)startSnippitScreenRecord
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"RecordSnippit" ofType:@"scpt"];
    NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
    [appleScript executeAndReturnError:nil];

}

-(void)uploadScreenshotWithArguments:(NSArray*)arguments
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* filename;
    do
    {
        filename = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%i", rand()]];
    } while ([fm fileExistsAtPath:filename]);
    
    NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/screencapture"
                                            arguments:[arguments arrayByAddingObject:filename]];
    [task waitUntilExit];
    
    //Gets The time
    
    
    // upload the file
    if ([fm fileExistsAtPath:filename])
    {
        if (keepFile)
        {
            NSError *copyError = nil;
            NSString *permName = [[NSApp delegate] getFileName];
            //Copyies the file
            if(![[NSFileManager defaultManager] copyItemAtPath:filename toPath:permName error:&copyError])
            {
                NSLog(@"Error: %@", copyError);
            }
        }
        IUUpload* upload = [[IUUpload alloc] initWithBlock:^(IUUpload* ul) {
            NSFileManager* fm = [NSFileManager defaultManager];
            for (NSString* file in [ul files])
            {
                NSError* error = nil;
                [fm removeItemAtPath:file error:&error];
                if (error) [NSApp presentError:error];
            }
        }];
        
        upload.files = [NSArray arrayWithObject:filename];
        [dropView.uploads addOperation:upload];
        [dropView uploadStarted];
    }
}

-(NSString*) getFileName
{
    int i = 1;
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDate* now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSHourCalendarUnit  | NSMinuteCalendarUnit |
                                                              NSSecondCalendarUnit) fromDate:now];
    NSInteger hour = [dateComponents hour];
    NSInteger min = [dateComponents minute];
    NSInteger sec = [dateComponents second];
    
    NSDateFormatter *weekdayFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat: @"yyyy MM dd"];
    [weekdayFormatter setDateFormat: @"EEEE"];
    
    NSString *formattedDate = [formatter stringFromDate: now];
    //NSString *weekday = [weekdayFormatter stringFromDate: now];
    
    NSString* path = [NSString stringWithFormat:@"%@/SavedImages/", [[NSApp delegate] applicationSupportDirectory]];
    if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    NSString *temp = @"~/Library/Application Support/Imgup/SavedImages/";
    NSString *filePath = [temp stringByExpandingTildeInPath];
    NSString *date = [NSString stringWithFormat:@"/Snippit %@ %02ld.%02ld.%02ld",formattedDate , hour, min, sec];
    NSString *permName = [filePath stringByAppendingString:date];
              temp = [permName stringByAppendingString:@".png"];
    
    while ([fm fileExistsAtPath:temp])
    {
        temp = [permName stringByAppendingString:[NSString stringWithFormat:@".%i.png", i++]];
    }
    return temp;
}


-(void)addImage:(NSString*)file withImgurUrl:(NSString*)url
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]
                                 initWithCapacity:2];
    
    // track the image
    [dict setValue:[[NSURL URLWithString:url] lastPathComponent]
            forKey:FILE_KEY];
    [dict setValue:url forKey:URL_KEY];
    [history insertObject:dict atIndex:0];
    
    // load the image (locally)
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:file];
    
    // find the size that will fit the image within 100x100
    NSSize origSize = [image size];
    NSSize size = origSize;
    if (size.width > size.height)
    {
        size.height = (size.height / size.width) * THUMB_SIZE;
        size.width = THUMB_SIZE;
    }
    else
    {
        size.width = (size.width / size.height) * THUMB_SIZE;
        size.height = THUMB_SIZE;
    }
    
    // scale down the image
    NSImage* sized = [[NSImage alloc] initWithSize:size];
    [sized lockFocus];
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
             fromRect:NSMakeRect(0, 0, origSize.width, origSize.height)
            operation:NSCompositeSourceOver
             fraction:1.0];
    [sized unlockFocus];
    
    
    // save the thumbnail
    [[NSBitmapImageRep representationOfImageRepsInArray:[[[NSImage alloc]
                                                         initWithData:
                                                         [sized
                                                          TIFFRepresentation]]
                                                         representations]
                                              usingType:NSJPEGFileType
                                             properties:nil]
     writeToFile:[self imagePath:[dict valueForKey:FILE_KEY]] atomically:YES];
    
    // write the plist to a file
    [history writeToFile:HISTORY_FILE atomically:YES];
}

-(NSString*)applicationSupportDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory,
		NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] :
                                               NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Imgup"];
}

-(NSString*)imagePath:(NSString*)filename
{
    // create the thumbnail directory if needed
    NSString* path = [NSString stringWithFormat:@"%@/Thumbnails/",
                      [[NSApp delegate] applicationSupportDirectory]];
    if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    return [NSString stringWithFormat:@"%@%@", path, filename];
}

-(void)growlNotificationWasClicked:(id)clickContext
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[clickContext objectForKey:@"URL"]]];
}

@end
