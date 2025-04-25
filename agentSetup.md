## AGENT SETUP

curl -sfL https://get.k3s.io | K3S_URL=https://3.129.21.182:6443 K3S_TOKEN=K109cae42b17682952040f9ac8dbfac3ec0a5933a4ea28b79eb6fb5386a84ba41bf::server:61df000cd788a53ae1be4c364f7e2e88 sh -

cd ~

mkdir .kube

cd .kube/

vi config

### insert content from /etc/rancher/k3s/k3s.yaml on server

### check if <PUBLIC IP> is pingable

ping <PUBLIC IP>

kubectl get nodes

---

### Reinstall K3s on Agent

1. **Uninstall K3s**:
   Run the following command to completely remove `k3s` from the agent:
   ```bash
   sudo /usr/local/bin/k3s-agent-uninstall.sh
   ```
2. **Verify Uninstallation**:
   Ensure all `k3s` files are removed:
   ```bash
   sudo rm -rf /var/lib/rancher /etc/rancher /var/lib/kubelet /etc/systemd/system/k3s-agent.service
   ```
3. **Reinstall K3s**:
   Rejoin the agent to the cluster using the following command:
   ```bash
   curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 K3S_TOKEN=<K3S_TOKEN> sh -
   ```

4. **Verify the Agent Node**:
   Check the status of the nodes to ensure the agent is connected:
   ```bash
   kubectl get nodes
   ```

5. **Reapply Agent-Specific Deployments**:
   Reapply the SQLite deployment and synchronization script:
   ```bash
   kubectl apply -f sqlite-deployment.yaml
   nohup ./sqlite-sync.sh > sqlite-sync.log 2>&1 &
   ```

---

### Deploy SQLite on Agent

1. Apply the SQLite deployment:
   ```bash
   kubectl apply -f sqlite-deployment.yaml
   ```

2. Verify the SQLite pod is running:
   ```bash
   kubectl get pods -l app=sqlite
   ```

3. Check the PersistentVolumeClaim (PVC) and PersistentVolume (PV) binding:
   ```bash
   kubectl get pvc
   kubectl get pv
   ```

---

### Configure and Run Synchronization Script

1. Copy the `sqlite-sync.sh` script to the agent node.
2. Make the script executable:
   ```bash
   chmod +x sqlite-sync.sh
   ```
3. Run the script in the background:
   ```bash
   nohup ./sqlite-sync.sh > sqlite-sync.log 2>&1 &
   ```
4. Verify the script is running:
   ```bash
   ps aux | grep sqlite-sync.sh
   ```

---

### Ensure Network Connectivity

1. Check if the SQLite pod has internet connectivity:
   ```bash
   kubectl exec -it <sqlite-pod-name> -- ping 8.8.8.8
   ```
2. Apply a network policy to allow egress traffic if needed:
   ```bash
   kubectl apply -f allow-egress-to-mqtt.yaml
   ```
3. Verify connectivity to the MQTT broker:
   ```bash
   kubectl exec -it <sqlite-pod-name> -- nc -zv <SERVER_IP> 1883
   ```
4. Check the logs of the synchronization script:
   ```bash
   kubectl exec -it <sqlite-pod-name> -- cat /var/log/sqlite-sync.log
   ```

---

### Verify SQLite Deployment on Agent

1. Check the status of the SQLite pod:
   ```bash
   kubectl get pods -l app=sqlite -o wide
   ```

2. Describe the SQLite pod for detailed information:
   ```bash
   kubectl describe pod -l app=sqlite
   ```

3. Verify the PersistentVolumeClaim (PVC) is bound:
   ```bash
   kubectl get pvc sqlite-pvc
   ```

4. Verify the PersistentVolume (PV) is bound to the PVC:
   ```bash
   kubectl get pv
   ```

5. Check the logs of the SQLite pod:
   ```bash
   kubectl logs -l app=sqlite
   ```

6. Access the SQLite pod to interact with the database:
   ```bash
   kubectl exec -it <sqlite-pod-name> -- bash
   ```

   - Navigate to the database directory:
     ```bash
     cd /data
     ```

   - Open the SQLite database:
     ```bash
     sqlite3 agent_data.db
     ```

   - Verify the `agent_data` table exists:
     ```sql
     .tables
     ```

   - Query the data:
     ```sql
     SELECT * FROM agent_data;
     ```

   - Exit the SQLite shell:
     ```sql
     .exit
     ```

7. Exit the pod shell:
   ```bash
   exit
   ```

---

### Create Table in SQLite Database

1. Access the SQLite pod:
   ```bash
   kubectl exec -it <sqlite-pod-name> -- bash
   ```

2. Navigate to the database directory:
   ```bash
   cd /data
   ```

3. Open the SQLite database:
   ```bash
   sqlite3 agent_data.db
   ```

4. Create a table with fields `id`, `agent-name`, and `data`:
   ```sql
   CREATE TABLE IF NOT EXISTS agent_data (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       agent_name TEXT NOT NULL,
       data TEXT NOT NULL
   );
   ```

5. Verify the table was created:
   ```sql
   .tables
   ```

6. Exit the SQLite shell:
   ```sql
   .exit
   ```

7. Exit the pod shell:
   ```bash
   exit
   ```

---

### Perform CRUD Operations on SQLite Database

1. **Access the SQLite Pod**:
   ```bash
   kubectl exec -it <sqlite-pod-name> -- bash
   ```

2. **Navigate to the Database Directory**:
   ```bash
   cd /data
   ```

3. **Open the SQLite Database**:
   ```bash
   sqlite3 agent_data.db
   ```

4. **Create a Table (if not already created)**:
   ```sql
   CREATE TABLE IF NOT EXISTS agent_data (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       agent_name TEXT NOT NULL,
       data TEXT NOT NULL
   );
   ```

5. **Insert Data**:
   ```sql
   INSERT INTO agent_data (agent_name, data) VALUES ('Agent1', 'Test data 1');
   INSERT INTO agent_data (agent_name, data) VALUES ('Agent2', 'Test data 2');
   ```

6. **Read Data**:
   ```sql
   SELECT * FROM agent_data;
   ```

7. **Update Data**:
   ```sql
   UPDATE agent_data SET data = 'Updated data' WHERE id = 1;
   ```

8. **Delete Data**:
   ```sql
   DELETE FROM agent_data WHERE id = 2;
   ```

9. **Verify Changes**:
   ```sql
   SELECT * FROM agent_data;
   ```

10. **Exit the SQLite Shell**:
    ```sql
    .exit
    ```

11. **Exit the Pod Shell**:
    ```bash
    exit
    ```

---

### Expected Outcome

- **Insert**: New rows should be added to the `agent_data` table.
- **Read**: The `SELECT` query should display all rows in the table.
- **Update**: The specified row should be updated with new data.
- **Delete**: The specified row should be removed from the table.