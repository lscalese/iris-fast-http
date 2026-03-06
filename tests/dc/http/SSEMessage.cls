Class tests.dc.http.SSEMessage Extends %UnitTest.TestCase
{

Method TestSimpleMessage()
{
    Set raw = "data: hello world"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Do $$$AssertEquals(msg.Data.Count(), 1, "Devrait avoir une ligne de data")
    Do $$$AssertEquals(msg.Data.GetAt(1), "hello world", "Le contenu data est incorrect")
}

Method TestMultiLineData()
{
    Set LF = $Char(10)
    Set raw = "data: line 1" _ LF _ "data: line 2"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Do $$$AssertEquals(msg.Data.Count(), 2, "Devrait avoir 2 lignes de data")
    Do $$$AssertEquals(msg.Data.GetAt(1), "line 1")
    Do $$$AssertEquals(msg.Data.GetAt(2), "line 2")
}

Method TestEventAndId()
{
    Set LF = $Char(10)
    Set raw = "event: update" _ LF _ "id: 123" _ LF _ "data: some update"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Do $$$AssertEquals(msg.Event, "update", "L'événement devrait être 'update'")
    Do $$$AssertEquals(msg.Id, "123", "L'ID devrait être '123'")
    Do $$$AssertEquals(msg.Data.GetAt(1), "some update")
}

Method TestRetry()
{
    Set raw = "retry: 5000"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Do $$$AssertEquals(msg.Retry, "5000", "Le retry devrait être 5000")
}

Method TestCommentIgnored()
{
    Set LF = $Char(10)
    Set raw = ": this is a comment" _ LF _ "data: actual data"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Do $$$AssertEquals(msg.Data.Count(), 1, "Le commentaire ne doit pas ajouter de data")
    Do $$$AssertEquals(msg.Data.GetAt(1), "actual data")
}

Method TestJsonParsing()
{
    Set raw = "data: {""status"": ""ok"", ""value"": 42}"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Set data = msg.Data.GetAt(1)
    
    Set isValid = ##class(dc.http.SSEMessage).IsValidJSONData(data, .jsonObj)
    Do $$$AssertTrue(isValid, "Le JSON devrait être valide")
    Do $$$AssertEquals(jsonObj.status, "ok")
    Do $$$AssertEquals(jsonObj.value, 42)
}

Method TestInvalidJson()
{
    Set raw = "data: {invalid json}"
    Set msg = ##class(dc.http.SSEMessage).%New(raw)
    Set isValid = ##class(dc.http.SSEMessage).IsValidJSONData(msg.Data.GetAt(1), .jsonObj)
    Do $$$AssertNotTrue(isValid, "Le JSON invalide devrait retourner $$$NO")
}

}
