def call(String tfToken, String workspaceId, String key, String value) {
    sh """
    set -e
    VAR_ID=\$(curl -s \
      -H "Authorization: Bearer ${tfToken}" \
      https://app.terraform.io/api/v2/workspaces/${workspaceId}/vars \
      | jq -r ".data[] | select(.attributes.key==\\"${key}\\") | .id")

    [ -z "\$VAR_ID" ] && echo "❌ Var ${key} not found" && exit 1

    curl -s -X PATCH \
      -H "Authorization: Bearer ${tfToken}" \
      -H "Content-Type: application/vnd.api+json" \
      -d '{
        "data": {
          "id": "'\$VAR_ID'",
          "type": "vars",
          "attributes": { "value": "${value}" }
        }
      }' \
      https://app.terraform.io/api/v2/workspaces/${workspaceId}/vars/\$VAR_ID > /dev/null
    
    echo "✓ Updated ${key}=${value}"
    """
}
