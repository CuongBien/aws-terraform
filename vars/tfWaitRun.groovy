def call(String tfToken, String runId, Integer timeoutMinutes = 30) {
    timeout(time: timeoutMinutes, unit: 'MINUTES') {
        sh """
        set -e
        
        while true; do
          STATUS=\$(curl -s \
            -H "Authorization: Bearer ${tfToken}" \
            https://app.terraform.io/api/v2/runs/${runId} \
            | jq -r '.data.attributes.status')

          echo "Terraform status: \$STATUS"

          if [[ "\$STATUS" =~ applied|planned_and_finished ]]; then
            echo "✓ Terraform completed"
            exit 0
          fi
          
          if [[ "\$STATUS" =~ errored|canceled ]]; then
            echo "✗ Terraform failed"
            exit 1
          fi

          if [[ "\$STATUS" == "pending_approval" ]]; then
            echo "⏸ Waiting for Terraform Cloud approval..."
          fi

          sleep 15
        done
        """
    }
}
