# FastHTTP

FastHTTP is a lightweight wrapper for `%Net.HttpRequest` in InterSystems IRIS, designed to simplify HTTP requests with a concise API and built-in JSON support.

## Installation

### With Docker

Clone the repository and run:

```bash
docker-compose up -d
```

### With ZPM

```objectscript
zpm "install fast-http"
```

## Usage

### Simple GET Request

```objectscript
Set response = ##class(dc.http.FastHTTP).DirectGet("url=https://httpbin.org/get")
write response.%ToJSON()
```

### POST Request with JSON Body

```objectscript
Set body = {"name": "Iris", "type": "Database"}
Set response = ##class(dc.http.FastHTTP).DirectPost("url=https://httpbin.org/post", body)
write response.%ToJSON()
```

### PUT & DELETE

```objectscript
// PUT
Set response = ##class(dc.http.FastHTTP).DirectPut("url=https://httpbin.org/put", {"update": 1})

// DELETE
Set response = ##class(dc.http.FastHTTP).DirectDelete("url=https://httpbin.org/delete")
```

### Configuration String

FastHTTP uses a configuration string to set up the request. You can pass it to the `FastHTTP` constructor or the `Direct...` methods.

Format: `"key=value,key2=value2"`

Supported keys:
- `url`: The full URL to send the request to.
- `Header_<Name>`: Sets a request header. Ex: `Header_Authorization=Bearer 123`

Example with headers:

```objectscript
Set config = "url=https://api.example.com/data,Header_Authorization=Bearer mytoken,Header_Content-Type=application/json"
Set response = ##class(dc.http.FastHTTP).DirectGet(config)
```

### Accessing the Client Instance

The `Direct...` methods also return the `client` instance as an output parameter if you need to access the underlying `%Net.HttpRequest` or response metadata.

```objectscript
Set response = ##class(dc.http.FastHTTP).DirectGet("url=https://httpbin.org/get", , .client)
Write "Status Code: ", client.HttpRequest.HttpResponse.StatusCode
```

### Server-Sent Events (SSE) / AI Streaming

FastHTTP has built-in support for Server-Sent Events (SSE), making it extremely easy to consume streaming APIs like OpenAI, Anthropic, or any LLM in real-time. Instead of waiting for the full response to complete, you can process chunks on the fly.

To consume an SSE stream, follow these steps:
1. Create a `dc.http.Stream` which will hold the incoming bits.
2. Link it to a `dc.http.SSEHandler`, configured with an Adapter (a class extending `dc.http.SSEAdapter`).
3. Pass your stream to the FastHTTP request.

```objectscript
// 1. Create a Stream that will receive the SSE chunks as they arrive
Set stream = ##class(dc.http.Stream).%New()

// 2. Create an Adapter to process each SSE Message (FastHTTP provides some basic ones, or you can create your own extending `dc.http.SSEAdapter`)
//    Set adapter = ##class(dc.http.SSEBasicAdapter).%New()
// For ChatGPT-like formatting, you could use: ##class(dc.http.SSEChatConsoleAdapter).%New()
Set adapter = ##class(dc.http.SSEChatConsoleAdapter).%New()

// 3. Create the SSE Handler and link the adapter
Set handler = ##class(dc.http.SSEHandler).%New(adapter)
Set stream.SSEHandler = handler

// 4. Set up your HTTP request
Set config = "url=https://api.openai.com/v1/chat/completions,Header_Authorization=Bearer <YOUR_TOKEN>,Header_Accept=text/event-stream"
Set body = {
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Tell me a short story."}],
    "stream": true
}

// 5. Fire the request - The adapter's OnMessage() will be triggered in real-time!
Set response = ##class(dc.http.FastHTTP).DirectPost(config, body, .client, stream)
```

To parse the stream your own way, simply create a class extending `dc.http.SSEAdapter` and override the `OnMessage(message As dc.http.SSEMessage) As %Status` method.

### Testing with the Mock Server

If you have started the workspace using Docker, a small `sse-mock` service is included in the `docker-compose.yml`. You can use it to simulate an AI streaming response without needing a real API key or internet connection.

Once the mock server is running, you can test the SSE behavior in the IRIS terminal with the following snippet:

```objectscript
Set stream = ##class(dc.http.SSEChatConsoleAdapter).GetStream()
Set config = "url=http://sse-mock:5000/stream,timeout=10"
Set response = ##class(dc.http.FastHTTP).DirectGet(config, , , stream)
```
