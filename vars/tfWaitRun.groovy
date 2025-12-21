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

          # Use case for POSIX sh compatibility
          case "\$STATUS" in
            applied|planned_and_finished)
              echo "✓ Terraform completed"
              exit 0
              ;;
            errored|canceled)
              echo "✗ Terraform failed"
              exit 1
              ;;
            pending_approval)
              echo "⏸ Waiting for Terraform Cloud approval..."
              ;;
          esac

          sleep 15
        done
        """
    }
}
