Class dc.aigateway.LMStudioSettings Extends %RegisteredObject
{

Property BaseUrl As %String;

Property ApiKey As %String;

Property ModelName As %String;

Method %OnNew() As %Status
{
    Return $$$OK
}

ClassMethod GetInstance() As dc.aigateway.LMStudioSettings
{
    If $Data(%zLMStudioSettings) {
        Return %zLMStudioSettings
    }
    Set %zLMStudioSettings = ..LoadStoredSettings()
    Return %zLMStudioSettings
}

ClassMethod SetSettings(baseUrl As %String, apiKey As %String, modelName As %String) As %Status
{
    Set instance = ..%New()
    Set instance.BaseUrl = baseUrl
    Set instance.ApiKey = apiKey
    Set instance.ModelName = modelName
    Set %zLMStudioSettings = instance
    Return $$$OK
}

ClassMethod LoadStoredSettings() As dc.aigateway.LMStudioSettings
{
    Set instance = ..%New()
    Set instance.ApiKey = $Get(^lmstudio("ApiKey"), $SYSTEM.Util.GetEnviron("LMSTUDIO_API_KEY"))
    Set instance.BaseUrl = $Get(^lmstudio("BaseUrl"), $SYSTEM.Util.GetEnviron("LMSTUDIO_BASE_URL"))
    Set instance.ModelName = $Get(^lmstudio("ModelName"), $SYSTEM.Util.GetEnviron("LMSTUDIO_DEFAULT_MODEL"))
    Return instance
}

}
