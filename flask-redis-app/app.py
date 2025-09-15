from flask import Flask, request, jsonify
import redis
import os

app = Flask(__name__)

# Connect to Redis using service name from docker-compose
REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

@app.route('/')
def home():
    return "Flask + Redis API is running! Use /items to interact."

@app.route('/items', methods=['GET'])
def get_items():
    items = r.lrange('items', 0, -1)
    return jsonify(items)

@app.route('/items', methods=['POST'])
def create_items():
    data = request.get_json()
    if isinstance(data, list):
        for item in data:
            r.rpush('items', item)
    elif isinstance(data, str):
        r.rpush('items', data)
    else:
        return jsonify({"error": "Invalid payload"}), 400
    return jsonify({"message": "Item(s) added"}), 201

@app.route('/items/<int:index>', methods=['PUT'])
def update_item(index):
    if index < 0 or index >= r.llen('items'):
        return jsonify({"error": "Index out of range"}), 404
    data = request.get_json()
    r.lset('items', index, data)
    return jsonify({"updated": data})

@app.route('/items/<int:index>', methods=['DELETE'])
def delete_item(index):
    items = r.lrange('items', 0, -1)
    if index < 0 or index >= len(items):
        return jsonify({"error": "Index out of range"}), 404
    r.lrem('items', 1, items[index])
    return jsonify({"removed": items[index]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

