#!/usr/bin/env bash
set -euo pipefail

# Kasutamine:
# chmod +x pt8_curl_paringud.sh
# ELASTIC_PASSWORD="sinu_tegelik_parool" ./pt8_curl_paringud.sh

ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-SINU_PAROOL}"
CA_CERT="/etc/elasticsearch/certs/http_ca.crt"
ES_URL="https://localhost:9200"

es_curl() {
    curl -s --cacert "$CA_CERT" -u "elastic:$ELASTIC_PASSWORD" "$@"
}

echo "=== [Punkt 8.1] Kõikide indeksite vaatamine ==="
es_curl "$ES_URL/_cat/indices?v"

echo -e "\n=== [Punkt 8.2] Teise õpilase lisamine (Juku Juurikas) ==="
es_curl -X POST "$ES_URL/opilased/_doc/2?pretty" -H 'Content-Type: application/json' -d'
{
  "eesnimi": "Juku",
  "perenimi": "Juurikas",
  "kursus": "IT-24",
  "keskmine_hinne": 3.5
}'

echo -e "\n=== [Punkt 8.3] Kolmanda õpilase lisamine automaatse ID-ga (Kati Karu) ==="
es_curl -X POST "$ES_URL/opilased/_doc/?pretty" -H 'Content-Type: application/json' -d'
{
  "eesnimi": "Kati",
  "perenimi": "Karu",
  "kursus": "KV-23",
  "keskmine_hinne": 4.9
}'

# Ootame indeksi värskendamist enne otsinguid
es_curl -X POST "$ES_URL/opilased/_refresh" > /dev/null

echo -e "\n=== [Punkt 8.4] Otsing: kursus IT-24 ==="
es_curl -X GET "$ES_URL/opilased/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "kursus": "IT-24"
    }
  }
}'

echo -e "\n=== [Punkt 8.5] Otsing: keskmine hinne >= 4.5 ==="
es_curl -X GET "$ES_URL/opilased/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "range": {
      "keskmine_hinne": {
        "gte": 4.5
      }
    }
  }
}'
