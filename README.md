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
- `stream_mode`: Resource ID for streaming responses (see Advanced Usage, will be explained later /*todo*/).

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
