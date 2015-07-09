/*
 Copyright (c) 2011, Spotify AB
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Spotify AB nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SPOTIFY AB BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppDelegate.h"
#include "appkey.c"
#import <TagLib/taglib.h>
#import <TagLib/fileref.h>
#import <TagLib/tag.h>
#import "NSString+Encoded.h"

@implementation AppDelegate

@synthesize window = _window;

@synthesize userNameField;
@synthesize passwordField;
@synthesize loginSheet;
@synthesize trackTable;
@synthesize trackArrayController;
@synthesize playbackManager;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {

	[self willChangeValueForKey:@"session"];
	NSError *error = nil;
	[SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
											   userAgent:@"com.ryanburke.applefy"
										   loadingPolicy:SPAsyncLoadingImmediate
												   error:&error];
	if (error != nil) {
		NSLog(@"CocoaLibSpotify init failed: %@", error);
		abort();
	}

	[[SPSession sharedSession] setDelegate:self];
	self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];

	[self didChangeValueForKey:@"session"];
	[self.window center];
	[self.window orderFront:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	[self.trackTable setTarget:self];
	[self performSelector:@selector(showLoginSheet) withObject:nil afterDelay:0.0];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([SPSession sharedSession].connectionState == SP_CONNECTION_STATE_LOGGED_OUT ||
		[SPSession sharedSession].connectionState == SP_CONNECTION_STATE_UNDEFINED) 
		return NSTerminateNow;
	
	[[SPSession sharedSession] logout:^{
		[[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
	}];
	return NSTerminateLater;
}

-(void)showLoginSheet {
	[NSApp beginSheet:self.loginSheet
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil 
		  contextInfo:nil];
}

-(SPSession *)session {
	// For bindings
	return [SPSession sharedSession];
}

- (IBAction)quitFromLoginSheet:(id)sender {
	
	// Invoked by clicking the "Quit" button in the UI.
	
	[NSApp endSheet:self.loginSheet];
	[NSApp terminate:self];
}

- (IBAction)login:(id)sender {
	
	// Invoked by clicking the "Login" button in the UI.
	if ([[userNameField stringValue] length] > 0 &&
		[[passwordField stringValue] length] > 0) {
		
		[[SPSession sharedSession] attemptLoginWithUserName:[userNameField stringValue]
												   password:[passwordField stringValue]];
	} else {
		NSBeep();
	}
}

#pragma mark -
#pragma mark SPSessionDelegate Methods

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
	// Invoked by SPSession after a successful login.
	[self.loginSheet orderOut:self];
	[NSApp endSheet:self.loginSheet];
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
	// Invoked by SPSession after a failed login.
    [NSApp presentError:error
         modalForWindow:self.loginSheet
               delegate:nil
     didPresentSelector:nil
            contextInfo:nil];
}

-(void)sessionDidLogOut:(SPSession *)aSession; {}
-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
	[[NSAlert alertWithMessageText:aMessage
					 defaultButton:@"OK"
				   alternateButton:@""
					   otherButton:@""
		 informativeTextWithFormat:@"This message was sent to you from the Spotify service."] runModal];
}

#pragma mark -
#pragma mark Saving

- (IBAction)savePlaylist:(id)sender {
    
    [self.saveButton setEnabled:NO];
    
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *path = [NSString stringWithFormat:@"%@/Applefy/%@", NSHomeDirectory(), [self.playlistButton.titleOfSelectedItem URLEncodedString_ch]];
    
    if(![fileManager fileExistsAtPath:path isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", path);

    NSURL *emptyMP3Path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/5sec.mp3", [[NSBundle mainBundle] resourcePath]]];
    
    for (SPPlaylistItem *item in self.trackArrayController.arrangedObjects) {
        
        SPTrack *track = item.item;
        
        NSString *title = track.name;
        NSString *fileName = [title URLEncodedString_ch];
        NSString *artist = [[[track artists] objectAtIndex:0] name];
        NSString *album = track.album.name;
        NSUInteger year = track.album.year;
        NSUInteger num_track = track.trackNumber;
        
        NSURL *fileMP3 = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.mp3", path, fileName]];
        [[NSFileManager defaultManager] copyItemAtURL:emptyMP3Path toURL:fileMP3 error:nil];
        
        TagLib::FileRef f([[fileMP3 path] cStringUsingEncoding:NSUTF8StringEncoding]);
        f.tag()->setTitle([title cStringUsingEncoding:NSUTF8StringEncoding]);
        f.tag()->setArtist([artist cStringUsingEncoding:NSUTF8StringEncoding]);
        f.tag()->setAlbum([album cStringUsingEncoding:NSUTF8StringEncoding]);
        f.tag()->setTrack((int)num_track);
        f.tag()->setYear((int)year);
        f.save();

    }
    
    [self.saveButton setEnabled:YES];
    
    
}

@end
