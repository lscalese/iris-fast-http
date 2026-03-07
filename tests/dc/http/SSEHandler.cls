Class tests.dc.http.SSEHandler Extends %UnitTest.TestCase
{

Method TestProcessSingleMessage()
{
    Set handler = ##class(dc.http.SSEHandler).%New()
    // Disable IO switching for unit tests to avoid device errors
    Set handler.SwitchIOOnMessage = 0 
    
    Set msg = "data: hello world" _ $Char(10,10)
    Do handler.BufferProcessing(msg)
    
    Do $$$AssertEquals(handler.Messages.Count(), 1, "Should have processed 1 message")
    Set sseMsg = handler.Messages.GetAt(1)
    
    // Note: This assumes you have applied the previous changes to SSEMessage
    // If Data is a list:
    Do $$$AssertEquals(sseMsg.Data.GetAt(1), "hello world", "Message content is incorrect")
}

Method TestProcessMultipleMessages()
{
    Set handler = ##class(dc.http.SSEHandler).%New()
    Set handler.SwitchIOOnMessage = 0 
    
    Set sep = handler.MessageSeparator // Default is $c(10,10)
    Set stream = "event: evt1"_$c(10)_"data: one" _ sep _ "event: evt2"_$c(10)_"data: two" _ sep
    
    Do handler.BufferProcessing(stream)
    
    Do $$$AssertEquals(handler.Messages.Count(), 2, "Should have processed 2 messages")
    
    Set msg1 = handler.Messages.GetAt(1)
    Do $$$AssertEquals(msg1.Event, "evt1")
    
    Set msg2 = handler.Messages.GetAt(2)
    Do $$$AssertEquals(msg2.Event, "evt2")
}

Method TestStateUpdateIdAndRetry()
{
    Set handler = ##class(dc.http.SSEHandler).%New()
    Set handler.SwitchIOOnMessage = 0 
    Set sep = handler.MessageSeparator
    
    // First message with ID and Retry
    Set msg1 = "id: 101"_$c(10)_"retry: 5000"_$c(10)_"data: init"_sep
    Do handler.BufferProcessing(msg1)
    
    Do $$$AssertEquals(handler.Id, "101", "Handler should have remembered ID")
    Do $$$AssertEquals(handler.Retry, "5000", "Handler should have remembered Retry")
    
    // Second message WITHOUT ID -> Handler must keep the old ID
    Set msg2 = "data: update"_sep
    Do handler.BufferProcessing(msg2)
    
    Do $$$AssertEquals(handler.Id, "101", "ID must persist in Handler")
    
    // Third message with NEW ID
    Set msg3 = "id: 102"_$c(10)_"data: new id"_sep
    Do handler.BufferProcessing(msg3)
    
    Do $$$AssertEquals(handler.Id, "102", "ID must be updated")
}

Method TestAdapterCallback()
{
    Set handler = ##class(dc.http.SSEHandler).%New()
    Set handler.SwitchIOOnMessage = 0
    
    // Use a mock to verify the call
    Set mock = ##class(tests.dc.http.MockAdapter).%New()
    Set handler.Adapter = mock
    
    Set stream = "data: test callback"_$c(10,10)
    Do handler.BufferProcessing(stream)
    
    Do $$$AssertEquals(mock.CallCount, 1, "Adapter should have been called once")
    Do $$$AssertEquals(mock.LastMessage.Data.GetAt(1), "test callback", "Adapter received wrong message")
}

Method TestBufferSizeAutoFlushThreshold()
{
    Set handler = ##class(dc.http.SSEHandler).%New()
    Set handler.SwitchIOOnMessage = 0
    
    // Low thresholds for testing
    Set handler.BufferSizeAutoFlushThreshold = 15
    Set handler.MaxBufferSize = 100
    
    // String length is ~35, which > 15. It has single newlines but no double newlines.
    Set partialMessageWithNewline = "data: part1"_$Char(10)_"data: part2"_$Char(10)_"leftover"
    
    Set sc = handler.BufferProcessing(partialMessageWithNewline)
    
    Do $$$AssertStatusOK(sc, "BufferProcessing with auto-flush should succeed")
    // Because size > 15, it will flush the buffer on single newlines
    Do $$$AssertEquals(handler.Messages.Count(), 2, "Should have auto-flushed and processed 2 partial items")
    
    // Remaining buffer should be just 'leftover'
    Do $$$AssertEquals(handler.Buffer, "leftover", "Buffer should retain the remaining text after last newline")
}

Method TestMaxBufferSize()
{
    Set handler = ##class(dc.http.SSEHandler).%New()
    Set handler.SwitchIOOnMessage = 0
    
    // Force auto flush and max buffer check on very small sizes
    Set handler.BufferSizeAutoFlushThreshold = 5
    Set handler.MaxBufferSize = 15
    
    Set exceptionThrown = 0
    
    Try {
        // Send a string larger than 15 without any newlines
        Do handler.BufferProcessing("this is a very long contiguous string")
    } Catch ex {
        Set exceptionThrown = 1
        Do $$$AssertTrue($Find(ex.DisplayString(), "SSE Buffer overflow protector") > 0, "Exception should be about buffer overflow")
    }
    
    Do $$$AssertTrue(exceptionThrown, "Should have thrown a buffer overflow exception")
    Do $$$AssertEquals(handler.Buffer, "", "Buffer should be cleared on overflow")
}

}
