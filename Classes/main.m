//
//  main.m
//  dir2src
//
//  Created by Andreas Fink on 14.10.14.
//  Copyright (c) 2014 SMSRelay AG. All rights reserved.
//

#import <Foundation/Foundation.h>

int main2(int argc, const char * argv[]);
void processFile(NSString *root, NSString *relativePath,int *count);
NSString *mimeTypeForFilename(NSString *filename);

#include <stddef.h>
#include <stdio.h>
#include <time.h>

BOOL textMode = NO;
FILE *fhead  = NULL;
FILE *fout   = NULL;
const char *headfilename = "out.h";
const char *outfilename = "out.m";
const char *toolname = "dir2src";
const char *source ="(https://github.com/andreasfink/dir2src)";
NSMutableArray *allFiles = NULL;

void header(void);
void write_files(void);
void footer(void);

void header(void)
{
    time_t now;
    
    time(&now);
    const char *nowString = ctime(&now);
    
    fprintf(fhead,"//\n");
    fprintf(fhead,"//\n");
    fprintf(fhead,"//\n");
    fprintf(fhead,"// automatically generated using '%s' %s\n",toolname,source);
    fprintf(fhead,"// on %s",nowString);
    fprintf(fhead,"\n");

    fprintf(fout,"//\n");
    fprintf(fout,"//\n");
    fprintf(fout,"//\n");
    fprintf(fout,"// automatically generated using '%s' %s\n",toolname,source);
    fprintf(fout,"// on %s",nowString);
    fprintf(fout,"\n");

    fprintf(fhead,"\n");
    fprintf(fhead,"#import <unistd.h>\n");
    fprintf(fhead,"\n");
    
    fprintf(fhead,"typedef struct webDirEntry\n");
    fprintf(fhead,"{\n");
    fprintf(fhead,"    const char *path;\n");
    fprintf(fhead,"    const char *mimeType;\n");
    fprintf(fhead,"    const unsigned char *data;\n");
    fprintf(fhead,"    size_t datalen;\n");
    fprintf(fhead,"} webDirEntry;\n");
    fprintf(fhead,"\n");
    fprintf(fhead,"extern webDirEntry allWebDirEntries[];\n");
    fprintf(fhead,"extern int allWebDirEntriesCount;\n");
    fprintf(fhead,"\n");

    fprintf(fout,"#include \"%s\"\n",headfilename);
    
    fprintf(fout,"\n");
    fprintf(fout,"webDirEntry allWebDirEntries[] =\n");
    fprintf(fout,"{\n");
}

void footer (void)
{
    int count = (int) [allFiles count];
    fprintf(fout,"};\n\n");
    fprintf(fout,"int allWebDirEntriesCount = %d;\n\n",count);
    fprintf(fout,"\n");
}

@interface FileEntry : NSObject
{
    NSString *absolutePath;
    NSString *relativePath;
    NSString *webPath;
    NSString *mimeType;
    NSData   *data;
}

@property(strong)    NSString *absolutePath;
@property(strong)    NSString *relativePath;
@property(strong)    NSString *webPath;
@property(strong)    NSString *mimeType;
@property(strong)    NSData   *data;

- (NSComparisonResult)caseInsensitiveCompare:(FileEntry *)other;

@end

@implementation FileEntry

@synthesize absolutePath;
@synthesize relativePath;
@synthesize webPath;
@synthesize mimeType;
@synthesize data;

- (NSComparisonResult)caseInsensitiveCompare:(FileEntry *)other
{
    return [webPath caseInsensitiveCompare:other.webPath];
}

@end


int main(int argc, const char *argv[])
{
    @autoreleasepool
	{
		const char **argv2 = (void *)malloc(sizeof(char *) * argc);

		toolname = argv[0];
		int i;
		int j=0;
		argv2[j++]=argv[0];
		if(argc==1)
		{
			fprintf(stderr,"Usage: %s --header <headerfile.h> --output <outputfile.m> directory1 directory2...\n",toolname);
			exit(0);
		}
		for(i=1;i<argc;i++)
		{
			const char *option = argv[i];

			if((strcmp(option,"-?")==0) || (strcmp(option,"-h")==0) || (strcmp(option,"--help")==0))
			{
				fprintf(stderr,"Usage: %s --header <headerfile.h> --output <outputfile.m> directory1 directory2...\n",toolname);
				exit(0);
			}
            if(strcmp(option,"--text")==0)
            {
                textMode = YES;
            }
            else if(strcmp(option,"--binary")==0)
            {
                textMode = NO;
            }
			if(strcmp(option,"--header")==0)
			{
				i++;
				if(i < argc)
				{
					headfilename = argv[i];
				}
			}
			else if(strcmp(option,"--output")==0)
			{
				i++;
				if(i < argc)
				{
					outfilename = argv[i];
				}
			}
			else
			{
				argv2[j++]=argv[i];
			}
		}
		int argc2 = j;
		fprintf(stderr,"Writing to header %s\n",headfilename);
		fhead  = fopen(headfilename,"w");
		if(fhead ==NULL)
		{
			fprintf(stderr,"Error: can not write to '%s'\n",headfilename);
			exit(-1);
		}
		fprintf(stderr,"Writing to outputfile %s\n",outfilename);
		fout   = fopen(outfilename,"w");
		if(fout ==NULL)
		{
			fprintf(stderr,"Error: can not write to '%s'\n",outfilename);
			exit(-1);
		}
		main2(argc2,argv2);
		fclose(fout);
		fclose(fhead);
	}
}

int main2(int argc, const char * argv[])
{
    int i;
    int count = 0;
    
    
    @autoreleasepool
    {
        allFiles = [[NSMutableArray alloc]init];
        for(i=1;i<argc;i++)
        {
            NSFileManager *mgr = [NSFileManager defaultManager];
            NSString *path = [NSString stringWithUTF8String:argv[i]];
            fprintf(stderr,"Traversing directory %s\n",argv[i]);

            
            for (NSString *filePath in [mgr enumeratorAtPath:path]) {
			    NSError *err = nil;
			    NSDictionary *itemInfo = [mgr attributesOfItemAtPath:[path stringByAppendingPathComponent:filePath] error:&err];
				if (itemInfo)
			    {
					if ([itemInfo objectForKey:NSFileTypeDirectory] == NSFileTypeDirectory)
					{
						fprintf(stderr,"Traversing directory %s\n",filePath.UTF8String);
					}
					else
					{
						if ([itemInfo objectForKey:NSFileType] == NSFileTypeRegular)
						{
							processFile(path, filePath,&count);
						}
					}
				}
				else
				{
				    fprintf(stderr, "Error getting attributes of %s: %s\n", filePath.UTF8String, err.localizedDescription.UTF8String);
				}
            }
        }
        header();
        write_files();
        footer();
    }
    return 0;
}

NSString *mimeTypeForFilename(NSString *filename)
{
    if(!filename)
    {
        return nil;
    }
    if([filename hasSuffix:@"txt"])
    {
        return @"text/plain; charset=\"UTF-8\"";
    }
    else if([filename hasSuffix:@"html"])
    {
        return @"text/html; charset=\"UTF-8\"";
    }
    else if([filename hasSuffix:@"css"])
    {
        return @"text/css";
    }
    else if([filename hasSuffix:@"png"])
    {
        return @"image/png";
    }
    else if([filename hasSuffix:@"jpg"])
    {
        return @"image/jpeg";
    }
    else if([filename hasSuffix:@"jpeg"])
    {
        return @"image/jpeg";
    }
    else if([filename hasSuffix:@"gif"])
    {
        return @"image/gif";
    }
    else if([filename hasSuffix:@"js"])
    {
        return @"application/javascript";
    }
    return @"application/octet-stream";
}

void processFile(NSString *root, NSString *relativePath,int *count)
{
    
    /* we explicitly exclude files ending in .json as they are placeholder for dynamic data used while testing */

    if([relativePath hasSuffix:@"json"])
    {
        return;
    }
    if([relativePath hasSuffix:@"DS_Store"])
    {
        return;
    }
    if([relativePath hasSuffix:@"git"])
    {
        return;
    }
    if([relativePath hasSuffix:@"svn"])
    {
        return;
    }
    NSLog(@"Processing file: %@",relativePath);
    
    
    FileEntry *e = [[FileEntry alloc]init];

    e.absolutePath = [NSString stringWithFormat:@"%@/%@",root,relativePath];
    e.relativePath = relativePath;
    e.webPath = [NSString stringWithFormat:@"/%@",relativePath];
    e.mimeType = mimeTypeForFilename(relativePath);
    e.data = [NSData dataWithContentsOfFile:e.absolutePath];
    [allFiles addObject:e];
}


void write_files(void)
{
    NSArray *sortedFiles =  [allFiles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for(FileEntry *entry in sortedFiles)
    {
        uint8_t *ptr = (uint8_t *)[entry.data bytes];
        size_t len = [entry.data length];
        
        int i;

        fprintf(fout,"\t{\n");
        fprintf(fout,"\t\t\"%s\",\n",entry.webPath.UTF8String);

        if([entry.relativePath hasSuffix:@"txt"])
        {
            fprintf(fout,"\t\t\"text/plain; charset=\\\"UTF-8\\\"\",\n");
        }
        else if([entry.relativePath hasSuffix:@"html"])
        {
            fprintf(fout,"\t\t\"text/html; charset=\\\"UTF-8\\\"\",\n");
        }
        else
        {
            fprintf(fout,"\t\t\"%s\",\n",entry.mimeType.UTF8String);
        }
        fprintf(fout,"\t\t");

        if(textMode==YES)
        {
            fprintf(fout,"\"");
            BOOL startNewLine = NO;
            int char_count = 0;
            for(i=0;i<len;i++)
            {
                uint8_t c = ptr[i];
                if(c=='\n')
                {
                    fprintf(fout,"\\n");
                    startNewLine = YES;
                }
                if(c=='\t')
                {
                    fprintf(fout,"\t");
                    char_count +=1;
                }
                else if(c=='"')
                {
                    fprintf(fout,"\\\"");
                    char_count +=2;
                }
                else if(c=='\\')
                {
                    fprintf(fout,"\\\\");
                    char_count +=2;
                }
                else if(isprint(c))
                {
                    fprintf(fout,"%c",c);
                    char_count++;

                }
                else
                {
                    fprintf(fout,"\\x%02X",c);
                    char_count += 4;
                }
                if(char_count > 240)
                {
                    startNewLine=YES;
                }
                if(startNewLine)
                {
                    fprintf(fout,"\"\n\t\t\"");
                    startNewLine = NO;
                    char_count=0;
                }
            }
            fprintf(fout,"\"");
        }
        else
        {
            fprintf(fout,"(unsigned char []){");
            for(i=0;i<len;i++)
            {
                fprintf(fout,"0x%02x",ptr[i]);
                if(i != (len-1))
                {
                    fprintf(fout,",");
                }
                if((i % 32)==31)
                {
                    fprintf(fout,"\n\t\t          ");
                }
            }
            fprintf(fout,"}");
        }
        fprintf(fout,",\n");
        fprintf(fout,"\t\t%d\n",(int)len);
        fprintf(fout,"\t},\n");
    }
}
