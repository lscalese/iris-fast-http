Class tests.dc.http.SSEChat Extends %UnitTest.TestCase
{

Method TestChatCompletionChunk()
{
    Set splitMessage = $lb("Hi,","How","can","I","help","you","today?")
    Set messageControl = $lts(splitMessage, " ") _ " "

    
    Set stream = ##class(dc.http.Stream).%New()
    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    Set handler.Adapter = ##class(dc.http.SSEChatConsoleAdapter).%New()
    Set handler.SwitchIOOnMessage = $$$NO

    Set ptr = 0, io = $IO, tempFile = ##class(%File).TempFilename("log")
    Open tempFile:"NWR"
    Try {
        Use tempFile
        While $ListNext(splitMessage, ptr, toChunk) {
            Set chunkMessage = {
                "choices": {
                    "0": {
                        "delta": {
                            "content": (toChunk_" ")
                        }
                    }
                },
                "object": "chat.completion.chunk"
            }
            Do stream.Write("data: "_chunkMessage.%ToJSON()_$Char(10,10))
        }
        Close tempFile
        Use io
    }
    Catch ex {
        Close tempFile
        Use io
        Do ##class(%File).Delete(tempFile)
        Set sc= ex.AsStatus()
        Do $$$AssertStatusOK(sc, "Exception occurred during test execution: "_$SYSTEM.Status.GetErrorText(sc))
        Throw ex
    }
    

    Set file = ##class(%Stream.FileCharacter).%New()
    Do file.LinkToFile(tempFile)
    Set firstLine = file.ReadLine()
    Kill file
    Do ##class(%File).Delete(tempFile)

    Do $$$AssertTrue(firstLine=messageControl, "Expected: "_messageControl_" Got: "_firstLine)

    // Verify adapter internal state
    Set adapter = handler.Adapter
    Do $$$AssertEquals(adapter.ContentResponse, messageControl, "Adapter ContentResponse should match the full message")
    
    // Verify Assistant Message helper
    Set assistantMsg = adapter.GetAssistantMessage()
    Do $$$AssertEquals(assistantMsg.role, "assistant", "Assistant message role should be 'assistant'")
    Do $$$AssertEquals(assistantMsg.content, messageControl, "Assistant message content match")

    // Verify all chunks were processed by handler
    Do $$$AssertEquals(handler.Items.Count(), $ListLength(splitMessage), "Handler should have processed all chunks")

    Do handler.Reset() // Ensure handler can reset state after processing
    Do $$$AssertEquals(handler.Items.Count(), 0, "Handler should have no items after reset")
    Do $$$AssertEquals(adapter.ContentResponse, "", "Adapter ContentResponse should be reset to empty")
    Do $$$AssertEquals(adapter.LastChunk.%ToJSON(), "{}", "Adapter LastChunk should be reset to empty json object {}")
    Return
}

}
