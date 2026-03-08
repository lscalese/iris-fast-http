from flask import Flask, Response
import time
import json

app = Flask(__name__)

@app.route('/stream')
def stream():
    def generate():
        tokens = ["Hi,", " How", " can", " I", " help", " you", " today?"]
        for token in tokens:
            # standard format for OpenAI streaming responses
            data = {
                "choices": [{"delta": {"content": token}}],
                "object": "chat.completion.chunk"
            }
            yield f"data: {json.dumps(data)}\n\n"
            time.sleep(0.1)  # Simulate delay between tokens
        yield "data: [DONE]\n\n"

    return Response(generate(), mimetype='text/event-stream')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)