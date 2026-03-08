Class dc.http.SSEHandler Extends %RegisteredObject
{

Property Adapter As dc.http.SSEAdapter;

Property SwitchIOOnMessage As %Boolean [ InitialExpression = {$$$YES} ];

Property IO As %String [ InitialExpression = 0 ];

Property Id As %String;

Property Retry As %String;

Property Messages As list Of dc.http.SSEMessage;

Property MessageSeparator As %String [ InitialExpression = {$Char(10,10)} ];

Property LineSeparator As %String [ InitialExpression = {$Char(10)} ];

/// Used if we receive a partial message that doesn't end with two newlines.
Property Buffer As %String;

/// if the Buffer property exceeds this threshold, we will flush it until its last new line separator, 
/// to avoid potential memory issues with very large messages that don't have proper newlines.
Property BufferSizeAutoFlushThreshold As %Integer [ InitialExpression = {1024 * 1024} ];

/// Max buffer size before throwing an error to avoid memory issues with malformed streams that never end with newlines.
/// Default is 3 600 000 characters.
Property MaxBufferSize As %Integer [ InitialExpression = 3600000 ];

Method %OnNew(adapter As dc.http.SSEAdapter = "", switchIOOnMessage As %Boolean = "", io As %String = "") As %Status
{
    Set:adapter'="" ..Adapter = adapter
    Set:switchIOOnMessage'="" ..SwitchIOOnMessage = switchIOOnMessage
    Set:io'="" ..IO = io
    Return $$$OK
}

Method BufferProcessing(data As %String) As %Status
{
    Set sc = $$$OK
    ; A valid message to parse should be ending with two newlines.
    ; If it doesn't, it means we have a partial message, and we should wait for the rest of the message before trying to parse it.
    Set ..Buffer = $Replace(..Buffer _ data, $Char(13, 10), $Char(10)) ; Normalize newlines to LF for consistent processing
    For  {
        Set endOfMessagePos = $Find(..Buffer, ..MessageSeparator)
        Quit:endOfMessagePos=0
        Set message = $Extract(..Buffer, 1, endOfMessagePos - 1)
        Set ..Buffer = $Extract(..Buffer, endOfMessagePos, *)
        Set sc = $$$ADDSC(sc, ..Process(message))
    }

    If $Length(..Buffer) < ..BufferSizeAutoFlushThreshold {
        Return sc
    }

    ; If buffer exceeds threshold, flush up to the last newline to avoid memory issues
    For  {
        Set newLinePosition = $Find(..Buffer, ..LineSeparator)
        Quit:newLinePosition=0
        Set message = $Extract(..Buffer, 1, newLinePosition - 1)
        Set ..Buffer = $Extract(..Buffer, newLinePosition, *)
        Set sc = $$$ADDSC(sc, ..Process(message))
    }
    
    If $Length(..Buffer) > ..MaxBufferSize { 
        Set ..Buffer = ""
        $$$ThrowStatus($$$ERROR($$$GeneralError, "SSE Buffer overflow protector"))
    }

    Return sc
}

Method Flush() As %Status
{
    If ..Buffer = "" {
        Return $$$OK
    }
    Set sc = ..Process(..Buffer)
    Set ..Buffer = ""
    Return sc
}

Method Process(messageString As %String) As %Status
{
    Set message = ##class(dc.http.SSEMessage).%New(messageString, ..LineSeparator)
    Do ..Messages.Insert(message)
    
    Set:message.Id'="" ..Id = message.Id
    Set:message.Retry'="" ..Retry = message.Retry

    Return ..SafeAdapterCall(message)
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
    Catch ex {  ; Ensure to restore original IO in case of an error in the adapter
        Use:..SwitchIOOnMessage io
        Throw ex
    }
    Return $$$OK
}

Method Reset()
{
    Do ..Messages.Clear()
    Set ..Buffer = ""
    Do:$IsObject(..Adapter) ..Adapter.Reset()
}

}
