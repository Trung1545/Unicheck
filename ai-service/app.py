import os
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "success": True,
        "data": {
            "status": "UP",
            "service": "UniCheck AI Microservice",
            "version": "1.0.0"
        },
        "message": "AI Service is healthy",
        "errorCode": None
    }), 200

@app.route('/api/v1/face/extract-embedding', methods=['POST'])
def extract_embedding():
    # Placeholder for biometric embedding extraction
    return jsonify({
        "success": True,
        "data": {
            "embedding": [0.0] * 128,
            "face_detected": True,
            "confidence": 0.98
        },
        "message": "Trích xuất đặc trưng khuôn mặt thành công",
        "errorCode": None
    }), 200

@app.route('/api/v1/face/check-liveness', methods=['POST'])
def check_liveness():
    return jsonify({
        "success": True,
        "data": {
            "is_live": True,
            "liveness_score": 0.96
        },
        "message": "Kiểm tra thực thể (liveness) thành công",
        "errorCode": None
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
