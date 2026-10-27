#!/usr/bin/env bash
# ==============================================================================
# RS 4.0 : Elasticsearchi ja Kibana automaatne paigaldusskript Ubuntu Serverile
# ==============================================================================
set -euo pipefail

# Kontrollime, kas skripti käivitatakse sudo/root õigustega
if [[ $EUID -ne 0 ]]; then
   echo "VIGA: Palun käivita see skript sudo-ga: sudo bash install_elk.sh"
   exit 1
fi

echo "=== [1/6] Süsteemi uuendamine ja abivahendite paigaldamine ==="
apt-get update && apt-get upgrade -y
apt-get install -y apt-transport-https curl gnupg ufw

echo "=== [2/6] Elasticu GPG-võtme ja 8.x repositooriumi lisamine ==="
install -m 0755 -d /usr/share/keyrings
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor --yes -o /usr/share/keyrings/elastic-keyring.gpg
chmod a+r /usr/share/keyrings/elastic-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list > /dev/null
apt-get update

echo "=== [3/6] Elasticsearchi paigaldamine ja mälu optimeerimine (1,5 GB) ==="
apt-get install -y elasticsearch

# Piirame JVM Heap mälu 1,5 GB peale (kriitiline 4 GB RAM-iga VM-i jaoks)
printf -- "-Xms1536m\n-Xmx1536m\n" | tee /etc/elasticsearch/jvm.options.d/custom_heap.options > /dev/null

systemctl daemon-reload
systemctl enable elasticsearch.service
echo "Käivitan Elasticsearchi (esmane käivitus võtab 1-2 minutit)..."
systemctl start elasticsearch.service

echo "=== [4/6] Kibana paigaldamine ja võrgu seadistamine ==="
apt-get install -y kibana

# Seadistame Kibana kuulama kõiki võrguliideseid (0.0.0.0)
sed -i 's/^#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml

# Avame pordid tulemüüris (kui UFW on kasutusel)
ufw allow 22/tcp > /dev/null || true
ufw allow 5601/tcp > /dev/null || true

systemctl enable kibana.service
systemctl start kibana.service

echo "=== [5/6] Ootan Elasticsearchi klastri valmimist (kuni 60 sek)... ==="
for i in {1..30}; do
    if systemctl is-active --quiet elasticsearch.service; then
        break
    fi
    sleep 2
done

echo "=== [6/6] Genereerin ligipääsuandmed ==="
VM_IP=$(hostname -I | awk '{print $1}')
ELASTIC_PASS=$(/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b -s)
KIBANA_TOKEN=$(/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)

echo ""
echo "=============================================================================="
echo " PAIGALDUS ON EDUKALT LÕPPENUD!"
echo "=============================================================================="
echo "1. Ava oma põhiarvuti brauseris Kibana: http://${VM_IP}:5601"
echo ""
echo "2. Kopeeri ja kleebi sinna järgmine Enrollment Token:"
echo "${KIBANA_TOKEN}"
echo ""
echo "3. Kui brauser küsib 6-kohalist kinnituskoodi, käivita terminalis:"
echo "   sudo /usr/share/kibana/bin/kibana-verification-code"
echo ""
echo "4. Sisselogimise andmed (SALVESTA NEED!):"
echo "   Kasutajanimi: elastic"
echo "   Parool:       ${ELASTIC_PASS}"
echo "=============================================================================="
