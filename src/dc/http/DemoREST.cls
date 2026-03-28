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
    <Route Url="/test" Method="GET" Call="Test"/>
    <Route Url="/v1/chat/completions" Method="POST" Call="ChatCompletions"/>
</Routes>
}

ClassMethod Test()
{
    Write $ZVersion
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
