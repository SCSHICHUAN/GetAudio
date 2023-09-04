//
//  ViewController.m
//  SCFFmpeg
//
//  Created by 石川 on 2019/5/18.
//  Copyright © 2019 石川. All rights reserved.
//

#import "ViewController.h"
#include "libavutil/log.h"
#include "libavformat/avio.h"
#include "libavformat/avformat.h"
#include <AVKit/AVKit.h>
#define kWidth ([UIScreen mainScreen].bounds.size.width)

@interface ViewController ()
@property(nonatomic,assign)BOOL end;
@property(nonatomic,strong)UILabel *lab;
@property(nonatomic,assign)NSInteger video_pak_count;
@property(nonatomic,assign)NSInteger audio_pak_count;
@end

@implementation ViewController


-(void)testClick{
    self.end = YES;
}
-(void)open{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lab.text = @"写入音频平数据中....";
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSLog(@"document=%@",document);
    });
}
-(void)open2{
    dispatch_async(dispatch_get_main_queue(), ^{
        AVPlayerViewController *pvc = [[AVPlayerViewController alloc] init];
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *path = [document stringByAppendingPathComponent:@"sc.mp4"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        pvc.player = [[AVPlayer alloc] initWithURL:url];
        [pvc.player play];
        [self presentViewController:pvc animated:YES completion:nil];
    });
}

-(void)testClick2{
    self.end = NO;
    self.video_pak_count = 0;
    self.audio_pak_count = 0;
    self.lab.text = @"拉流中请稍等...";
    
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [document stringByAppendingPathComponent:@"sc.mp4"];
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [self takeAudio:@"http://sf1-hscdn-tos.pstatp.com/obj/media-fe/xgplayer_doc_video/flv/xgplayer-demo-360p.flv" with:@"/Users/stan/Desktop/sc.mp4"];
        [self takeAudio:@"rtmp://ns8.indexforce.com/home/mystream" with:path];
    });
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    {
        UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
        [[UIApplication sharedApplication].keyWindow addSubview:test];
        test.frame = CGRectMake(50, 100, kWidth-100, 40);;
        test.backgroundColor = UIColor.blueColor;
        [test setTitle:@"START 开始拉流" forState:UIControlStateNormal];
        [test addTarget:self action:@selector(testClick2) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:test];
    }
    UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
    [[UIApplication sharedApplication].keyWindow addSubview:test];
    test.frame = CGRectMake(50, 180, kWidth-100, 40);
    test.backgroundColor = UIColor.redColor;
    [test setTitle:@"STOP 停止拉流" forState:UIControlStateNormal];
    [test addTarget:self action:@selector(testClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:test];
    
    UILabel *lab = [[UILabel alloc] initWithFrame: CGRectMake(50, 250, kWidth-100, 40)];
    lab.backgroundColor = UIColor.blackColor;
    lab.textColor = UIColor.whiteColor;
    [self.view addSubview:lab];
    self.lab = lab;
}






-(int)takeAudio:(NSString *)inPutPath with:(NSString *)outPutPath
{
    
  const char *a = [inPutPath cStringUsingEncoding: NSUTF8StringEncoding];
  const char *b = [outPutPath cStringUsingEncoding: NSUTF8StringEncoding];
    
  const  char *argv[] ={"",a,b};
    
    int err_code;
    char errors[1024];
    
    //资源文件和目标文件
   const char *src_filename = NULL;
   const char *dst_filename = NULL;
    int  video_stream_index = -1,audio_stream_index = -1;
    
    
    //设置log文件的级别
    av_log_set_level(AV_LOG_DEBUG);
    
    //输入文件格式上下文
    AVFormatContext *fmt_ctx = NULL;
    //输出文件的格式上下文
    AVFormatContext *ofmt_ctx = NULL;
    //输出文件容器格式
    AVOutputFormat *output_fmt = NULL;
    
    //AVStream是存储每一个视频/音频流信息的结构体，位于avformat.h文件中
    AVStream *in_stream = NULL;
    AVStream *video_stream = NULL,*audio_stream = NULL;
    
    
   
    AVPacket pkt;
    
    //检测用户输入的参数
//    if(argc<3){
//        av_log(NULL,AV_LOG_DEBUG,"你输入的参数小于两个！\n");
//        return -1;
//    }
    src_filename = argv[1];
    dst_filename = argv[2];
    
    if(src_filename == NULL || dst_filename == NULL){
        av_log(NULL,AV_LOG_DEBUG,"输入文件，或者输出文件路径，或者名称错误！\n");
    }
    //注册所有解码器
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    /*
     初始化格式上下文
     avformat_open_input(****)
     参数1(AVFormatContext **ps):格式上下文
     参数2(char):是媒体文件名或URL．
     参数3(AVInputFormat *fmt):指定输入的封装格式。一般传NULL，由FFmpeg自行探测
     参数4(AVDictionary **options):其它参数设置。它是一个字典，用于参数传递，不传则写NULL
     */
    if((err_code = avformat_open_input(&fmt_ctx,src_filename,NULL,NULL)) < 0){
        //获取错误的文字信息
        av_strerror(err_code,errors,1024);
        av_log(NULL,AV_LOG_DEBUG,"不能打开输入文件: %s,%d(%s)\n",src_filename,err_code,errors);
        return -1;
    }
    /*
     该函数可以读取一部分视音频数据并且获得一些相关的信息
     avformat_find_stream_info(**)
     参数1(AVFormatContext ps):格式上下文
     参数2:额外参数
     */
    if ((err_code = avformat_find_stream_info(fmt_ctx,NULL)) < 0) {
        av_strerror(err_code,errors,1024);
        av_log(NULL,AV_LOG_DEBUG,"没有找到输入流的相关信息:%s,%d(%s)\n",src_filename,err_code,errors);
        return -1;
    }
    /*
     打印多媒体信息
     av_dump_format(****)
     参数1(AVFormatContext ps):格式上下文
     参数2(int):流的索引值
     参数3(char):流的的url或者名字
     参数4(int):"0"表示输入，"1"表示输出
     */
    av_dump_format(fmt_ctx,0,src_filename,0);
    
    
    
    
    /*
     从流中获取编码器
     含音视频参数的结构体。很重要，可以用来获取音视频参数中的宽度、高度、采样率、编码格式等信息。
     */
    AVCodecParameters *video_codecpar,*audio_codecpar;
    
    
    bool have_video_codec = false, have_audio_codec = false;
    //获取环境中所有的流
    int streamChannl = fmt_ctx->nb_streams;
    for(int i = 0;i<streamChannl;i++){
        
        //从格式上下文中获取流
        in_stream = fmt_ctx->streams[i];
        enum AVMediaType mediaType = in_stream->codecpar->codec_type;
        
        char *enumName;
        switch (mediaType) {
            case -1:
                enumName = "AVMEDIA_TYPE_UNKNOWN";
                break;
            case 0:
                enumName = "AVMEDIA_TYPE_VIDEO";
                video_codecpar = in_stream->codecpar;
                have_video_codec = true;
                break;
            case 1:
                enumName = "AVMEDIA_TYPE_AUDIO";
                audio_codecpar = in_stream->codecpar;
                have_audio_codec = true;
                break;
            case 2:
                enumName = "AVMEDIA_TYPE_DATA";
                break;
            case 3:
                enumName = "AVMEDIA_TYPE_SUBTITLE";
                break;
            case 4:
                enumName = "AVMEDIA_TYPE_ATTACHMENT";
                break;
            case 5:
                enumName = "AVMEDIA_TYPE_NB";
                break;
        }
        printf("AVMediaType:%s\n",enumName);
    
    }
    if (!have_video_codec) {
        av_log(NULL,AV_LOG_ERROR,"视频编解码器类型无效");
        return -1;
    }
    if (!have_audio_codec) {
        av_log(NULL,AV_LOG_ERROR,"音频编解码器类型无效");
        return -1;
    }
    
    
    
    //初始化输出格式上下文
    ofmt_ctx = avformat_alloc_context();
    /*
     猜测输出文件容器的格式
     参数1:可以添“rtmp”等
     参数2:文件名字或者url
     参数3:只定解码器
     */
    output_fmt = av_guess_format(NULL,dst_filename,NULL);
    if (!output_fmt) {
        av_log(NULL,AV_LOG_DEBUG,"无法检测到文件格式\n");
        return -1;
    }
    
    //设置输出格式上下文的容器格式
    ofmt_ctx->oformat = output_fmt;
    
    /*
     创建一个输出流
     参数1(AVFormatContext):格式上下文
     参数2:编码器
     */
    //video
    video_stream = avformat_new_stream(ofmt_ctx,NULL);
    //audio
    audio_stream = avformat_new_stream(ofmt_ctx,NULL);
    
    //要在视频中获取音频流则多媒体合作中至少有两路流
    if(fmt_ctx->nb_streams<2){
        av_log(NULL, AV_LOG_ERROR, "the number of stream is too less!\n");
        exit(1);
    }
    
    
    
    
    //复制编码器到输出流的编码器
    //video
    if ((err_code = avcodec_parameters_copy(video_stream->codecpar,video_codecpar)) < 0) {
        av_strerror(err_code,errors,1024);
        av_log(NULL,AV_LOG_ERROR,"不能复制视频编码器参数到输出流中:%s,%d(%s)\n",dst_filename,
               err_code,errors);
        return -1;
    }
    //做一个标记，这里没有用到
    video_stream->codecpar->codec_tag = 0;
    //audio
    if ((err_code = avcodec_parameters_copy(audio_stream->codecpar,audio_codecpar)) < 0) {
        av_strerror(err_code,errors,1024);
        av_log(NULL,AV_LOG_ERROR,"不能复制音频编码器参数到输出流中:%s,%d(%s)\n",dst_filename,
               err_code,errors);
        return -1;
    }
    //做一个标记，这里没有用到
    audio_stream->codecpar->codec_tag = 0;
    
   
    
    /*
     参数1:是一个上下文，后面的API 使用这个上下文就知道是对这个文件操作了
     参数2:输出文件名字或者URL
     参数3:第三个参数是指定对文件允许做那种操作，是只读文件？还是可以对文件进行读写
     */
    if ((err_code = avio_open(&ofmt_ctx->pb,dst_filename,AVIO_FLAG_WRITE)) < 0) {
        av_strerror(err_code,errors,1024);
        av_log(NULL,AV_LOG_DEBUG,"不能打开输出文件: %s,%d(%s)\n",src_filename,err_code,errors);
        //异常退出
        exit(1);
    }
    //打印输出文件的多媒体信息
    av_dump_format(ofmt_ctx,0,dst_filename,1);
    
    
    
    //初始化数据包
    av_init_packet(&pkt);
    pkt.data = NULL;
    pkt.size = 0;
    
    /*
     av_find_best_stream(******)
     参数1:格式上下文
     参数2:获取视频还是音频
     参数3:流的索引值（不知道传-1）
     参数4:和流相关的流（视频流对应的音频流是那个）
     参数5:流的编码器
     参数6:标志flag（暂时没有用）
     返回：这个流的索引值
     */
    
    
    //video
    video_stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if(video_stream_index < 0){
        av_log(NULL, AV_LOG_DEBUG, "Could not find %s stream in input file %s\n",
               av_get_media_type_string(AVMEDIA_TYPE_VIDEO),
               src_filename);
        //EINVAL= ERROR INVALID；代表无效值
        return AVERROR(EINVAL);
    }
    //audio
    audio_stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if(audio_stream_index < 0){
        av_log(NULL, AV_LOG_DEBUG, "Could not find %s stream in input file %s\n",
               av_get_media_type_string(AVMEDIA_TYPE_AUDIO),
               src_filename);
        //EINVAL= ERROR INVALID；代表无效值
        return AVERROR(EINVAL);
    }
   
    
    
    /*
     写入头
     参数1:用于输出的AVFormatContext
     参数2:options，额外的选项，一般为NULL
     返回：函数正常执行后返回值等于0
     */
    if (avformat_write_header(ofmt_ctx,NULL) < 0) {
        av_log(NULL,AV_LOG_DEBUG,"不能打开当前的输出文件");
        exit(1);
    }
    
    //从格式上下文读取数据到数据包中
    while (av_read_frame(fmt_ctx, &pkt) >=0 && !self.end) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lab.text = [NSString stringWithFormat:@"video:%ld 个，audio:%ld 个",self.video_pak_count,self.audio_pak_count];
        });
        
        //video
        if (pkt.stream_index == video_stream_index) {
            self.video_pak_count++;
            //把输入流的时间基转换到输出流的时间基，第三个参数, 它的作用是计算 "a * b / c" 的值并分五种方式来取整.
            pkt.pts = av_rescale_q_rnd(pkt.pts,in_stream->time_base,video_stream->time_base,
                                       (AV_ROUND_INF|AV_ROUND_PASS_MINMAX));
            //解码顺序时间，和呈现顺序相同
            pkt.dts = pkt.pts;
            /*
             int64_t av_rescale_q(int64_t a, AVRational bq, AVRational cq) av_const;
             av_rescale_q(a,b,c)的作用是，把时间戳从一个时基调整到另外一个时基时候用的函数。其中，a 表式要换算的值；b 表式原来的时间基；c表式要转换的时间基。其计算公式为 a * bq / cq。（q = 1000000）
             */
            //把时间转换为输出流的时间
            pkt.duration = av_rescale_q(pkt.duration,in_stream->time_base,video_stream->time_base);
            /*
             byte position in stream, -1 if unknown
             当前帧数据在文件中的位置（字节为单位），如果做文件移位用到，如果rtsp就没有此数据。
             */
            pkt.pos = -1;
            //帧数据所属流的索引，用来区分音频，视频，和字幕数据。
//            pkt.stream_index = 1;
            av_interleaved_write_frame(ofmt_ctx,&pkt);
            /*读取数据，每读取一个数据
             包就是开辟一个空间，引用计数加一，要用 av_packet_unref() 来让引用计数减一
             如果引用计数为零就释放掉。*/
            av_packet_unref(&pkt);
         //audio
        }else  if (pkt.stream_index == audio_stream_index) {
            self.audio_pak_count++;
            //把输入流的时间基转换到输出流的时间基，第三个参数, 它的作用是计算 "a * b / c" 的值并分五种方式来取整.
            pkt.pts = av_rescale_q_rnd(pkt.pts,in_stream->time_base,audio_stream->time_base,
                                       (AV_ROUND_INF|AV_ROUND_PASS_MINMAX));
            //解码顺序时间，和呈现顺序相同
            pkt.dts = pkt.pts;
            /*
             int64_t av_rescale_q(int64_t a, AVRational bq, AVRational cq) av_const;
             av_rescale_q(a,b,c)的作用是，把时间戳从一个时基调整到另外一个时基时候用的函数。其中，a 表式要换算的值；b 表式原来的时间基；c表式要转换的时间基。其计算公式为 a * bq / cq。（q = 1000000）
             */
            //把时间转换为输出流的时间
            pkt.duration = av_rescale_q(pkt.duration,in_stream->time_base,audio_stream->time_base);
            /*
             byte position in stream, -1 if unknown
             当前帧数据在文件中的位置（字节为单位），如果做文件移位用到，如果rtsp就没有此数据。
             */
            pkt.pos = -1;
            //帧数据所属流的索引，用来区分音频，视频，和字幕数据。
//            pkt.stream_index = 0;
            av_interleaved_write_frame(ofmt_ctx,&pkt);
            /*读取数据，每读取一个数据
             包就是开辟一个空间，引用计数加一，要用 av_packet_unref() 来让引用计数减一
             如果引用计数为零就释放掉。*/
            av_packet_unref(&pkt);
        }
        
    }
    [self open];
    //创建尾
    av_write_trailer(ofmt_ctx);
    //关闭输入格式上下文
    avformat_close_input(&fmt_ctx);
    //关闭输出格式上下文
    avio_close(ofmt_ctx->pb);
    [self open2];
    return 0;
}

@end
