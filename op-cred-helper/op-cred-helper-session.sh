#!/bin/bash

vault="$1"
secret_id="$2"
region="$3"
role="$4"

CACHE_FILE="/tmp/aws_session_${secret_id}_${role:-default}.json"

# Helper: Check if cached credentials are still valid
is_valid_session() {
    if [ ! -f "$CACHE_FILE" ]; then
        return 1
    fi

    expiration=$(jq -r '.Expiration' "$CACHE_FILE")
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ "$now" < "$expiration" ]]; then
        return 0
    fi
    return 1
}

# ✅ If session is valid, return it in required format
if is_valid_session; then
    jq '{
        Version: 1,
        AccessKeyId: .AccessKeyId,
        SecretAccessKey: .SecretAccessKey,
        SessionToken: .SessionToken,
        Expiration: .Expiration
    }' "$CACHE_FILE"
    exit 0
fi

# ❌ No valid cache — fetch fresh credentials using op + aws sts
AWS_ACCESS_KEY_ID=$(op item get "${secret_id}" --fields "access key id" --reveal | xargs)
AWS_SECRET_ACCESS_KEY=$(op item get "${secret_id}" --fields "secret access key" --reveal | xargs)
mfa_code=$(op item get "${secret_id}" --otp | xargs)
mfa_serial=$(op item get "${secret_id}" --fields "mfa serial" --reveal | xargs)

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

if [ -z "$role" ]; then
    # No role to assume — get-session-token
    session=$(aws sts get-session-token \
        --region "${region}" \
        --serial-number "${mfa_serial}" \
        --token-code "${mfa_code}" \
        --duration-seconds 3600 \
        --query "Credentials" \
        --output json)
else
    # Assume a role
    role_arn=$(op item get "${secret_id}" --fields "${role}" --reveal | xargs)
    session=$(aws sts assume-role \
        --region "${region}" \
        --role-arn "${role_arn}" \
        --serial-number "${mfa_serial}" \
        --role-session-name "${role}-session" \
        --token-code "${mfa_code}" \
        --duration-seconds 3600 \
        --query "Credentials" \
        --output json)
fi

# Write raw credentials to cache
echo "$session" > "$CACHE_FILE"

# Output in credential_process format
echo "$session" | jq '{
    Version: 1,
    AccessKeyId: .AccessKeyId,
    SecretAccessKey: .SecretAccessKey,
    SessionToken: .SessionToken,
    Expiration: .Expiration
}'

