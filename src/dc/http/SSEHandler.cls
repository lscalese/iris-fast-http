Class dc.http.SSEHandler Extends %RegisteredObject
{

Property MessageSeparator As %String [ InitialExpression = {$Get(^ServerSentEventHandler("MessageSeparator"), $Char(10,10))} ];

Property LineSeparator As %String [ InitialExpression = {$Get(^ServerSentEventHandler("LineSeparator"), $Char(10))} ];

Property Items As %ListOfObjects;

Property Adapter As dc.http.SSEAdapter;

Property SwitchIOOnMessage As %Boolean [ InitialExpression = 1 ];

Property IO As %String [ InitialExpression = 0 ];

ClassMethod Notify(message As %String) As %Status
{
    Return ..GetInstance().Parse(message) ; retrieve the previously created instance of the handler and call Parse to process the incoming message
}

Method Parse(event As %String) As %Status
{
    Set io = $IO
    Set splitMsg = $ListFromString(event, ..MessageSeparator), ptr = 0
    While $ListNext(splitMsg, ptr, item) {
        Continue:item=""
        Set SSEMessages = ..ProcessItem(item)
        For i=1:1:SSEMessages.Count() {
            Set sseMessage = SSEMessages.GetAt(i)
            Do ..Items.Insert(sseMessage)
            Continue:'$IsObject(..Adapter)
            Try {
                Use:..SwitchIOOnMessage ..IO
                Do ..Adapter.OnMessage(sseMessage)
                Use:..SwitchIOOnMessage io
            } Catch ex {
                Use:..SwitchIOOnMessage io
                Throw ex
            }
        }
    }
    Return $$$OK
}

ClassMethod ProcessItem(messageItem As %String, lineSeparator As %String = {$Get(^ServerSentEventHandler("LineSeparator"), $Char(10))}) As %ListOfObjects
{
    Set previousLine = ""

    Set listParsedItems = ##class(%ListOfObjects).%New()

    For i = 1 : 1 : $Length(messageItem, lineSeparator) {
        Set line = $Piece(messageItem, lineSeparator, i)
        Continue:line=""

        Set parsedItem = ##class(dc.http.SSEMessage).%New()
        Set parsedItem.Raw = line

        If ..IsComment(line, .comment) {
            Set parsedItem.Comment = comment
        }
        ElseIf ..IsData(line, .data) {
            If ..IsEventType(previousLine, .eventType) { ; If previous line is event type, we can associate it with this data
                Set parsedItem.EventName = eventType
            }
            Set parsedItem.Data = data
        }
        ElseIf ..IsEventType(line, .eventType) {
            Set parsedItem.EventName = eventType
        }
        
        Do listParsedItems.Insert(parsedItem)

        Set previousLine = line, eventType = "", comment = "", data = ""
    }

    Return listParsedItems
}

ClassMethod IsComment(line As %String, Output comment As %String = "") As %Boolean
{
    If $Extract(line, 1) '= ":" {
        Return $$$NO
    }
    Set comment = $Extract(line, 3, *)
    Return $$$YES
}

ClassMethod IsData(line As %String, Output data As %String = "") As %Boolean
{
    If $Extract(line, 1, 5) '= "data:" {
        Return $$$NO
    }
    Set data = $Extract(line, 7, *)
    Return $$$YES
}

ClassMethod IsEventType(line As %String, Output eventType As %String = "") As %Boolean
{
    If $Extract(line, 1, 6) '= "event:" {
        Return $$$NO
    }
    Set eventType = $Extract(line, 8, *)
    Return $$$YES
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
    Do ..Items.Clear()
    Do:$IsObject(..Adapter) ..Adapter.Reset()
}

}
