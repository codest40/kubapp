from flask import Flask, render_template, request

app = Flask(__name__)

def bot_response(message):
    message = message.lower()

    if "hello" in message:
        return "Hey there 👋"
    elif "how are you" in message:
        return "I'm just code, but I'm running fine!"
    elif "bye" in message:
        return "Goodbye!"
    else:
        return "I don't understand that yet."

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/chat", methods=["POST"])
def chat():
    user_msg = request.form["message"]
    response = bot_response(user_msg)
    return {"reply": response}

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "service": "chat-bot",
        "checks": {
            "app": "ok"
        }
    }), 200

@app.route("/live", methods=["GET"])
def live():
    return "alive", 200
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
