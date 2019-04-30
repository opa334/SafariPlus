// SPDownload.mm
// (c) 2017 - 2019 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPDownload.h"

#import "../Util.h"
#import "SPDownloadInfo.h"
#import "SPPreferenceManager.h"
#import "SPLocalizationManager.h"

@implementation SPDownload

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	self = [super init];

	_request = downloadInfo.request;
	_filesize = downloadInfo.filesize;
	_filename = downloadInfo.filename;
	_targetURL = downloadInfo.targetURL;

	_orgInfo = downloadInfo;

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
	_didFinish = [decoder decodeBoolForKey:@"didFinish"];
	_wasCancelled = [decoder decodeBoolForKey:@"wasCancelled"];

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
	[coder encodeBool:_didFinish forKey:@"didFinish"];
	[coder encodeBool:_wasCancelled forKey:@"wasCancelled"];
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
		if(paused)
		{
			//Download needs to be paused
			[self.downloadTask cancelByProducingResumeData:^(NSData *resumeData)
			{
				self.resumeData = resumeData;
				_paused = YES;

				//Update cell delegates
				dispatch_async(dispatch_get_main_queue(), ^
					       {
						       _browserCellDelegate.paused = YES;
						       _listCellDelegate.paused = YES;
					       });

				//Stop Timer
				[self setTimerEnabled:NO];

				self.downloadTask = nil;

				//Update data on disk
				[self.downloadManagerDelegate saveDownloadsToDisk];
			}];
		}
		else
		{
			_paused = NO;

			if(!self.downloadTask)
			{
				if(self.resumeData)
				{
					//Resume from resumeData
					self.downloadTask = [[self.downloadManagerDelegate sharedDownloadSession] downloadTaskWithResumeData:self.resumeData];
					self.resumeData = nil;
				}
				else
				{
					//Begin downloading
					self.downloadTask = [[self.downloadManagerDelegate sharedDownloadSession] downloadTaskWithRequest:self.request];
				}
			}

			//Update cell delegates
			dispatch_async(dispatch_get_main_queue(), ^
			{
				_browserCellDelegate.paused = NO;
				_listCellDelegate.paused = NO;
			});

			//Start Timer
			[self setTimerEnabled:YES];

			//Resume task
			[self.downloadTask resume];

			//Update data on disk
			[self.downloadManagerDelegate saveDownloadsToDisk];
		}
	}
}

- (void)setFilesize:(int64_t)filesize
{
	if(filesize != _filesize)
	{
		_filesize = filesize;

		dlogDownload(self, @"setFilesize");

		//Also update size of info
		self.orgInfo.filesize = filesize;

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.browserCellDelegate setFilesize:filesize];
			[self.listCellDelegate setFilesize:filesize];
		});
	}
}

- (void)cancelDownload
{
	self.didFinish = YES;
	self.wasCancelled = YES;

	dlogDownload(self, @"cancelDownload");

	if(self.downloadTask)
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
	[self.browserCellDelegate updateDownloadSpeed:self.bytesPerSecond];
	[self.listCellDelegate updateDownloadSpeed:self.bytesPerSecond];
}

- (void)updateProgress:(int64_t)totalBytesWritten totalFilesize:(int64_t)filesize
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

	//Update cell(s)
	[self.browserCellDelegate updateProgress:totalBytesWritten totalBytes:self.filesize animated:YES];
	[self.listCellDelegate updateProgress:totalBytesWritten totalBytes:self.filesize animated:YES];
}

- (int64_t)remainingBytes
{
	return self.filesize - self.totalBytesWritten;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<SPDownload: filename = %@, targetURL = %@, filesize = %llu>", self.filename, self.targetURL, self.filesize];
}

@end
