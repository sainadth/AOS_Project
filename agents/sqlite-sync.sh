#!/bin/bash

LOG_FILE="/var/log/sqlite-sync.log"
exec > >(tee -a $LOG_FILE) 2>&1
echo "Starting SQLite synchronization script with MQTT at $(date)"

# Configuration
SQLITE_DB_PATH="/data/agent_data.db"
TIMESCALE_DB_HOST="3.129.21.182"  # Replace with the TimescaleDB server IP
TIMESCALE_DB_PORT="5432"
TIMESCALE_DB_NAME="timescaledb"
TIMESCALE_DB_USER="admin"
TIMESCALE_DB_PASSWORD="admin"
MQTT_BROKER_HOST="3.129.21.182"  # Replace with the MQTT broker IP
MQTT_TOPIC="sync/trigger"  # Topic to listen for sync triggers

# Export TimescaleDB credentials for psql
export PGPASSWORD=$TIMESCALE_DB_PASSWORD

# Verify database file exists
if [ ! -f "$SQLITE_DB_PATH" ]; then
  echo "Error: SQLite database file $SQLITE_DB_PATH not found. Ensure the PersistentVolume is mounted correctly."
  exit 1
fi

# Ensure the table exists in TimescaleDB
psql -h $TIMESCALE_DB_HOST -p $TIMESCALE_DB_PORT -U $TIMESCALE_DB_USER -d $TIMESCALE_DB_NAME -c "
CREATE TABLE IF NOT EXISTS agent_data (
    id INTEGER PRIMARY KEY,
    agent_name TEXT NOT NULL,
    data TEXT NOT NULL
);"

# Function to sync data
sync_data() {
  echo "Starting sync at $(date)"

  # Query new data from SQLite
  sqlite3 $SQLITE_DB_PATH "SELECT * FROM agent_data;" | while IFS='|' read -r id agent_name data; do
    echo "Processing row: id=$id, agent_name=$agent_name, data=$data"
    # Insert data into TimescaleDB
    psql -h $TIMESCALE_DB_HOST -p $TIMESCALE_DB_PORT -U $TIMESCALE_DB_USER -d $TIMESCALE_DB_NAME -c \
      "INSERT INTO agent_data (id, agent_name, data) VALUES ($id, '$agent_name', '$data') ON CONFLICT (id) DO NOTHING;" || echo "Failed to insert row: id=$id, agent_name=$agent_name, data=$data"
  done

  echo "Sync completed at $(date)"
}

# Listen for MQTT messages and trigger sync
mosquitto_sub -h $MQTT_BROKER_HOST -t $MQTT_TOPIC | while read -r message; do
  echo "Received MQTT message: $message"
  if [ "$message" == "sync" ]; then
    sync_data
  fi
done
