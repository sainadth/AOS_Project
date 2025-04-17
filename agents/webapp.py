from flask import Flask, request, jsonify, send_from_directory
import sqlite3
import os

app = Flask(__name__, static_folder='frontend/build')
DB_PATH = "/data/agent_data.db"

# Database connection
def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
@app.route('/<path:path>')
def serve_frontend(path='index.html'):
    return send_from_directory(app.static_folder, path)

@app.route('/data', methods=['GET'])
def read_data():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM data;")
    rows = cursor.fetchall()
    conn.close()
    return jsonify([dict(row) for row in rows])

@app.route('/data', methods=['POST'])
def create_data():
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO data (column1, column2) VALUES (?, ?);", (data['column1'], data['column2']))
    conn.commit()
    conn.close()
    return jsonify({"message": "Data inserted successfully"}), 201

@app.route('/data/<int:id>', methods=['PUT'])
def update_data(id):
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE data SET column1 = ?, column2 = ? WHERE id = ?;", (data['column1'], data['column2'], id))
    conn.commit()
    conn.close()
    return jsonify({"message": "Data updated successfully"})

@app.route('/data/<int:id>', methods=['DELETE'])
def delete_data(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM data WHERE id = ?;", (id,))
    conn.commit()
    conn.close()
    return jsonify({"message": "Data deleted successfully"})

if __name__ == '__main__':
    print("Web app is running locally on http://127.0.0.1:5000")
    print("To expose this app to external devices, use a tunneling service like ngrok or Cloudflare Tunnel.")
    app.run(host='0.0.0.0', port=5000)
