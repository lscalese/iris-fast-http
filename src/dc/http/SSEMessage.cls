Class dc.http.SSEMessage Extends %RegisteredObject
{

Property Event As %String;

Property Id As %String;

Property Retry As %String;

Property Data As list Of %String;

Property Raw As %String;

Property LineSeparator As %String [ InitialExpression = {$Char(10)} ];

Method %OnNew(message As %String, lineSeparator As %String = {$Char(10)}) As %Status
{
    Set ..Raw = message, ..LineSeparator = lineSeparator
    Do ..Parse(message)
    Return $$$OK
}

Method Parse(message As %String) As %Status
{
    For i = 1 : 1 : $Length(message, ..LineSeparator) {
        Set line = $Piece(message, ..LineSeparator, i)
        Continue:line=""
        Set (comment, data, eventType, retry, id) = ""

        If ..IsComment(line, .comment) {
            Continue
        }
        ElseIf ..IsData(line, .data) {
            Do ..Data.Insert(data)
            Continue
        }
        ElseIf ..IsEvent(line, .eventType) {
            Set ..Event = eventType
            Continue
        }
        ElseIf ..IsId(line, .id) {
            Set ..Id = id
            Continue
        }
        ElseIf ..IsRetry(line, .retry) {
            Set ..Retry = retry
            Continue
        }
    }
    Return $$$OK
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

ClassMethod IsEvent(line As %String, Output eventType As %String = "") As %Boolean
{
    If $Extract(line, 1, 6) '= "event:" {
        Return $$$NO
    }
    Set eventType = $Extract(line, 8, *)
    Return $$$YES
}

ClassMethod IsId(line As %String, Output id As %String = "") As %Boolean
{
    If $Extract(line, 1, 3) '= "id:" {
        Return $$$NO
    }
    Set id = $Extract(line, 5, *)
    Return $$$YES
}

ClassMethod IsRetry(line As %String, Output retry As %String = "") As %Boolean
{
    If $Extract(line, 1, 6) '= "retry:" {
        Return $$$NO
    }
    Set retry = $Extract(line, 8, *)
    Return $$$YES
}

ClassMethod IsValidJSONData(data As %String, Output jsonData As %Library.DynamicObject) As %Boolean
{
    Set jsonData = ""

    If data = "" {
        Return $$$NO
    }
    
    Try {
        Set jsonData = {}.%FromJSON(data)
        Return $$$YES
    }
    Catch ex {
        Return $$$NO
    }

    Return $$$NO
}

}
