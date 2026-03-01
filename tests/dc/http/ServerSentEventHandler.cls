Class tests.dc.http.ServerSentEventHandler Extends %UnitTest.TestCase
{

Method TestSimpleData()
{
    Set handler = ##class(dc.http.ServerSentEventHandler).%New()
    Set message = "data: This is a simple message"_$Char(10,10)
    
    // Use Parse which populates Items
    Do handler.Parse(message)
    
    Do $$$AssertEquals(handler.Items.Count(), 1, "Should have 1 item")
    
    Set item = handler.Items.GetAt(1)
    Do $$$AssertEquals(item.Data, "This is a simple message", "Data content mismatch")
    Do $$$AssertEquals(item.EventName, "", "Event name should be empty")
}

Method TestNamedEvent()
{
    Set handler = ##class(dc.http.ServerSentEventHandler).%New()
    Set message = "event: user-login"_$Char(10)_"data: { ""username"": ""bobby"" }"_$Char(10,10)
    
    Do handler.Parse(message)
    
    Do $$$AssertEquals(handler.Items.Count(), 2, "Should have 2 items")
    
    Set item1 = handler.Items.GetAt(1)
    Do $$$AssertEquals(item1.EventName, "user-login", "Event name mismatch")
    
    Set item2 = handler.Items.GetAt(2)
    Do $$$AssertEquals(item2.EventName, "user-login", "Event name mismatch")
    Do $$$AssertEquals(item2.Data, "{ ""username"": ""bobby"" }", "Data content mismatch")
}

Method TestComment()
{
    Set handler = ##class(dc.http.ServerSentEventHandler).%New()
    Set message = ": this is a test stream"_$Char(10,10)
    
    Do handler.Parse(message)
    
    Do $$$AssertEquals(handler.Items.Count(), 1, "Should have 1 item")
    Set item = handler.Items.GetAt(1)
    Do $$$AssertEquals(item.Comment, "this is a test stream", "Comment mismatch")
}

Method TestMultipleMessages()
{
    Set handler = ##class(dc.http.ServerSentEventHandler).%New()
    Set msg1 = "data: message 1"_$Char(10,10)
    Set msg2 = "data: message 2"_$Char(10,10)
    
    Do handler.Parse(msg1_msg2)
    
    Do $$$AssertEquals(handler.Items.Count(), 2, "Should have 2 items")
    
    Set item1 = handler.Items.GetAt(1)
    Do $$$AssertEquals(item1.Data, "message 1", "Item 1 data mismatch")
    
    Set item2 = handler.Items.GetAt(2)
    Do $$$AssertEquals(item2.Data, "message 2", "Item 2 data mismatch")
}

Method TestMixedContent()
{
    Set handler = ##class(dc.http.ServerSentEventHandler).%New()
    Set message = "event: update"_$Char(10)_"data: payload"_$Char(10,10)
    
    Do handler.Parse(message)
    
    Do $$$AssertEquals(handler.Items.Count(), 2, "Logic usually produces one item per line found")
    
    Set item1 = handler.Items.GetAt(1)
    Do $$$AssertEquals(item1.EventName, "update", "Item 1 event name")
    Do $$$AssertEquals(item1.Data, "", "Item 1 data empty")
    
    Set item2 = handler.Items.GetAt(2)
    Do $$$AssertEquals(item2.EventName, "update", "Item 2 event name")
    Do $$$AssertEquals(item2.Data, "payload", "Item 2 data content")
}

Method TestIdField()
{
    Set handler = ##class(dc.http.ServerSentEventHandler).%New()
    Set message = "id: 123"_$Char(10)_"data: message with id"_$Char(10,10)
    Do handler.Parse(message)
    Do $$$AssertEquals(handler.Items.Count(), 2, "Should have 2 items")
    Do $$$AssertEquals(handler.Items.GetAt(1).Raw, "id: 123", "Raw line should be preserved")
    Do $$$AssertEquals(handler.Items.GetAt(2).Data, "message with id", "Data correct")
    Do $$$AssertEquals(handler.Items.GetAt(2).Raw, "data: message with id", "Raw line should be preserved")
}

Method TestBasicSSEHandler()
{
    Kill ^||CallbackData
    Set handler = ##class(tests.dc.http.SSEHandler).%New()
    Do handler.SetThisInstance()
    
    Set stream = ##class(dc.http.Stream).%New()
    Do stream.Write("event: testEvent"_$Char(10)_"data: testData"_$Char(10,10))

    Do $$$AssertTrue($Data(^||CallbackData), "Callback should have been called")
    
    Set callbackItem = $Get(^||CallbackData(1))
    Do $$$AssertEquals($lg(callbackItem,1), "testEvent", "Event name should be 'testEvent'")
    
    Set callbackItem = $Get(^||CallbackData(2))
    Do $$$AssertEquals($lg(callbackItem,2), "testData", "Data should be 'testData'")
}

}
