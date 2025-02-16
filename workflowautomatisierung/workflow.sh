#!/bin/bash

# Setze Variablen
ANSIBLE_INVENTORY="inventory.ini"

# 1️⃣ Terraform initialisieren und Infrastruktur bereitstellen
echo "🚀 Terraform wird initialisiert..."
terraform init
terraform apply -auto-approve

# 2️⃣ Terraform Outputs holen
echo "📥 Extrahiere Terraform Outputs..."
PUBLIC_IPS=$(terraform output -json ip_adresses | jq -r '.[]')  # KORRIGIERT!
KEY_NAME=$(terraform output -raw key_name 2>/dev/null)  # Fehler unterdrücken, falls nicht vorhanden
USERNAME="ec2-user"  # Feste Zuweisung, falls Terraform keinen Output liefert

# Falls die Outputs leer sind, Skript abbrechen
if [[ -z "$PUBLIC_IPS" ]]; then
    echo "❌ Fehler: Terraform Outputs nicht gefunden. Überprüfe deine outputs.tf Datei!"
    exit 1
fi

# 3️⃣ Inventory-Datei für Ansible erstellen
echo "📜 Erstelle Ansible Inventory..."
echo "[servers]" > $ANSIBLE_INVENTORY
for IP in $PUBLIC_IPS; do
  echo "$IP ansible_user=$USERNAME ansible_ssh_private_key_file=~/.ssh/$KEY_NAME.pem" >> $ANSIBLE_INVENTORY
done

# 4️⃣ SSH-Host-Schlüssel der neuen Instanzen akzeptieren
echo "🔑 Füge Hosts zu known_hosts hinzu..."
for IP in $PUBLIC_IPS; do
  ssh-keyscan -H $IP >> ~/.ssh/known_hosts
done

# 5️⃣ Ansible Playbook ausführen
if [[ -n "$KEY_NAME" ]]; then
  echo "$IP ansible_user=$USERNAME ansible_ssh_private_key_file=~/.ssh/$KEY_NAME.pem" >> $ANSIBLE_INVENTORY
else
  echo "$IP ansible_user=$USERNAME" >> $ANSIBLE_INVENTORY
fi


echo "✅ Workflow abgeschlossen!"

