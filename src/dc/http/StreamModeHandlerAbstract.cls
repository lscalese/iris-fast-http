Class dc.http.StreamModeHandlerAbstract Extends %RegisteredObject
{

/// cannot contains special characters (underscore is not allowed) 
Property ResourceId As %String;

Property SystemEventTimeout As %Integer [ InitialExpression = 1 ];

Property SystemEventMaxWait As %Integer [ InitialExpression = 60 ];

Property StopOnMessageContains As %String [ InitialExpression = "[~~~exit~~~]" ];

Method %OnNew(resourceId As %String) As %Status
{
    Set ..ResourceId = resourceId
    If resourceId '= "" {
        Do ..CreateSystemEvent(resourceId)
    }
    Return $$$OK
}

ClassMethod CleanSystemEvent(resourceId As %String) As %Status
{
    If $SYSTEM.Event.Defined(resourceId) {
        Do $SYSTEM.Event.Clear(resourceId)
        Do $SYSTEM.Event.Delete(resourceId)
    }
    Return $$$OK
}

ClassMethod CreateSystemEvent(resourceId As %String) As %Integer
{
    Do ..CleanSystemEvent(resourceId)
    Return $SYSTEM.Event.Create(resourceId)
}

Method Listen() As %Status
{
    Set start = $ZHorolog
    For  {
        Set result = $SYSTEM.Event.WaitMsg(..ResourceId, ..SystemEventTimeout)
        Set code = $ListGet(result, 1)
        Set data = $ListGet(result, 2)
        Quit:code=-1 ;event deleted
        If code = 1, data '= "" {
            If '..OnMessage(data) {
                Quit
            }
            If ..StopOnMessageContains '= "", data [ ..StopOnMessageContains {
                Quit
            }   
        }
        Quit:($ZHorolog - start > ..SystemEventMaxWait)
    }
    Do ..CleanSystemEvent(..ResourceId)
    Return $$$OK
}

Method OnMessage(message As %String) As %Boolean
{
    Return $$$YES
}

}
