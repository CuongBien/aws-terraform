def call(String tfToken, String org, String workspace) {
    return sh(
        returnStdout: true,
        script: """
        curl -s -H "Authorization: Bearer ${tfToken}" \
        https://app.terraform.io/api/v2/organizations/${org}/workspaces/${workspace} \
        | jq -r '.data.id'
        """
    ).trim()
}
