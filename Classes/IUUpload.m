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
#import "IUUpload.h"
#import "NSDataBase64.h"

#define CLIENT_ID @"Client-ID 2cca2597409f0ff"

@interface IUUpload ()
@property (readonly) NSURL *uploadURL;
-(NSURL *)redditURL:(NSString *)url;
@end

@implementation IUUpload

@synthesize files;
@synthesize reddit;

-(id)initWithBlock:(IUUploadCompleteBlock)blk
{
    self = [super init];
    if (self)
    {
        block = [blk copy];
    }
    return self;
}

-(NSURL *)uploadURL
{
    return [NSURL URLWithString:@"https://api.imgur.com/3/upload.xml"];
}

-(NSURL *)redditURL:(NSString *)url
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://www.reddit.com/submit?url=%@", url]];
}

-(void)main
{
    NSLock* lock = [[NSLock alloc] init];
    
    for (NSString* file in files) {
        NSString* imageData = [[NSData dataWithContentsOfFile:file] base64EncodedString];
        CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                      (__bridge CFStringRef)imageData,
                                                                      NULL,
                                                                      (CFStringRef)@";/?:@&=+$",
                                                                      kCFStringEncodingUTF8);
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[self uploadURL]];
        NSString* httpBody = [NSString stringWithFormat:@"image=%@", (__bridge NSString*)escaped];
        [request setHTTPMethod:@"POST"];
        [request addValue:CLIENT_ID forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
        CFRelease(escaped);
        
        // TODO: Make this an asynchronous request
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* responseData = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
        if (!responseData)
        {
            NSLog(@"Upload for %@ failed", file);
            continue;
        }
        if (error)
        {
            [NSApp presentError:error];
            continue;
        }
        
        NSString* xml = [[NSString alloc] initWithData:responseData
                                              encoding:NSUTF8StringEncoding];
        NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml
                                                              options:0
                                                                error:&error];
        if (error)
        {
            [NSApp presentError:error];
            continue;
        }
        
        NSArray* nodes = [doc nodesForXPath:@"/data/link" error:&error];
        if (error)
        {
            [NSApp presentError:error];
            continue;
        }
        
        if ([nodes count] != 1)
        {
            NSLog(@"Wrong number of nodes: %u", (uint) [nodes count]);
			// Do not proceed, this causes a crash.
			return;
        }
        
        NSString *url = [[nodes objectAtIndex:0] stringValue];
        NSLog(@"Received imgur URL: %@", url);
        
        if (reddit)
        {
            [[NSWorkspace sharedWorkspace] openURL:[self redditURL:url]];
        }
        else
        {
            NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType]
                               owner:nil];
            [pasteboard setString:url forType:NSStringPboardType];
        }
        
        // Notify that the upload is finished
        [[NSSound soundNamed:@"Glass"] play];
        
        // Keep track of images we've uploaded
        [lock lock];
        [[NSApp delegate] addImage:file withImgurUrl:url];
        [lock unlock];
        
        if (block)
        {
            block(self);
        }
    }
}

@end
