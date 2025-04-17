#!/bin/bash

LOG_FILE="/var/log/agent-sync.log"

# Start logging
exec > >(tee -a $LOG_FILE) 2>&1
echo "Starting synchronization script at $(date)"

# Configure log rotation
cat <<EOF | sudo tee /etc/logrotate.d/agent-sync
$LOG_FILE {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
}
EOF
echo "Log rotation configured for $LOG_FILE."

# Configure server details
SERVER_IP="<server-ip>"  # Replace with the server's IP address
MQTT_PORT=1883           # Default Mosquitto MQTT port
MQTT_TOPIC="db-sync"     # Topic for database synchronization

# Path to the SQLite database
DB_PATH="/data/agent_data.db"

# Check if required tools are installed
if ! command -v inotifywait &> /dev/null; then
  echo "Error: inotify-tools is not installed. Install it using 'sudo apt-get install inotify-tools'."
  exit 1
fi

if ! command -v sqlite3 &> /dev/null; then
  echo "Error: sqlite3 is not installed. Install it using 'sudo apt-get install sqlite3'."
  exit 1
fi

# Check if the SQLite database file exists
if [ ! -f "$DB_PATH" ]; then
  echo "Error: Database file $DB_PATH does not exist. Ensure the database is created before running this script."
  exit 1
fi

# Verify database schema
if ! sqlite3 $DB_PATH ".schema" &> /dev/null; then
  echo "Error: Unable to access the database schema in $DB_PATH. Verify the database file."
  exit 1
fi

# Monitor the SQLite database for changes
echo "Monitoring database changes in $DB_PATH..."
inotifywait -m -e modify $DB_PATH | while read path _ file; do
  echo "Change detected in $file at $(date). Synchronizing with server..."

  # Extract the latest changes from the database
  CHANGES=$(sqlite3 $DB_PATH "SELECT * FROM data ORDER BY timestamp DESC LIMIT 1;")
  echo "Extracted changes: $CHANGES"

  # Publish the changes to the server using Mosquitto
  mosquitto_pub -h $SERVER_IP -p $MQTT_PORT -t $MQTT_TOPIC -m "$CHANGES"
  echo "Synchronization complete at $(date)."
done
