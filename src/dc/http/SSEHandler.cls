Class dc.http.SSEHandler Extends %RegisteredObject
{

Property Adapter As dc.http.SSEAdapter;

Property SwitchIOOnMessage As %Boolean [ InitialExpression = 1 ];

Property IO As %String [ InitialExpression = 0 ];

Property Id As %String;

Property Retry As %String;

Property Messages As list Of dc.http.SSEMessage;

Property MessageSeparator As %String [ InitialExpression = {$Char(10,10)} ];

Property LineSeparator As %String [ InitialExpression = {$Char(10)} ];

/// Used if we receive a partial message that doesn't end with two newlines.
Property Buffer As %String;

ClassMethod Notify(data As %String) As %Status
{
    Return ..GetInstance().BufferProcessing(data)
}

Method BufferProcessing(data As %String) As %Status
{
    ; a valid message to parse should be ending with two newlines.
    ; if it doesn't, it means we have a partial message, and we should wait for the rest of the message before trying to parse it.
    Set ..Buffer = $Replace(..Buffer _ data, $Char(13, 10), $Char(10)) ; Normalize newlines to LF for consistent processing
    If $Extract(..Buffer, *-($Length(..MessageSeparator)-1), *) '= ..MessageSeparator {
        Return $$$OK
    }
    Set sc = ..Process(..Buffer)
    Set ..Buffer = ""
    Return sc
}

Method Process(messages As %String) As %Status
{
    For i = 1 : 1 : $Length(messages, ..MessageSeparator) {
        Set messageString = $Piece(messages, ..MessageSeparator, i)
        Continue:messageString=""
        
        Set message = ##class(dc.http.SSEMessage).%New(messageString, ..LineSeparator)
        Do ..Messages.Insert(message)
        
        Set:message.Id'="" ..Id = message.Id
        Set:message.Retry'="" ..Retry = message.Retry

        Do ..SafeAdapterCall(message)
    }
    Return $$$OK
}

Method SafeAdapterCall(message As dc.http.SSEMessage) As %Status
{
    If '$IsObject(..Adapter) {
        Return $$$OK
    }
    Set io = $IO

    Try {
        Use:..SwitchIOOnMessage ..IO
        Do ..Adapter.OnMessage(message)
        Use:..SwitchIOOnMessage io
    } 
    Catch ex {
        Use:..SwitchIOOnMessage io
        Throw ex
    }
    Return $$$OK
}

ClassMethod SetInstance(instance As dc.http.SSEHandler)
{
    Set %zSSEHandler = instance
}

Method SetThisInstance()
{
    Do ..SetInstance(##this)
}

ClassMethod GetInstance() As dc.http.SSEHandler
{
    Set instance = $Get(%zSSEHandler)
    Return:$IsObject(instance) instance
    Set instance = ..%New()
    Do ..SetInstance(instance)
    Return instance
}

/// Create a new instance of the handler and set it as the current instance to be used for processing incoming messages.
/// Return the newly created instance.
ClassMethod SetAndGetNewInstance() As dc.http.SSEHandler
{
    Set instance = ..%New()
    Do ..SetInstance(instance)
    Return instance
}

Method Reset()
{
    Do ..Messages.Clear()
    Do:$IsObject(..Adapter) ..Adapter.Reset()
}

}
