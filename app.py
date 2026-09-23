import os
import io
import base64

from flask import Flask, render_template, request, jsonify
from dotenv import load_dotenv
from huggingface_hub import InferenceClient

load_dotenv()

app = Flask(__name__)

HF_TOKEN = os.getenv("HUGGINGFACE_TOKEN")

client = InferenceClient(
    api_key=HF_TOKEN,
    provider="auto"
)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/generate", methods=["POST"])
def generate_image():
    data = request.get_json()
    prompt = data.get("prompt", "").strip()

    if not prompt:
        return jsonify({"error": "Prompten får inte vara tom."}), 400

    try:
        image = client.text_to_image(
            prompt=prompt,
            model="black-forest-labs/FLUX.1-dev"
        )

        image_bytes = io.BytesIO()
        image.save(image_bytes, format="PNG")
        image_bytes.seek(0)

        base64_image = base64.b64encode(
            image_bytes.read()
        ).decode("utf-8")

        image_data_url = f"data:image/png;base64,{base64_image}"

        return jsonify({"image_url": image_data_url})

    except Exception as e:
        print(f"Bildgenereringsfel: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
