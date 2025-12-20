def call(String tfToken, String workspaceId, String message) {
    def runId = sh(
        returnStdout: true,
        script: """
        curl -s -X POST \
          -H "Authorization: Bearer ${tfToken}" \
          -H "Content-Type: application/vnd.api+json" \
          -d '{
            "data": {
              "type": "runs",
              "attributes": { "message": "${message}" },
              "relationships": {
                "workspace": {
                  "data": { "type": "workspaces", "id": "${workspaceId}" }
                }
              }
            }
          }' \
          https://app.terraform.io/api/v2/runs | jq -r '.data.id'
        """
    ).trim()
    
    echo "🚀 Terraform Run: ${runId}"
    return runId
}
