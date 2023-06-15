# Enables http2 analyzer
@load http2

module ProtobufAnalyzer;

# Enable or disable debug messages
global ProtobufAnalyzerDebug: bool = T;

# =============================== Handling gRPC text event

export {
	type ProtoInfo: record 
    {
		is_protobuf: bool &optional;
        stream: count &optional;
        is_orig: bool &optional;
	};
}

redef record HTTP2::Info += {
    proto:          ProtoInfo  &optional;
};

redef record fa_file += {
    proto:          ProtoInfo  &optional;
};

const protobuf_mime_types = { 
    
    # https://developers.cloudflare.com/support/speed/optimization-file-size/what-will-cloudflare-compress/
    "application/x-protobuf",
    # https://groups.google.com/g/protobuf/c/VAoJ-HtgpAI
    "application/vnd.google.protobuf",
    # https://datatracker.ietf.org/doc/html/draft-rfernando-protocol-buffers-00
    "application/protobuf",
    # https://stackoverflow.com/questions/30505408/what-is-the-correct-protobuf-content-type
    "application/octet-stream",
    # https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-WEB.md
    "application/grpc",
    "application/grpc+proto",
    "application/grpc+json",
    "application/grpc+proto+json",
    "application/grpc-web",
    "application/grpc-web+proto",
    "application/grpc-web+json",
    "application/grpc-web+proto+json",
    "application/grpc-web-text",
    "application/grpc-web-text+proto",
    "application/grpc-web-text+json",
    "application/grpc-web-text+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto",
    "application/grpc-web+proto+json",
    "application/grpc-web+proto+json",
    # NOTE: This is not a valid mime type, but it is used in replies from the server
    "text/plain"
 };

 event zeek_init()
{
	print "ProtobufAnalyzer loaded";
}



event http2_content_type(c: connection, is_orig: bool, stream: count, contentType: string)
{

@if ( ProtobufAnalyzerDebug )
    print "[http2_content_type]";
    print "    contentType", contentType;
    print "    is_orig", is_orig;
    print "    stream", stream;
@endif

    
    if ( contentType in protobuf_mime_types) 
    {
        
@if ( ProtobufAnalyzerDebug )
        print "    contentType is protobuf: ", contentType;
@endif


        c$http2$proto = ProtoInfo();
        c$http2$proto$is_protobuf = T;
        c$http2$proto$stream = stream;
        c$http2$proto$is_orig = is_orig;
    }

    # print "";

}

event file_over_new_connection(f: fa_file, c: connection, is_orig: bool) &priority=5
{
@if ( ProtobufAnalyzerDebug )
    print "[file_over_new_connection]";
@endif
    if ( c?$http2 )
    {
        if ( c$http2?$proto )
        {
            f$proto = c$http2$proto;
        }
		else
		{
@if ( ProtobufAnalyzerDebug )
            print "    no proto info on http2 connection";
@endif

        }
    }
	else
	{
@if ( ProtobufAnalyzerDebug )
        print "    no http2 info on connection";
@endif
    }

    # print "";

}

event file_sniff(f: fa_file, meta: fa_metadata) &priority=5
{
    # print "[file_sniff]";
    Files::add_analyzer(f, Files::ANALYZER_PROTOBUF);

    if (f?$proto)
    {
        if (f$proto?$is_protobuf
            && f$proto$is_protobuf == T)
        {
@if ( ProtobufAnalyzerDebug )
            print "PROTO FILE DETECTED!! Calling ANALYZER_PROTOBUF";
@endif

            Files::add_analyzer(f, Files::ANALYZER_PROTOBUF);
        }
		else
		{
@if ( ProtobufAnalyzerDebug )
            print "    proto info is not protobuf or is_protobuf is false";
@endif

        }

    }
	else 
	{
@if ( ProtobufAnalyzerDebug )
        print "    no proto info on file";
@endif
    }

    # print "";
}

# =============================== Handling gRPC text event
event protobuf_string(f: fa_file, text: string)
{

@if ( ProtobufAnalyzerDebug )
    print "[protobuf_string]";
    print "    text", text;
@endif


    local is_sql_injection = Demo::ProtobufAnalyzer::is_sql_injection(text, |text|);

@if ( ProtobufAnalyzerDebug )
    print "    is_sql_injection", is_sql_injection;

    if ( is_sql_injection )
    {
        print "    ===> SQL INJECTION DETECTED!! *** ";
    }

    print "";
@endif


}