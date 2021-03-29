// Copyright (c) 2017-2021 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "SPDownload.h"

#import "../Util.h"
#import "../SafariPlus.h"
#import "SPDownloadInfo.h"
#import "SPPreferenceManager.h"
#import "SPLocalizationManager.h"

#import <AVFoundation/AVFoundation.h>

@implementation SPDownload

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	self = [super init];

	_request = downloadInfo.request;
	_filesize = downloadInfo.filesize;
	_filename = downloadInfo.filename;
	_targetURL = downloadInfo.targetURL;
	_isHLSDownload = downloadInfo.isHLSDownload;

	if(downloadInfo.sourceDocument)
	{
		_startedFromPrivateBrowsingMode = privateBrowsingEnabledForTabDocument(downloadInfo.sourceDocument);
	}
	else
	{
		_startedFromPrivateBrowsingMode = NO;
	}

	_orgInfo = downloadInfo;

	_observerDelegates = [NSHashTable weakObjectsHashTable];

	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];

	_taskIdentifier = [decoder decodeIntegerForKey:@"taskIdentifier"];
	_request = [decoder decodeObjectForKey:@"request"];
	_filename = [decoder decodeObjectForKey:@"filename"];
	_targetURL = [decoder decodeObjectForKey:@"targetURL"];
	_filesize = [decoder decodeIntegerForKey:@"filesize"];
	_totalBytesWritten = [decoder decodeIntegerForKey:@"totalBytesWritten"];
	_paused = [decoder decodeBoolForKey:@"paused"];
	_resumeData = [decoder decodeObjectForKey:@"resumeData"];
	_wasCancelled = [decoder decodeBoolForKey:@"wasCancelled"];
	_startedFromPrivateBrowsingMode = [decoder decodeBoolForKey:@"startedFromPrivateBrowsingMode"];
	_isHLSDownload = [decoder decodeBoolForKey:@"isHLSDownload"];
	_expectedDuration = [decoder decodeFloatForKey:@"expectedDuration"];

	_observerDelegates = [NSHashTable weakObjectsHashTable];

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInteger:_taskIdentifier forKey:@"taskIdentifier"];
	[coder encodeObject:_request forKey:@"request"];
	[coder encodeObject:_filename forKey:@"filename"];
	[coder encodeObject:_targetURL forKey:@"targetURL"];
	[coder encodeInteger:_filesize forKey:@"filesize"];
	[coder encodeInteger:_totalBytesWritten forKey:@"totalBytesWritten"];
	[coder encodeBool:_paused forKey:@"paused"];
	[coder encodeObject:_resumeData forKey:@"resumeData"];
	[coder encodeBool:_wasCancelled forKey:@"wasCancelled"];
	[coder encodeBool:_startedFromPrivateBrowsingMode forKey:@"startedFromPrivateBrowsingMode"];
	[coder encodeBool:_isHLSDownload forKey:@"isHLSDownload"];
	[coder encodeFloat:_expectedDuration forKey:@"expectedDuration"];
}

- (void)setDownloadTask:(NSURLSessionDownloadTask*)downloadTask
{
	_downloadTask = downloadTask;

	//Update taskIdentifier to make download resumable after Safari has been closed
	_taskIdentifier = _downloadTask.taskIdentifier;
}

- (void)startDownload
{
	if(self.resumeData)
	{
		[self parseResumeData];
	}
	else
	{
		if(preferenceManager.onlyDownloadOnWifiEnabled)
		{
			if(isUsingCellularData())
			{
				static BOOL cellularDataWarningHasBeenShown = NO;
				if(!cellularDataWarningHasBeenShown)
				{
					sendSimpleAlert([localizationManager localizedSPStringForKey:@"WARNING"], [localizationManager localizedSPStringForKey:@"CELLULAR_DATA_WARNING"]);
					cellularDataWarningHasBeenShown = YES;
				}
			}
		}
	}

	[self setPaused:self.paused forced:YES];
}

- (void)parseResumeData
{
	//Parse resumeData
	NSDictionary* resumeDataDict = [NSPropertyListSerialization
					propertyListWithData:self.resumeData options:NSPropertyListImmutable
					format:nil error:nil];

	if([[resumeDataDict objectForKey:@"$archiver"] isEqualToString:@"NSKeyedArchiver"])
	{
		resumeDataDict = decodeResumeData12(self.resumeData);
	}

	//Get progress from resumeData
	NSNumber* progress = [resumeDataDict objectForKey:@"NSURLSessionResumeBytesReceived"];

	//Update totalBytesWritten
	self.totalBytesWritten = (int64_t)[progress longLongValue];
}

- (void)setPaused:(BOOL)paused
{
	[self setPaused:paused forced:NO];
}

- (void)setPaused:(BOOL)paused forced:(BOOL)forced
{
	dlogDownload(self, [NSString stringWithFormat:@"setPaused:%i forced:%i", paused, forced]);
	if((paused != _paused) || forced)
	{
		BOOL needsUpdate = YES;

		if(paused)
		{
			//Download needs to be paused
			if(self.downloadTask.state == NSURLSessionTaskStateRunning)
			{
				if(self.isHLSDownload)
				{
					[self.downloadTask suspend];
				}
				else
				{
					needsUpdate = NO;	//Only code path that updates delayed (after the task is actually cancelled)
					[self.downloadTask cancelByProducingResumeData:^(NSData *resumeData)
					{
						if(self.totalBytesWritten > 0)
						{
							//If no bytes have been written yet, the resumeData will be invalid and cause an error
							//when the download is resumed, therefore we don't store and rather start from beginning
							self.resumeData = resumeData;
						}

						self.downloadTask = nil;

						_paused = paused;
						[self pauseStateChanged];
					}];
				}
			}
		}
		else
		{
			if(!self.downloadTask)
			{
				if(self.resumeData && !self.isHLSDownload)
				{
					//Resume from resumeData
					self.downloadTask = [[self.downloadManagerDelegate sharedDownloadSession] downloadTaskWithResumeData:self.resumeData];
					self.resumeData = nil;
				}
				else
				{
					//Begin downloading
					if(self.isHLSDownload)
					{
						if(self.downloadTask)
						{
							[self.downloadTask resume];
						}
						else
						{
							AVURLAsset* URLAsset = [AVURLAsset URLAssetWithURL:self.request.URL options:nil];
							self.downloadTask = [[self.downloadManagerDelegate sharedAVDownloadSession] assetDownloadTaskWithURLAsset:URLAsset assetTitle:self.request.URL.lastPathComponent assetArtworkData:nil options:nil];
						}
					}
					else
					{
						self.downloadTask = [[self.downloadManagerDelegate sharedDownloadSession] downloadTaskWithRequest:self.request];
					}
				}
			}

			//Resume task
			[self.downloadTask resume];
		}

		if(needsUpdate)
		{
			_paused = paused;
			[self pauseStateChanged];
		}
	}
}

- (void)pauseStateChanged
{
	//Update cell delegates
	[self runBlockOnObserverDelegates:^(id<DownloadObserverDelegate> observerDelegate)
	{
		[observerDelegate pauseStateDidChangeForDownload:self];
	} onMainThread:YES];

	[self.downloadManagerDelegate runningDownloadsCountDidChange];

	//Start Timer
	[self setTimerEnabled:!self.paused];

	//Update data on disk
	[self.downloadManagerDelegate saveDownloadsToDisk];
}

- (void)setFilesize:(int64_t)filesize
{
	if(filesize != _filesize)
	{
		_filesize = filesize;

		dlogDownload(self, @"setFilesize");

		//Also update size of info
		self.orgInfo.filesize = filesize;

		[self runBlockOnObserverDelegates:^(id<DownloadObserverDelegate> observerDelegate)
		{
			[observerDelegate filesizeDidChangeForDownload:self];
		} onMainThread:YES];

		[self.downloadManagerDelegate totalProgressDidChange];
	}
}

- (void)setExpectedDuration:(CGFloat)expectedDuration
{
	if(expectedDuration != _expectedDuration)
	{
		_expectedDuration = expectedDuration;

		[self runBlockOnObserverDelegates:^(id<DownloadObserverDelegate> observerDelegate)
		{
			[observerDelegate expectedDurationDidChangeForDownload:self];
		} onMainThread:YES];

		[self.downloadManagerDelegate totalProgressDidChange];
	}
}

- (void)cancelDownload
{
	self.wasCancelled = YES;

	dlogDownload(self, @"cancelDownload");

	if(self.downloadTask && self.downloadTask.state == NSURLSessionTaskStateRunning)
	{
		//Cancel task
		[self.downloadTask cancel];

		//Stop timer
		[self setTimerEnabled:NO];
	}
	else
	{
		//Download is paused or stuck, force the cancellation
		[self.downloadManagerDelegate forceCancelDownload:self];
	}
}

- (void)setTimerEnabled:(BOOL)enabled
{
	dlogDownload(self, [NSString stringWithFormat:@"setTimerEnabled:%i", enabled]);
	if(enabled && !self.paused && ![self.speedTimer isValid])
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			//Start timer that updates download speed every 0.5 seconds
			self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
					   target:self selector:@selector(updateDownloadSpeed) userInfo:nil repeats:YES];

			//Set lastSpeedRefreshTime (of timer) to current time
			self.lastSpeedRefreshTime = [NSDate timeIntervalSinceReferenceDate];
		});
	}
	else if(!enabled && [self.speedTimer isValid])
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			//Stop timer
			[self.speedTimer invalidate];
		});
	}
}

- (void)updateDownloadSpeed
{
	//Get current time
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

	//Calculate bytes per second from last half a second
	self.bytesPerSecond = (self.totalBytesWritten - self.startBytes) / (currentTime - self.lastSpeedRefreshTime);

	//Set new values for next update
	self.startBytes = self.totalBytesWritten;
	self.lastSpeedRefreshTime = currentTime;

	//Update value on cell(s)
	[self runBlockOnObserverDelegates:^(id<DownloadObserverDelegate> observerDelegate)
	{
		[observerDelegate downloadSpeedDidChangeForDownload:self];
	} onMainThread:YES];
}

- (void)updateProgressForTotalBytesWritten:(int64_t)totalBytesWritten totalFilesize:(int64_t)filesize
{
	dlog(@"%@ / %llu - updateProgress", self.filename, (unsigned long long)self.taskIdentifier);
	//Verify filesize
	if(self.filesize != filesize)
	{
		//Set filesize
		self.filesize = filesize;

		//Check if enough space is left
		if(![self.downloadManagerDelegate enoughDiscspaceForDownloadInfo:self.orgInfo])
		{
			[self cancelDownload];

			[self.downloadManagerDelegate presentNotEnoughSpaceAlertWithDownloadInfo:self.orgInfo];
		}
	}

	//Update totalBytesWritten
	self.totalBytesWritten = totalBytesWritten;

	[self updateProgress];
}

- (void)updateProgressForSecondsLoaded:(CGFloat)secondsLoaded expectedDuration:(CGFloat)expectedDuration
{
	if(self.expectedDuration != expectedDuration)
	{
		self.expectedDuration = expectedDuration;
	}

	self.secondsLoaded = secondsLoaded;

	[self updateProgress];
}

- (void)updateProgress
{
	[self.downloadManagerDelegate totalProgressDidChange];

	[self runBlockOnObserverDelegates:^(id<DownloadObserverDelegate> observerDelegate)
	{
		[observerDelegate progressDidChangeForDownload:self shouldAnimateChange:YES];
	} onMainThread:YES];
}

- (int64_t)remainingBytes
{
	return self.filesize - self.totalBytesWritten;
}

- (void)runBlockOnObserverDelegates:(void (^)(id<DownloadObserverDelegate> receiverDelegate))block onMainThread:(BOOL)mainThread
{
	for(id<DownloadObserverDelegate> observerDelegate in _observerDelegates)
	{
		if(observerDelegate)
		{
			if(![NSThread isMainThread] && mainThread)
			{
				dispatch_async(dispatch_get_main_queue(), ^(void)
				{
					block(observerDelegate);
				});
			}
			else
			{
				block(observerDelegate);
			}
		}
	}
}

- (void)addObserverDelegate:(id<DownloadObserverDelegate>)observerDelegate
{
	if(![_observerDelegates containsObject:observerDelegate])
	{
		[_observerDelegates addObject:observerDelegate];

		//Welcome the new delegate by running updates

		if(self.isHLSDownload)
		{
			[observerDelegate expectedDurationDidChangeForDownload:self];
		}
		else
		{
			[observerDelegate filesizeDidChangeForDownload:self];
		}
		[observerDelegate pauseStateDidChangeForDownload:self];
		[observerDelegate downloadSpeedDidChangeForDownload:self];
		[observerDelegate progressDidChangeForDownload:self shouldAnimateChange:NO];
	}
}

- (void)removeObserverDelegate:(id<DownloadObserverDelegate>)observerDelegate
{
	if([_observerDelegates containsObject:observerDelegate])
	{
		[_observerDelegates removeObject:observerDelegate];
	}
}

- (NSUInteger)hash
{
	return [self description].hash;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<SPDownload: filename = %@, targetURL = %@, filesize = %llu, request = %@ downloadTask = %@>", self.filename, self.targetURL, self.filesize, self.request, self.downloadTask];
}

@end
