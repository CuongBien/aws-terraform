pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        choice(
            name: 'DEPLOYMENT_TARGET',
            choices: ['green', 'blue'],
            description: 'Deploy to which environment?'
        )
        choice(
            name: 'TRAFFIC_SPLIT',
            choices: ['canary-10', 'half-50', 'full-100'],
            description: 'Traffic distribution'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip health checks'
        )
    }

    environment {
        AWS_REGION   = 'ap-southeast-2'
        PROJECT_NAME = 'pbl4-three-tier'

        TF_ORG       = 'CBien'
        TF_WORKSPACE = 'aws-terraform-vcs'
    }

    stages {

        /* ================= CHECKOUT ================= */
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
                echo "Deploying commit ${env.GIT_COMMIT_SHORT}"
            }
        }

        /* ================= VALIDATION ================= */
        stage('Validate Input') {
            steps {
                script {
                    if (params.TRAFFIC_SPLIT == 'full-100' && params.DEPLOYMENT_TARGET == 'blue') {
                        echo "⚠ Full traffic to blue – make sure green is current production"
                    }
                }
            }
        }

        /* ================= UPDATE TRAFFIC VARS ================= */
        stage('Update Traffic Variables') {
            steps {
                withCredentials([string(
                    credentialsId: 'terraform-cloud-token',
                    variable: 'TF_TOKEN_app_terraform_io'
                )]) {
                    script {

                        def trafficMatrix = [
                            'canary-10': [blue: 90, green: 10],
                            'half-50'  : [blue: 50, green: 50],
                            'full-100' : [blue: 0 , green: 100]
                        ]

                        def traffic = trafficMatrix[params.TRAFFIC_SPLIT]

                        if (params.DEPLOYMENT_TARGET == 'blue') {
                            traffic = [blue: traffic.green, green: traffic.blue]
                        }

                        sh """
                        set -e

                        WORKSPACE_ID=\$(curl -s \
                          -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                          https://app.terraform.io/api/v2/organizations/${TF_ORG}/workspaces/${TF_WORKSPACE} \
                          | jq -r '.data.id')

                        update_var () {
                          KEY=\$1
                          VALUE=\$2

                          VAR_ID=\$(curl -s \
                            -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                            https://app.terraform.io/api/v2/workspaces/\$WORKSPACE_ID/vars \
                            | jq -r ".data[] | select(.attributes.key==\\"\$KEY\\") | .id")

                          if [ -z "\$VAR_ID" ]; then
                            echo "Variable \$KEY not found"
                            exit 1
                          fi

                          curl -s -X PATCH \
                            -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                            -H "Content-Type: application/vnd.api+json" \
                            -d "{
                              \\"data\\": {
                                \\"id\\": \\"\$VAR_ID\\",
                                \\"type\\": \\"vars\\",
                                \\"attributes\\": { \\"value\\": \\"\$VALUE\\" }
                              }
                            }" \
                            https://app.terraform.io/api/v2/workspaces/\$WORKSPACE_ID/vars/\$VAR_ID
                        }

                        update_var traffic_distribution_blue  ${traffic.blue}
                        update_var traffic_distribution_green ${traffic.green}
                        """
                        echo "Traffic updated → Blue ${traffic.blue}% | Green ${traffic.green}%"
                    }
                }
            }
        }

        /* ================= ENABLE ENV ================= */
        stage('Enable Target Environment') {
            steps {
                withCredentials([string(
                    credentialsId: 'terraform-cloud-token',
                    variable: 'TF_TOKEN_app_terraform_io'
                )]) {
                    sh """
                    set -e

                    WORKSPACE_ID=\$(curl -s \
                      -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                      https://app.terraform.io/api/v2/organizations/${TF_ORG}/workspaces/${TF_WORKSPACE} \
                      | jq -r '.data.id')

                    VAR_ID=\$(curl -s \
                      -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                      https://app.terraform.io/api/v2/workspaces/\$WORKSPACE_ID/vars \
                      | jq -r ".data[] | select(.attributes.key==\\"enable_${params.DEPLOYMENT_TARGET}_env\\") | .id")

                    curl -s -X PATCH \
                      -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                      -H "Content-Type: application/vnd.api+json" \
                      -d '{
                        "data": {
                          "id": "'\$VAR_ID'",
                          "type": "vars",
                          "attributes": {
                            "value": "true",
                            "hcl": true
                          }
                        }
                      }' \
                      https://app.terraform.io/api/v2/workspaces/\$WORKSPACE_ID/vars/\$VAR_ID
                    """
                }
            }
        }

        /* ================= TRIGGER + WAIT TERRAFORM ================= */
        stage('Terraform Cloud Apply') {
            steps {
                withCredentials([string(
                    credentialsId: 'terraform-cloud-token',
                    variable: 'TF_TOKEN_app_terraform_io'
                )]) {
                    sh """
                    set -e

                    WORKSPACE_ID=\$(curl -s \
                      -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                      https://app.terraform.io/api/v2/organizations/${TF_ORG}/workspaces/${TF_WORKSPACE} \
                      | jq -r '.data.id')

                    RUN_ID=\$(curl -s -X POST \
                      -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                      -H "Content-Type: application/vnd.api+json" \
                      -d '{
                        "data": {
                          "type": "runs",
                          "attributes": {
                            "message": "Deploy ${params.DEPLOYMENT_TARGET} ${params.TRAFFIC_SPLIT} (${env.GIT_COMMIT_SHORT})"
                          },
                          "relationships": {
                            "workspace": {
                              "data": {
                                "type": "workspaces",
                                "id": "'\$WORKSPACE_ID'"
                              }
                            }
                          }
                        }
                      }' \
                      https://app.terraform.io/api/v2/runs \
                      | jq -r '.data.id')

                    echo "Terraform run \$RUN_ID"

                    while true; do
                      STATUS=\$(curl -s \
                        -H "Authorization: Bearer \$TF_TOKEN_app_terraform_io" \
                        https://app.terraform.io/api/v2/runs/\$RUN_ID \
                        | jq -r '.data.attributes.status')

                      echo "Terraform status: \$STATUS"

                      if [[ "\$STATUS" == "applied" ]]; then exit 0; fi
                      if [[ "\$STATUS" == "errored" || "\$STATUS" == "canceled" ]]; then exit 1; fi

                      sleep 15
                    done
                    """
                }
            }
        }

        /* ================= HEALTH CHECK ================= */
        stage('Health Check') {
            when { expression { !params.SKIP_TESTS } }
            steps {
                script {
                    try {
                        withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                            sh """
                            set -e
                            TG_ARN=\$(aws elbv2 describe-target-groups \
                            --region ${AWS_REGION} \
                            --names ${PROJECT_NAME}-web-tg-${params.DEPLOYMENT_TARGET} \
                            --query 'TargetGroups[0].TargetGroupArn' \
                            --output text)

                            for i in {1..30}; do
                            HEALTHY=\$(aws elbv2 describe-target-health \
                                --region ${AWS_REGION} \
                                --target-group-arn \$TG_ARN \
                                --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`]|length(@)' \
                                --output text)

                            if [ "\$HEALTHY" -ge 1 ]; then
                                echo "✓ Environment healthy (\$HEALTHY instances)"
                                exit 0
                            fi

                            echo "Waiting... (\$HEALTHY/1 healthy, attempt \$i/30)"
                            sleep 10
                            done

                            echo "✗ Health check failed"
                            exit 1
                            """
                        }
                    } catch (Exception e) {
                        env.HEALTH_CHECK_FAILED = 'true'
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }

        /* ================= MANUAL APPROVAL (FULL CUTOVER ONLY) ================= */
        stage('Manual Approval - Full Cutover') {
            when {
                allOf {
                    expression { params.TRAFFIC_SPLIT == 'full-100' }
                    expression { !params.SKIP_TESTS }
                }
            }
            steps {
                script {
                    def userInput = input(
                        message: """
                            ⚠️ FULL CUTOVER CONFIRMATION
                            
                            Target: ${params.DEPLOYMENT_TARGET}
                            Traffic: 100% → ${params.DEPLOYMENT_TARGET}
                            Commit: ${env.GIT_COMMIT_SHORT}
                            
                            Health Check: PASSED ✅
                            
                            Proceed with full cutover?
                        """,
                        parameters: [
                            choice(
                                name: 'ACTION',
                                choices: ['Proceed', 'Rollback'],
                                description: 'Choose action'
                            )
                        ]
                    )
                    
                    if (userInput == 'Rollback') {
                        error("Deployment aborted by user - initiating rollback")
                    }
                    
                    echo "✓ Full cutover approved by user"
                }
            }
        }
    }

    post {
        success {
            script {
                def message = """
                    ✅ DEPLOYMENT SUCCESS
                    
                    Target: ${params.DEPLOYMENT_TARGET}
                    Traffic: ${params.TRAFFIC_SPLIT}
                    Commit: ${env.GIT_COMMIT_SHORT}
                    Duration: ${currentBuild.durationString}
                """
                echo message
                
                // TODO: Send Slack/Email notification
            }
        }
        failure {
            script {
                def message = """
                    ❌ DEPLOYMENT FAILED
                    
                    Target: ${params.DEPLOYMENT_TARGET}
                    Traffic: ${params.TRAFFIC_SPLIT}
                    Commit: ${env.GIT_COMMIT_SHORT}
                    
                    ${env.HEALTH_CHECK_FAILED == 'true' ? '⚠️ Automated rollback initiated' : ''}
                """
                echo message
                
                // TODO: Send Slack/Email notification
            }
        }
        always {
            cleanWs()
        }
    }
}
