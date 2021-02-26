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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self takeAudio:@"/Users/stan/Desktop/1.mp4" with:@"/Users/stan/Desktop/v1.aac"];
    
    
    
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
    int audio_stream_index = -1;
    
    
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
    AVStream *out_stream = NULL;
    
    
    /*
     保存了fream，和其他的一些信息
     AVPacket是FFmpeg中很重要的一个数据结构，它保存了解复用（demuxer)之后，解码（decode）之前的数据
     （仍然是压缩后的数据）和关于这些数据的一些附加的信息，如显示时间戳（pts），解码时间戳（dts）,数据
     时长（duration），所在流媒体的索引（stream_index）等等。对于视频（Video）来说，AVPacket通常
     包含一个压缩的Frame；而音频（Audio）则有可能包含多个压缩的Frame。并且，一个packet也有可能是空的，
     不包含任何压缩数据data，只含有边缘数据side data（side data,容器提供的关于packet的一些附加信息，
     例如，在编码结束的时候更新一些流的参数,在另外一篇av_read_frame会介绍）AVPacket的大小是公共的
     ABI(Public ABI)一部分，这样的结构体在FFmpeg很少，由此也可见AVPacket的重要性，它可以被分配在
     栈空间上（可以使用语句AVPacket pkt;在栈空间定义一个Packet），并且除非libavcodec 和libavformat
     有很大的改动，不然不会在AVPacket中添加新的字段。
     
     typedef struct AVPacket {
     
     AVBufferRef *buf;//用来存放引用计数的数据，如果没有使用引用计数，值就是NULL，当你多个packet对象引用同一帧数据的时候用到。
     
     int64_t pts;
     int64_t dts;
     
     //帧的数据和数据大小
     uint8_t *data;
     int size;
     
     int stream_index;//帧数据所属流的索引，用来区分音频，视频，和字幕数据。
     int flags;//标志，其中为1表示该数据是一个关键帧（AV_PKT_FLAG_KEY 0x0001） 关键帧
     
     //容器提供的一些附加数据
     AVPacketSideData *side_data;
     int side_data_elems;
     
     int64_t duration;//下一帧pts - 当前帧pts ，也就表示两帧时间间隔。
     int64_t pos;//当前帧数据在文件中的位置（字节为单位），如果做文件移位用到，如果rtsp就没有此数据。
     
     #if FF_API_CONVERGENCE_DURATION
     attribute_deprecated
     int64_t convergence_duration;
     #endif
     } AVPacket;
     */
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
    AVCodecParameters *in_codecpar;
    
    
    bool haveCodec = false;
    //获取环境中所有的流
    int streamChannl = fmt_ctx->nb_streams;
    for(int i = 0;i<streamChannl;i++){
        
        //从格式上下文中获取流
        in_stream = fmt_ctx->streams[i];
        in_codecpar = in_stream->codecpar;
        enum AVMediaType mediaType = in_codecpar->codec_type;
        
        char *enumName;
        switch (mediaType) {
            case -1:
                enumName = "AVMEDIA_TYPE_UNKNOWN";
                break;
            case 0:
                enumName = "AVMEDIA_TYPE_VIDEO";
                break;
            case 1:
                enumName = "AVMEDIA_TYPE_AUDIO";
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
        
        if (mediaType == AVMEDIA_TYPE_AUDIO) {
            in_codecpar = in_stream->codecpar;
            haveCodec = true;
            break;
        }
        
    }
    if (!haveCodec) {
        av_log(NULL,AV_LOG_ERROR,"编解码器类型无效");
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
    }
    
    //设置输出格式上下文的容器格式
    ofmt_ctx->oformat = output_fmt;
    
    /*
     创建一个输出流
     参数1(AVFormatContext):格式上下文
     参数2:编码器
     */
    out_stream = avformat_new_stream(ofmt_ctx,NULL);
    
    //要在视频中获取音频流则多媒体合作中至少有两路流
    if(fmt_ctx->nb_streams<2){
        av_log(NULL, AV_LOG_ERROR, "the number of stream is too less!\n");
        exit(1);
    }
    
    //复制编码器到输出流的编码器
    if ((err_code = avcodec_parameters_copy(out_stream->codecpar,in_codecpar)) < 0) {
        av_strerror(err_code,errors,1024);
        av_log(NULL,AV_LOG_ERROR,"不能复制编码器参数到输出流中:%s,%d(%s)\n",dst_filename,
               err_code,errors);
    }
    
    //做一个标记，这里没有用到
    out_stream->codecpar->codec_tag = 0;
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
    /*
     FFmpeg中的时间
     一个GOF的存储和播放
     PTS：第一行，播放的顺序：I    B    B    P
     DTS：第二行，储存的顺序：I    P    B    B
     PTS：Presentation Time Stamp。PTS主要用于度量解码后的视频帧什么时候被显示出来
     DTS：Decode Time Stamp。DTS主要是标识读入内存中的bit流在什么时候开始送入解码器中进行解码。
     如果没有B帧 PTS = DTS 相等
     
     所谓的时间基就是指每个刻度是多少秒，time_base(每个时间刻度是多少秒)，单位是秒
     这是表示帧时间戳的基本时间单位(以秒为单位)
     typedef struct AVRational{
     int num; //< Numerator 分子
     int den; //< Denominator 分母
     } AVRational;
     
     static inline double av_q2d(AVRational a){
     return a.num / (double) a.den;
     }
     
     //计算一桢在整个视频中的时间位置
     timestamp(秒) = pts * av_q2d(st->time_base);
     //计算视频长度的方法：
     time(秒) = st->duration * av_q2d(st->time_base);
     
     pts和dts的值指的是占多少个时间刻度（占多少个格子）。pts和dts的单位不是秒，而是时间刻度。
     如果每秒钟的帧率是 25帧，那么它的时间基（时间刻度）就是 1/25。也就是说每隔1/25 秒后，显示一帧
     
     tbr: 是我们通常所说的帧率。time base of rate
     tbn: 视频流的时间基。 time base of stream
     tbc: 视频解码的时间基。time base of codec
     
     
     FFmpeg中的所有时间都是以它为一个单位
     #define         AV_TIME_BASE   1000000
     1s = 1000000μs 由此可见，FFmpeg内部的时间单位其实是微秒(μs),而 AV_TIME_BASE_Q
     其实是一种分数的表示形式，其中的1表示分子， AV_TIME_BASE 也就是1000000，表示的是分母，
     所以它其实就是1微秒，也就是 1/1000000 秒
     */
    //从格式上下文读取数据到数据包中
    while (av_read_frame(fmt_ctx, &pkt) >=0) {
        //如果拿到的pkt中的流有和这路流的索引值相等
        if (pkt.stream_index == audio_stream_index) {
            //把输入流的时间基转换到输出流的时间基，第三个参数, 它的作用是计算 "a * b / c" 的值并分五种方式来取整.
            pkt.pts = av_rescale_q_rnd(pkt.pts,in_stream->time_base,out_stream->time_base,
                                       (AV_ROUND_INF|AV_ROUND_PASS_MINMAX));
            //解码顺序时间，和呈现顺序相同
            pkt.dts = pkt.pts;
            /*
             int64_t av_rescale_q(int64_t a, AVRational bq, AVRational cq) av_const;
             av_rescale_q(a,b,c)的作用是，把时间戳从一个时基调整到另外一个时基时候用的函数。其中，a 表式要换算的值；b 表式原来的时间基；c表式要转换的时间基。其计算公式为 a * bq / cq。（q = 1000000）
             */
            //把时间转换为输出流的时间
            pkt.duration = av_rescale_q(pkt.duration,in_stream->time_base,out_stream->time_base);
            /*
             byte position in stream, -1 if unknown
             当前帧数据在文件中的位置（字节为单位），如果做文件移位用到，如果rtsp就没有此数据。
             */
            pkt.pos = -1;
            //帧数据所属流的索引，用来区分音频，视频，和字幕数据。
            pkt.stream_index = 0;
            av_interleaved_write_frame(ofmt_ctx,&pkt);
            /*读取数据，每读取一个数据
             包就是开辟一个空间，引用计数加一，要用 av_packet_unref() 来让引用计数减一
             如果引用计数为零就释放掉。*/
            av_packet_unref(&pkt);
        }
    }
    //创建尾
    av_write_trailer(ofmt_ctx);
    //关闭输入格式上下文
    avformat_close_input(&fmt_ctx);
    //关闭输出格式上下文
    avio_close(ofmt_ctx->pb);
    return 0;
}

@end
