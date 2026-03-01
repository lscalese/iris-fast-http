Class dc.http.ServerSentEventHandler Extends %RegisteredObject
{

Property MessageSeparator As %String [ InitialExpression = {$Get(^ServerSentEventHandler("MessageSeparator"), $Char(10,10))} ];

Property LineSeparator As %String [ InitialExpression = {$Get(^ServerSentEventHandler("LineSeparator"), $Char(10))} ];

Property Items As %ListOfObjects;

ClassMethod NotifyEvent(message As %String) As %Status
{
    Return ..GetInstance().Parse(message) ; retrieve the previously created instance of the handler and call Parse to process the incoming message
}

Method Parse(event As %String) As %Status
{
    Set splitMsg = $ListFromString(event, ..MessageSeparator), ptr = 0
    While $ListNext(splitMsg, ptr, item) {
        Continue:item=""
        Set SSEMessages = ..ProcessItem(item)
        For i=1:1:SSEMessages.Count() {
            Set sseMessage = SSEMessages.GetAt(i)
            Do ..Items.Insert(sseMessage)
            Do ..OnMessage(sseMessage)
        }
    }
    Return $$$OK
}

/// Override this method in subclasses to handle incoming messages
/// Keep in mind when this method is called, the current $IO is a |TCP| device and not the standard output, 
/// so if you want to write to the console for debugging purposes, you need to save the current $IO and switch to 0 before writing, 
/// then switch back to the original $IO after you're done.
/// For example:
/// Set io = $IO
/// USE 0
/// Write "Event: ", item.EventName, !
/// Write "Data: ", item.Data, !
/// Write "Comment: ", item.Comment, !
/// Write "----", !
/// USE io
ClassMethod OnMessage(item As dc.http.ServerSentEventMessage) As %Status
{
    /*
    Set io = $IO
    USE 0
    Write "Event: ", item.EventName, !
    Write "Data: ", item.Data, !
    Write "Comment: ", item.Comment, !
    Write "----", !
    USE io
    */
    Return $$$OK
}

ClassMethod ProcessItem(messageItem As %String, lineSeparator As %String = {$Get(^ServerSentEventHandler("LineSeparator"), $Char(10))}) As %ListOfObjects
{
    Set previousLine = ""

    Set listParsedItems = ##class(%ListOfObjects).%New()

    For i = 1 : 1 : $Length(messageItem, lineSeparator) {
        Set line = $Piece(messageItem, lineSeparator, i)
        Continue:line=""

        Set parsedItem = ##class(dc.http.ServerSentEventMessage).%New()
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

ClassMethod SetInstance(instance As dc.http.ServerSentEventHandler)
{
    Set %zSSEHandler = instance
}

Method SetThisInstance()
{
    Do ..SetInstance(##this)
}

ClassMethod GetInstance() As dc.http.ServerSentEventHandler
{
    Set instance = $Get(%zSSEHandler)
    Return:$IsObject(instance) instance
    Set instance = ..%New()
    Do ..SetInstance(instance)
    Return instance
}

}
