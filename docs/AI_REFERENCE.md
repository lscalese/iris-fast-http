# FastHTTP AI Reference Manual

This document serves as an exhaustive technical reference for AI Assistants (Copilot, Cursor, etc.) generating code for the `iris-fast-http` project.

## 1. The Configuration String (`Config String`)

The core of `dc.http.FastHTTP` lies in initializing requests via a formatted character string.
- **General Format:** `key1=value1,key2=value2`
- **Escape Characters:** Commas `,` and backslashes `\` in values must be escaped with `\` (e.g., `Header_Authorization=Bearer 123\,456\\789`).

### 1.1 Special Keys

| Key (Case-insensitive) | Description |
|-------------------------|-------------|
| `url` | The target URL (e.g., `https://api.example.com/v1/data?query=1&page=2`). If the protocol is `https`, `SSLConfiguration` is automatically set to `DefaultSSL` if empty. |
| `Header_<Name>` | Any parameter starting with `Header_` or `header_` is transformed into an HTTP header (e.g., `Header_Content-Type=application/json`). |

### 1.2 Keys Mapped to `%Net.HttpRequest`

All these keys directly modify the corresponding properties of the underlying `%Net.HttpRequest`. They are case-insensitive.

| Key | `%Net.HttpRequest` Equivalent | Notes |
|---|---|---|
| `Timeout` | `Timeout` | Waiting time (seconds). |
| `OpenTimeout` | `OpenTimeout` | TCP socket open timeout. |
| `ProxyServer` | `ProxyServer` | Proxy server address. |
| `ProxyPort` | `ProxyPort` | Proxy server port. |
| `ProxyHTTPS` | `ProxyHTTPS` | Whether the proxy is HTTPS. |
| `SSLConfiguration` | `SSLConfiguration` | Must match an SSL configuration on the IRIS server. If manually set, it is not replaced by `DefaultSSL`. |
| `FollowRedirect` | `FollowRedirect` | Automatically follow HTTP redirects (true/false). |
| `Location` | `Location` | Request path (often extracted from the `url` key). |
| `SSLCheckServerIdentity` | `SSLCheckServerIdentity` | Strict SSL certificate verification. |

> **Full list of supported keys:** followredirect, forcereusedevice, localinterface, location, nodefaultcontentcharset, opentimeout, postgzip, proxyhttps, proxyport, proxyserver, readrawmode, requestheadercharset, returngzipresponse, sslcheckserveridentity, sslconfiguration, sockettimeout, timeout, writerawmode, writetimeout.

### 1.3 Macro and String Interpolation

Always include the macro at the top of the file using `Include FastHTTP`.
This allows for easy string interpolation when building the configuration string using the `$$$f()` macro.

Example:
```objectscript
Include FastHTTP

// ...
Set key = "my_secret_token"
Set configString = $$$f("url=https://httpbin.org/get,Header_Authorization=Bearer {key}")
```

## 2. Main Public API

### 2.1 "Direct" Sending (1-liner)

Returns a `%DynamicObject` encapsulating the response.

```objectscript
// Common Syntax:
// ClassMethod Direct<Method>(config As %String, body = "", Output client As dc.http.FastHTTP, responseStream As %Stream.GlobalBinary = "") As %DynamicObject

// IMPORTANT INFO: Always retrieve ".client" (pass-by-reference argument) to facilitate debugging for the developer!
Set response = ##class(dc.http.FastHTTP).DirectGet($$$f("url={myUrl},Timeout=30"), , .client)
Set response = ##class(dc.http.FastHTTP).DirectPost($$$f("url=.../post,Header_Authorization=Bearer {key}"), {"key":"value"}, .client)
Set response = ##class(dc.http.FastHTTP).DirectPut("url=.../put", {"key":"value"}, .client)
Set response = ##class(dc.http.FastHTTP).DirectDelete("url=.../delete", , .client)
```

**Response object structure (`response`):**
```json
{
  "statusCode": 200,
  "reasonPhrase": "OK",
  "contentType": "application/json",
  "data": { ... } // %DynamicObject if the response is JSON, otherwise a string or raw stream.
}
```

## 3. SSE Implementation (Server-Sent Events) for LLMs

To receive asynchronous streams (e.g., OpenAI / Anthropic streaming), `FastHTTP` uses `dc.http.Stream` for processing.

1. **Create an SSE Handler:** `Set handler = ##class(dc.http.SSEHandler).%New(adapter)`
2. **Initialize a Response Stream linked to the Handler:** `Set responseStream = ##class(dc.http.Stream).%New()` with `responseStream.SSEHandler = handler`
3. **Make the call via `Direct...`:** Specify `responseStream` as the 4th argument.

### SSE Model

The adapter passed to the `SSEHandler` must inherit from `dc.http.SSEAdapter` and implement the method:
```objectscript
Method OnMessage(message As dc.http.SSEMessage) As %Status
{
    // message.Event (e.g., "message", "error")
    // message.Data (the text payload, often convertible to JSON with {}.%FromJSON(message.Data))
    // message.Id
}
```
