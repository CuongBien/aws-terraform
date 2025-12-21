@Library('pbl4-shared-library') _

pipeline {
    agent any

    parameters {
        choice(
            name: 'ROLLBACK_TO',
            choices: ['green', 'blue'],
            description: 'Rollback to environment'
        )
        booleanParam(
            name: 'DISABLE_FAILED_ENV',
            defaultValue: true,
            description: 'Disable failed environment'
        )
    }

    environment {
        AWS_REGION = 'ap-southeast-2'
        PROJECT_NAME = 'pbl4-three-tier'
        TF_ORG = 'CBien'
        TF_WORKSPACE = 'aws-terraform-vcs'
        TF_WORKSPACE_ID = ''
    }

    stages {
        stage('Resolve Workspace') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        env.TF_WORKSPACE_ID = tfGetWorkspaceId(TF_TOKEN, TF_ORG, TF_WORKSPACE)
                    }
                }
            }
        }

        stage('Confirm Rollback') {
            steps {
                script {
                    def userInput = input(
                        message: """
                        ⚠️ EMERGENCY ROLLBACK
                        Rollback to: ${params.ROLLBACK_TO}
                        Disable failed: ${params.DISABLE_FAILED_ENV}

                        Confirm?
                        """,
                        parameters: [
                            choice(
                                name: 'CONFIRM',
                                choices: ['Proceed', 'Abort'],
                                description: 'Confirm action'
                            )
                        ]
                    )
                    
                    if (userInput == 'Abort') {
                        error("Rollback aborted")
                    }
                }
            }
        }

        stage('Execute Rollback') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        def target = params.ROLLBACK_TO
                        def traffic = (target == 'green')
                            ? [blue: '0', green: '100']
                            : [blue: '100', green: '0']

                        tfUpdateVar(TF_TOKEN, env.TF_WORKSPACE_ID, 'traffic_distribution_blue', traffic.blue)
                        tfUpdateVar(TF_TOKEN, env.TF_WORKSPACE_ID, 'traffic_distribution_green', traffic.green)

                        if (params.DISABLE_FAILED_ENV) {
                            tfUpdateVar(
                                TF_TOKEN, env.TF_WORKSPACE_ID,
                                "enable_${target == 'green' ? 'blue' : 'green'}_env",
                                "false"
                            )
                        }

                        def runId = tfTriggerRun(
                            TF_TOKEN, env.TF_WORKSPACE_ID,
                            "EMERGENCY ROLLBACK → ${target}"
                        )
                        tfWaitRun(TF_TOKEN, runId, 30)
                    }
                }
            }
        }

        stage('Verify Rollback') {
            steps {
                withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                    sh """
                    set -e
                    
                    TG_ARN=\$(aws elbv2 describe-target-groups \
                        --region ${AWS_REGION} \
                        --names ${PROJECT_NAME}-web-tg-${params.ROLLBACK_TO} \
                        --query 'TargetGroups[0].TargetGroupArn' \
                        --output text)

                    for i in {1..30}; do
                        HEALTHY=\$(aws elbv2 describe-target-health \
                            --region ${AWS_REGION} \
                            --target-group-arn \$TG_ARN \
                            --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`]|length(@)' \
                            --output text)

                        [ "\$HEALTHY" -ge 1 ] && echo "✓ Rollback verified" && exit 0
                        
                        sleep 10
                    done

                    echo "✗ Verification failed"
                    exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            echo """
            ✅ ROLLBACK SUCCESS
            Restored: ${params.ROLLBACK_TO}
            """
        }
        failure {
            echo """
            ❌ ROLLBACK FAILED
            Manual intervention required
            """
        }
        always {
            cleanWs()
        }
    }
}