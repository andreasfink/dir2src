# dir2src
Convert directory with files to C code to include.


Let's assume you have an integrated mini webserver in your application which dynamically creates HTML pages.
However you have some statical content such as CSS files or so which you have to serve as well.
You can have these files separate from the binary or you can embed them. This tool is for makign the second 
case easier. It is written in ObjectiveC but outputs plain C code. Under Linux it uses the gnustep-base Foundation classes.



Example

you have a directory structure like tis:

	web/
		index.html
		css/
			style.css
			
you call:

	dir2src --header web.h --output web.m web


and you will end up with  web.h and web.m you can include in your C or ObjectiveC code to access this data.


To initialize it this code snippet in ObjectiveC will create a dictionary with the pages you generated

		#import "web.h"
		
		NSMutableDictionary *_webPages;
		
		void initStaticPages()
		{
			_webPages = [[NSMutableDictionary alloc]init];
			int i=0;
			int n = allWebDirEntriesCount;
			for(i=0;i<n;i++)
			{
				webDirEntry *e = &allWebDirEntries[i];
				NSMutableDictionary *entry = [[NSMutableDictionary alloc]init];
				NSString *path =  @(e->path);
				entry[@"path"] = path;
				entry[@"content-type"] = @(e->mimeType);
				entry[@"data"] = [NSData dataWithBytes:e->data length:e->datalen ];
				_webPages[path] = entry;
			}
		}

If you use the integrated webserver of ulib (http://github.com/andreasfink/ulib) you can serve these 
built in pages like this:


	- (void)  httpGetPost:(UMHTTPRequest *)req
	{
		@autoreleasepool
		{
			NSString *path = req.url.relativePath;
			if([path hasPrefix:@"/api"])
			{
				/* do your generated code here */
				[req setResponseJsonObject:@{ @"error" : @"api-not-found" }];
			}
			else /* any non generated page */
			{
				NSDictionary *entry = _webPages[path];
				if(entry)
				{
					[req setContentType:entry[@"content-type"]];
					[req setResponseData:entry[@"data"]];
				}
				else
				{
					NSString *s = @"Result: Error\nReason: Unknown request\n";
					[req setResponseTypeText];
					req.responseData = [s dataUsingEncoding:NSUTF8StringEncoding];
					req.responseCode =  404;
				}
			}
		}
	}
