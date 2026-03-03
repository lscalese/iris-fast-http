Class dc.http.SSEMessage Extends %RegisteredObject
{

Property EventName As %String;

Property Data As %String;

Property Comment As %String;

Property Raw As %String;

Method IsNamedEvent() As %Boolean [ CodeMode = expression ]
{
..EventName '= "" && (..Data '= "")
}

Method IsComment() As %Boolean [ CodeMode = expression ]
{
..Comment '= ""
}

Method IsUnnamedEvent() As %Boolean [ CodeMode = expression ]
{
..EventName = "" && (..Data '= "")
}

Method IsValidJSONData(Output jsonData As %Library.DynamicObject) As %Boolean
{
    Set jsonData = ""

    If ..Data = "" {
        Return $$$NO
    }
    
    Try {
        Set jsonData = {}.%FromJSON(..Data)
        Return $$$YES
    }
    Catch ex {
        Return $$$NO
    }

    Return $$$NO
}

}
