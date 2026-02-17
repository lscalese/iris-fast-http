Class dc.aigateway.LMStudioStreamHandler Extends dc.http.StreamModeHandlerAbstract
{

Property endMessage As %DynamicObject;

Method OnMessage(message As %String) As %Boolean
{
    ;Write !,"Received message: "
    Set splitMsg = $ListFromString(message, $Char(10,10)), ptr = 0
    While $ListNext(splitMsg, ptr, item) {
        Continue:item=""
        Set utf8Item = $ZConvert($Piece(item, "data: ", 2 , *),"I","UTF8")
        Set msgJsonItem = {}.%FromJSON(utf8Item)
        If msgJsonItem.type = "chat.end" {
            Set ..endMessage = msgJsonItem
            Do ..CleanSystemEvent(..ResourceId)
            Return $$$NO
        }
        ElseIf msgJsonItem.type = "message.delta" {
            Write $replace($Replace(msgJsonItem.content, $Char(10), $char(10,10)), $Char(10,10), $char(13,10))
        }
    }
    Return $$$YES
}

}
