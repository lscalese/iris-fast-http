Include FastHTTP

Class dc.http.DemoREST Extends %CSP.REST
{

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

Parameter IgnoreWrites = 0;

/// Description
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/ping" Method="GET" Call="Ping"/>
    <Route Url="/sse/test" Method="GET" Call="Test"/>
    <Route Url="/v1/chat/completions" Method="POST" Call="ChatCompletions"/>
</Routes>
}

ClassMethod Ping() As %Status
{
    Write $ZVersion
    Return $$$OK
}

ClassMethod Test() As %Status
{
    Set %response.AllowOutputFlush = 1
    Set %response.ContentType = "text/event-stream"
    Do %response.SetHeader("Cache-Control", "no-cache")
    Do %response.SetHeader("Connection", "keep-alive")

    // The CSP Gateway buffers output until ~4KB before forwarding to the browser.
    // Sending a padding comment upfront saturates the buffer so subsequent events
    // are delivered immediately without waiting for it to fill.
    Write ": ", $Justify("", 4096), $Char(10)
    Do %response.Flush()

    For content = "Hel", "lo", " world" {
        Try {
            Write "data: ", {"id":($Increment(i)),"choices":[{"delta":{"content":(content)}}]}.%ToJSON(), $Char(10,10)
            Do %response.Flush()
            Hang 1
        } Catch ex {
            Quit
        }
    }
    Try {
        Write "event: done", $Char(10)
        Write "data: [DONE]", $Char(10,10)
        Do %response.Flush()
    } Catch ex {}

    Return $$$OK
}

ClassMethod ChatCompletions() As %Status
{
    Set %response.AllowOutputFlush = 1
    Set %response.ContentType = "text/event-stream"
    
    Set message = {}.%FromJSON(%request.Content)
    Set apiKey = $Get(^APIKey) ; your api key here
    
    ; Set url = "http://host.docker.internal:8080/v1/chat/completions" ; my localai endpoint
    ; Set message.model = "mistralai_ministral-3-8b-reasoning-2512-multimodal" ; force a model
    
    Set url = "https://api.openai.com/v1/chat/completions"
    Set config= $$$f("url={url},header_Authorization=Bearer {apiKey}")

    Set responseStream = ##class(dc.http.SSEPassthroughAdapter).GetStream()
    Set handler = responseStream.SSEHandler
    Set handler.SwitchIOOnMessage = 1
    Set handler.IO = $IO
    
    Set response = ##class(dc.http.FastHTTP).DirectPost(config, message, .client, responseStream)
    If response.statusCode '= 200 {
        Throw ##class(%Exception.General).%New("Chat completion request failed",,,response.%ToJSON())
    }
    Return $$$OK
}

}
