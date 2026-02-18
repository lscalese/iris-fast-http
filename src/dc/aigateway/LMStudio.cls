Include FastHTTP

/// usage:
/// Initialize settings with ##class(dc.aigateway.LMStudioSettings).SetSettings(baseUrl, apiKey, modelName)
/// Call ##class(dc.aigateway.LMStudio).ListModels() to show available models
/// Use ##class(dc.aigateway.LMStudio).LoadModel(instanceId) to load a model before using it for chat
/// Then call ##class(dc.aigateway.LMStudio).Chat(message) to send a chat message to the model. Message should be a dynamic object with the following format : {"model": "modelName", "input": "your message", "system_prompt": "", "temperature": 0.7}
/// See ##class(dc.aigateway.LMStudio).Session() for an example of a session implementation.
Class dc.aigateway.LMStudio
{

Parameter CHATENDPOINT = "/api/v1/chat";

Parameter LISTMODELSENDPOINT = "/api/v1/models";

Parameter LOADMODELENDPOINT = "/api/v1/models/load";

Parameter DOWNLOADMODELENDPOINT = "/api/v1/models/download";

Parameter UNLOADMODELENDPOINT = "/api/v1/models/unload";

ClassMethod Chat(message As %DynamicObject, Output client As dc.http.FastHTTP) As %DynamicObject
{
    Set settings = ##class(dc.aigateway.LMStudioSettings).GetInstance()
    Return ##class(dc.http.FastHTTP).DirectPost($$$f("url={settings.BaseUrl_..#CHATENDPOINT},header_Authorization=Bearer {settings.ApiKey}"), message, .client)
}

ClassMethod UnloadModel(instanceId As %String, Output client As dc.http.FastHTTP) As %DynamicObject
{
    Set settings = ##class(dc.aigateway.LMStudioSettings).GetInstance()
    Return ##class(dc.http.FastHTTP).DirectPost($$$f("url={settings.BaseUrl_..#UNLOADMODELENDPOINT},Header_Authorization=Bearer {settings.ApiKey}"), {"instance_id": (instanceId)}, .client)
}

ClassMethod LoadModel(instanceId As %String, Output client As dc.http.FastHTTP) As %Status
{
    Set settings = ##class(dc.aigateway.LMStudioSettings).GetInstance()
    Return ##class(dc.http.FastHTTP).DirectPost($$$f("url={settings.BaseUrl_..#LOADMODELENDPOINT},Header_Authorization=Bearer {settings.ApiKey}"), {"model": (instanceId)}, .client)
}

ClassMethod ListModels(Output client As dc.http.FastHTTP) As %DynamicObject
{
    Set settings = ##class(dc.aigateway.LMStudioSettings).GetInstance()
    Return ##class(dc.http.FastHTTP).DirectGet($$$f("url={settings.BaseUrl_..#LISTMODELSENDPOINT},Header_Authorization=Bearer {settings.ApiKey}"), , .client)
}

ClassMethod ChatStreamMode(message As %DynamicObject, streamHandler As dc.aigateway.LMStudioStreamHandler) As %DynamicObject
{
    Try {
        Set settings = ##class(dc.aigateway.LMStudioSettings).GetInstance()
        Job ##class(dc.http.FastHTTP).DirectPost($$$f("url={settings.BaseUrl_..#CHATENDPOINT},header_Content-Type=application/json,header_Authorization=Bearer {settings.ApiKey},stream_mode={streamHandler.ResourceId}"), message.%ToJSON(), "")
        Do streamHandler.Listen()
    } Catch ex {
        Throw ex
    }
    Return ""
}

ClassMethod TestStreamMode()
{
    Set messageTemplate = {
        "model": "mistralai/ministral-3-3b", 
        "input": "Salut mini!",
        "system_prompt": "",
        "temperature": 0.7,
        "stream": true
    }
    Set streamModeHandler = ##class(dc.aigateway.LMStudioStreamHandler).%New("lmstudio"_$JOB)
    Do ..ChatStreamMode(messageTemplate, streamModeHandler)
    Quit
}

ClassMethod Session() As %Status
{
    Set messageTemplate = {
        "model": "mistralai/ministral-3-3b", 
        "input": "",
        "system_prompt": "Votre interlocuteur est un roi, parlez lui avec respect et politesse.",
        "temperature": 0.7,
        "stream": true
    }
    Set previousResponseId = ""
    Write !,"Ask something to start a session.  Type ""exit"" to quit.",!

    For  {
        Write !,!, "Your message: "
        Read input
        Write !,!, "Response: ",!
        If input = "exit" Return $$$OK
        Set message = {}.%FromJSON(messageTemplate.%ToJSON())
        Set message.input = input
        Do:previousResponseId'="" message.%Set("previous_response_id", previousResponseId)

        Set streamModeHandler = ##class(dc.aigateway.LMStudioStreamHandler).%New("lmstudio"_$JOB)
        Do ..ChatStreamMode(message, streamModeHandler)    
        Set previousResponseId = streamModeHandler.endMessage.result.%Get("response_id")
        Kill streamModeHandler
    }
    Return $$$OK
}

}
