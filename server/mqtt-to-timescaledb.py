import paho.mqtt.client as mqtt
import psycopg2
import json

# MQTT Configuration
MQTT_BROKER = "mosquitto"  # Use the Mosquitto service name in Kubernetes
MQTT_PORT = 1883
MQTT_TOPIC = "mysql-sync"

# TimescaleDB Configuration
DB_HOST = "timescaledb"  # Use the TimescaleDB service name in Kubernetes
DB_PORT = 5432
DB_NAME = "metrics"
DB_USER = "admin"
DB_PASSWORD = "admin"

# Database connection
def connect_to_db():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

# Callback for when a message is received
def on_message(client, userdata, msg):
    print(f"Received message on topic {msg.topic}: {msg.payload.decode()}")
    try:
        # Parse the message payload
        message = json.loads(msg.payload.decode())
        operation = message.get("Operation")
        data = json.loads(message.get("Data"))

        conn = connect_to_db()
        cursor = conn.cursor()

        if operation == "INSERT":
            cursor.execute(
                "INSERT INTO agent_data (id, agent_name, data) VALUES (%s, %s, %s) ON CONFLICT (id) DO NOTHING;",
                (data["id"], data["agent_name"], data["data"])
            )
        elif operation == "UPDATE":
            cursor.execute(
                "UPDATE agent_data SET agent_name = %s, data = %s WHERE id = %s;",
                (data["agent_name"], data["data"], data["id"])
            )
        elif operation == "DELETE":
            cursor.execute(
                "DELETE FROM agent_data WHERE id = %s;",
                (data["id"],)
            )

        conn.commit()
        cursor.close()
        conn.close()
        print(f"Processed {operation} operation successfully.")
    except Exception as e:
        print(f"Error processing message: {e}")

# MQTT setup
def main():
    client = mqtt.Client()
    client.on_message = on_message

    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.subscribe(MQTT_TOPIC)

    print(f"Subscribed to MQTT topic: {MQTT_TOPIC}")
    client.loop_forever()

if __name__ == "__main__":
    main()
