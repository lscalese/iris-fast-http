# Demo: OpenAI API Streaming with IRIS FastHTTP

This demo illustrates how to set up a passthrough for the OpenAI API with streaming support using the `csp-test-1` branch.

## 1. Installation

Clone the repository, switch to the specific branch, and start the environment using Docker:

```bash
git clone -b csp-test-1 https://github.com/lscalese/iris-fast-http.git
cd iris-fast-http
docker compose build --no-cache
docker compose up -d
```

## 2. Configuration

To use the OpenAI API, you must configure your API key in the IRIS instance. Open a terminal and run:

```objectscript
Set ^APIKey = "sk-..." ; your OpenAI API key
```

## 3. Testing the Demo

### Web Interface
Access the built-in chat interface at:
[http://localhost:42600/csp/ui/demo/chat.html](http://localhost:42600/csp/ui/demo/chat.html)

### REST Endpoint
The backend logic is implemented in [dc.http.DemoRest](https://github.com/lscalese/iris-fast-http/blob/csp-test-1/src/dc/http/DemoREST.cls). You can adapt this class to match your specific testing requirements.