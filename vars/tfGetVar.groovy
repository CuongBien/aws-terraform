def call(String tfToken, String workspaceId, String key) {
    return sh(
        returnStdout: true,
        script: """
        curl -s -H "Authorization: Bearer ${tfToken}" \
        https://app.terraform.io/api/v2/workspaces/${workspaceId}/vars \
        | jq -r '.data[] | select(.attributes.key=="${key}") | .attributes.value'
        """
    ).trim()
}
