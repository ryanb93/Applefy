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
#import "taglib.h"
#import "fileref.h"
#import "tag.h"
#import "NSString+TStringAdditions.h"

@implementation AppDelegate

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
	if ([[self.userNameField stringValue] length] > 0 &&
		[[self.passwordField stringValue] length] > 0) {
		
		[[SPSession sharedSession] attemptLoginWithUserName:[self.userNameField stringValue]
												   password:[self.passwordField stringValue]];
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
    
    [SPAsyncLoading waitUntilLoaded:aSession timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loaded, NSArray *notLoaded) {
        [SPAsyncLoading waitUntilLoaded:aSession.userPlaylists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loaded, NSArray *notLoaded) {
            [self setFlatPlaylists:aSession.userPlaylists.flattenedPlaylists];
            [self.playlistButton setEnabled:YES];
        }];
    }];
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
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *path = [NSString stringWithFormat:@"%@/Applefy/%@", NSHomeDirectory(), [self.playlistButton.titleOfSelectedItem stringByReplacingOccurrencesOfString:@"/" withString:@" "]];

    BOOL isDir;
    if(![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        if(![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL]) {
            NSLog(@"Error: Create folder failed %@", path);
        }
    }

    NSURL *emptyMP3Path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/5sec.mp3", [[NSBundle mainBundle] resourcePath]]];

    NSString *m3uFilePath = [NSString stringWithFormat:@"%@/%@.m3u",  path, [self.playlistButton.titleOfSelectedItem stringByReplacingOccurrencesOfString:@"/" withString:@" "]];
    NSMutableString *m3uList = [[NSMutableString alloc]init];

    int playlistIndex = 0;

    for (SPPlaylistItem *item in self.trackArrayController.arrangedObjects) {
        
        if([item.item isKindOfClass:[SPTrack class]]) {
            
            SPTrack *track = item.item;
            NSString *title = track.name;
            NSString *artist = [[[track artists] objectAtIndex:0] name];
            NSString *album = track.album.name;
            NSUInteger year = track.album.year;
            NSUInteger num_track = track.trackNumber;

            NSString *mp3FilePath = [NSString stringWithFormat:@"%@/%d - %@.mp3", path, ++playlistIndex, [title stringByReplacingOccurrencesOfString:@"/" withString:@" "]];
            NSURL *mp3FileURL = [NSURL fileURLWithPath:mp3FilePath];
            [[NSFileManager defaultManager] copyItemAtURL:emptyMP3Path toURL:mp3FileURL error:nil];
          
            TagLib::FileRef f([[mp3FileURL path] UTF8String]);
            f.tag()->setTitle(NSStringToTagLibString(title));
            f.tag()->setArtist(NSStringToTagLibString(artist));
            f.tag()->setAlbum(NSStringToTagLibString(album));
            f.tag()->setTrack((int)num_track);
            f.tag()->setYear((int)year);
            f.save();
            
            
            [m3uList appendString:[mp3FileURL path]];
            [m3uList appendString:@"\n"];
            

        }
    }
    
    NSError* error = nil;
    
    [m3uList writeToFile:m3uFilePath
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:&error];
    
    [self.saveButton setEnabled:YES];
    [self showCompleteAlertWithPath:path];
}

- (void)showCompleteAlertWithPath:(NSString *)path {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Show"];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Playlist exported"];
    [alert setInformativeText:@"The playlist has been extracted to your home folder."];
    [alert setAlertStyle:NSInformationalAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[NSWorkspace sharedWorkspace]openFile:path withApplication:@"Finder"];
    }
}

- (IBAction)buyCoffee:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PVGE2UTGDJK62"]];
}


@end
