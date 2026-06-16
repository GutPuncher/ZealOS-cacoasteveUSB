#define BROWSER_CACHE_DIR	"::/Tmp/Browser"
#define BROWSER_MAX_REDIRECTS	5
#define BROWSER_HISTORY_MAX	64
#define BROWSER_URL_MAX		512
#define BROWSER_LINE_MAX		4096

#define BROWSER_ERR_NONE		0
#define BROWSER_ERR_HTTPS		-1
#define BROWSER_ERR_PARSE		-2
#define BROWSER_ERR_DNS			-3
#define BROWSER_ERR_CONNECT		-4
#define BROWSER_ERR_HTTP		-5
#define BROWSER_ERR_FILE		-6
#define BROWSER_ERR_TOO_MANY_REDIRECTS	-7

class CBrowserURL
{
	U8	scheme[16];
	U8	*host;
	U16	port;
	U8	*path;
	U8	*query;
	U8	*full;
};

class CHTTPResponse
{
	I64	status;
	U8	*content_type;
	U8	*location;
	I64	content_length;
	U8	*body_path;
};

class CBrowser
{
	CDoc	*doc;
	U8	*current_url;
	U8	*history[BROWSER_HISTORY_MAX];
	I64	history_len;
	I64	history_pos;
};
