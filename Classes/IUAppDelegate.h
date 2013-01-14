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

#import <Cocoa/Cocoa.h>
#import "DDHotKeyCenter.h"
#import "IUDropView.h"
#import "IUWindowController.h"

@interface IUAppDelegate : NSObject <NSApplicationDelegate>
{
    NSStatusItem *item;
    IUDropView* dropView;
    IBOutlet NSMenu* menu;
    IBOutlet NSMenuItem* recentUploads;
    IBOutlet NSMenuItem* saveLocal;
    //IBOutlet NSMenuItem* onOpen;
    NSMutableArray* history;
    NSDictionary* preferencesArray;
    
    DDHotKeyCenter* hotkeyCenter;
    
    IUWindowController* allUploads;
    BOOL keepFile;
}

//@interface Controller : NSObject
//{
//    
//}

@property (nonatomic) NSDictionary* preferencesArray;
@property (readonly) NSArray* history;
@property (readonly) NSMenuItem* recentUploads;
@property (readonly) NSMenuItem* saveLocal;
@property (readwrite, strong) IUWindowController* allUploads;

-(IBAction)onAbout:(NSMenuItem*)sender;
-(IBAction)onPreferences:(NSMenuItem*)sender;
-(IBAction)onUploadClipboard:(NSMenuItem *)sender;
-(IBAction)onAllUploads:(NSMenuItem*)sender;
-(IBAction)onSave:(NSMenuItem*)sender;
-(IBAction)onQuit:(NSMenuItem*)sender;
-(IBAction)onOpenDir:(NSMenuItem*)sender;

-(void)addImage:(NSString*)file withImgurUrl:(NSString*)url;
-(NSString*)getFileName;
-(NSString *)applicationSupportDirectory;
-(NSString*)imagePath:(NSString*)filename;

-(void)uploadScreenshot:(NSEvent*)event;
-(void)uploadSnippedScreenshot:(NSEvent*)event;
-(void)uploadScreenshotWithArguments:(NSArray*)arguments;

//-(void)captureScreenStart:(NSEvent*)event;
//-(void)captureScreenEnd:(NSEvent*)event;
-(void)startFullScreenRecord;
-(void)startSnippitScreenRecord;

@end

#define SIZE 22
#define URL_KEY @"imgur-url"
#define FILE_KEY @"file-path"
