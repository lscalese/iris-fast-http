Class tests.dc.http.SSEHandler Extends %UnitTest.TestCase
{

/// Cleanup before each test to ensure isolation (the %zSSEHandler singleton)
Method OnBeforeOneTest() As %Status
{
    Kill %zSSEHandler
    Return $$$OK
}

Method OnAfterOneTest() As %Status
{
    Kill %zSSEHandler
    Return $$$OK
}

Method TestSingletonInstance()
{
    // Test if GetInstance always returns the same instance
    Set handler1 = ##class(dc.http.SSEHandler).GetInstance()
    Set handler2 = ##class(dc.http.SSEHandler).GetInstance()
    
    Do $$$AssertEquals(handler1, handler2, "GetInstance should return the same object (Singleton)")
}

Method TestNewInstanceSeparation()
{
    // Test if SetAndGetNewInstance forces a new creation
    Set handler1 = ##class(dc.http.SSEHandler).GetInstance()
    Set handler2 = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    
    Do $$$AssertNotEquals(handler1, handler2, "SetAndGetNewInstance should create a new object")
}

Method TestProcessSingleMessage()
{
    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    // Disable IO switching for unit tests to avoid device errors
    Set handler.SwitchIOOnMessage = 0 
    
    Set msg = "data: hello world" _ $Char(10,10)
    Do handler.Process(msg)
    
    Do $$$AssertEquals(handler.Messages.Count(), 1, "Should have processed 1 message")
    Set sseMsg = handler.Messages.GetAt(1)
    
    // Note: This assumes you have applied the previous changes to SSEMessage
    // If Data is a list:
    Do $$$AssertEquals(sseMsg.Data.GetAt(1), "hello world", "Message content is incorrect")
}

Method TestProcessMultipleMessages()
{
    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    Set handler.SwitchIOOnMessage = 0 
    
    Set sep = handler.MessageSeparator // Default is $c(10,10)
    Set stream = "event: evt1"_$c(10)_"data: one" _ sep _ "event: evt2"_$c(10)_"data: two" _ sep
    
    Do handler.Process(stream)
    
    Do $$$AssertEquals(handler.Messages.Count(), 2, "Should have processed 2 messages")
    
    Set msg1 = handler.Messages.GetAt(1)
    Do $$$AssertEquals(msg1.Event, "evt1")
    
    Set msg2 = handler.Messages.GetAt(2)
    Do $$$AssertEquals(msg2.Event, "evt2")
}

Method TestStateUpdateIdAndRetry()
{
    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    Set handler.SwitchIOOnMessage = 0 
    Set sep = handler.MessageSeparator
    
    // First message with ID and Retry
    Set msg1 = "id: 101"_$c(10)_"retry: 5000"_$c(10)_"data: init"_sep
    Do handler.Process(msg1)
    
    Do $$$AssertEquals(handler.Id, "101", "Handler should have remembered ID")
    Do $$$AssertEquals(handler.Retry, "5000", "Handler should have remembered Retry")
    
    // Second message WITHOUT ID -> Handler must keep the old ID
    Set msg2 = "data: update"_sep
    Do handler.Process(msg2)
    
    Do $$$AssertEquals(handler.Id, "101", "ID must persist in Handler")
    
    // Third message with NEW ID
    Set msg3 = "id: 102"_$c(10)_"data: new id"_sep
    Do handler.Process(msg3)
    
    Do $$$AssertEquals(handler.Id, "102", "ID must be updated")
}

Method TestAdapterCallback()
{
    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    Set handler.SwitchIOOnMessage = 0
    
    // Use a mock to verify the call
    Set mock = ##class(tests.dc.http.MockAdapter).%New()
    Set handler.Adapter = mock
    
    Set stream = "data: test callback"_$c(10,10)
    Do handler.Process(stream)
    
    Do $$$AssertEquals(mock.CallCount, 1, "Adapter should have been called once")
    Do $$$AssertEquals(mock.LastMessage.Data.GetAt(1), "test callback", "Adapter received wrong message")
}

}
