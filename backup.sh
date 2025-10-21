#!/bin/bash

echo "$(date): Starting backup process..."

while true; do
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILENAME="backup_${POSTGRES_DB}_${TIMESTAMP}.sql.gz"
    BACKUP_PATH="/tmp/${BACKUP_FILENAME}"

    echo "Creating backup for database ${POSTGRES_DB}..."
    PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} ${POSTGRES_DB} | gzip > ${BACKUP_PATH}

    if [ -z "${APILLON_BUCKET_UUID}" ]; then
        echo "ERROR: APILLON_BUCKET_UUID is not set"
        exit 1
    fi

    echo "Uploading to Apillon storage..."

    # Step 1: Initiate upload session
    AUTH_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Basic ${APILLON_BASIC_AUTH}" \
        -H "Content-Type: application/json" \
        -d "{\"files\": [{\"fileName\": \"${BACKUP_FILENAME}\", \"contentType\": \"application/gzip\"}]}" \
        "https://api.apillon.io/storage/buckets/${APILLON_BUCKET_UUID}/upload")

    # Extract upload URL and session UUID from .data
    UPLOAD_URL=$(echo "$AUTH_RESPONSE" | jq -r '.data.files[0].url')
    SESSION_UUID=$(echo "$AUTH_RESPONSE" | jq -r '.data.sessionUuid')

    if [ -z "$UPLOAD_URL" ] || [ "$UPLOAD_URL" = "null" ] || [ -z "$SESSION_UUID" ] || [ "$SESSION_UUID" = "null" ]; then
        echo "ERROR: Failed to get upload URL or session UUID from Apillon"
        echo "Full response: $AUTH_RESPONSE"
        exit 1
    fi

    echo "Upload URL obtained. Uploading file..."

    # Step 2: Upload the file
    curl -X PUT \
        -H "Content-Type: application/gzip" \
        --data-binary @"${BACKUP_PATH}" \
        "$UPLOAD_URL" \
        --fail

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to upload file to Apillon"
        exit 1
    fi

    echo "File uploaded. Finalizing session..."

    # Step 3: End upload session
    FINALIZE_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Basic ${APILLON_BASIC_AUTH}" \
        -H "Content-Type: application/json" \
        -d "{\"sessionUuid\":\"${SESSION_UUID}\"}" \
        "https://api.apillon.io/storage/buckets/${APILLON_BUCKET_UUID}/upload/${SESSION_UUID}/end")

    # Check success
    if echo "$FINALIZE_RESPONSE" | grep -q '"data":true'; then
        echo "Backup successfully uploaded to Apillon"
    else
        echo "ERROR: Failed to finalize upload session"
        echo "Finalize response: $FINALIZE_RESPONSE"
        exit 1
    fi

    # Clean up
    rm -f "${BACKUP_PATH}"
    echo "$(date): Backup process completed"

    echo "Sleeping for $BACKUP_INTERVAL seconds before next backup..."
    sleep "$BACKUP_INTERVAL"
done
