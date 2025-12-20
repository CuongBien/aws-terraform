@Library('pbl4-shared-library') _

/* ================== PIPELINE ================== */

pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        choice(name: 'DEPLOYMENT_TARGET', choices: ['green','blue'])
        choice(name: 'TRAFFIC_SPLIT', choices: ['canary-10','half-50','full-100'])
        booleanParam(name: 'SKIP_TESTS', defaultValue: false)
    }

    environment {
        AWS_REGION   = 'ap-southeast-2'
        PROJECT_NAME = 'pbl4-three-tier'
        TF_ORG       = 'CBien'
        TF_WORKSPACE = 'aws-terraform-vcs'

        TF_WORKSPACE_ID = ''
        PREV_BLUE  = ''
        PREV_GREEN = ''
        ROLLBACK_NEEDED = 'false'
    }

    stages {

        /* ========== CHECKOUT ========== */
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        /* ========== RESOLVE WORKSPACE ID ========== */
        stage('Resolve Terraform Workspace') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        env.TF_WORKSPACE_ID = tfGetWorkspaceId(TF_TOKEN, TF_ORG, TF_WORKSPACE)
                        echo "Workspace ID: ${env.TF_WORKSPACE_ID}"
                    }
                }
            }
        }

        /* ========== SAVE CURRENT STATE ========== */
        stage('Snapshot Current Traffic') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        env.PREV_BLUE = sh(
                            returnStdout: true,
                            script: """
                              curl -s -H "Authorization: Bearer ${TF_TOKEN}" \
                              https://app.terraform.io/api/v2/workspaces/${env.TF_WORKSPACE_ID}/vars \
                              | jq -r '.data[] | select(.attributes.key=="traffic_distribution_blue") | .attributes.value'
                            """
                        ).trim()

                        env.PREV_GREEN = sh(
                            returnStdout: true,
                            script: """
                              curl -s -H "Authorization: Bearer ${TF_TOKEN}" \
                              https://app.terraform.io/api/v2/workspaces/${env.TF_WORKSPACE_ID}/vars \
                              | jq -r '.data[] | select(.attributes.key=="traffic_distribution_green") | .attributes.value'
                            """
                        ).trim()

                        if (!env.PREV_BLUE.isNumber() || !env.PREV_GREEN.isNumber()) {
                            error("Invalid previous traffic state – abort")
                        }

                        echo "Saved state → Blue ${env.PREV_BLUE}% | Green ${env.PREV_GREEN}%"
                    }
                }
            }
        }

        /* ========== UPDATE TRAFFIC ========== */
        stage('Update Traffic') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        def matrix = [
                            'canary-10':[blue:90, green:10],
                            'half-50' :[blue:50, green:50],
                            'full-100':[blue:0 , green:100]
                        ]
                        def t = matrix[params.TRAFFIC_SPLIT]
                        if (params.DEPLOYMENT_TARGET == 'blue') {
                            t = [blue:t.green, green:t.blue]
                        }

                        tfUpdateVar(TF_TOKEN, env.TF_WORKSPACE_ID, 'traffic_distribution_blue',  t.blue.toString())
                        tfUpdateVar(TF_TOKEN, env.TF_WORKSPACE_ID, 'traffic_distribution_green', t.green.toString())
                    }
                }
            }
        }

        /* ========== APPLY ========== */
        stage('Terraform Apply') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        try {
                            def runId = tfTriggerRun(
                                TF_TOKEN,
                                env.TF_WORKSPACE_ID,
                                "Deploy ${params.DEPLOYMENT_TARGET} ${params.TRAFFIC_SPLIT} (${env.GIT_COMMIT_SHORT})"
                            )
                            tfWaitRun(TF_TOKEN, runId, 30)
                        } catch (e) {
                            env.ROLLBACK_NEEDED = 'true'
                            throw e
                        }
                    }
                }
            }
        }

        /* ========== HEALTH CHECK ========== */
        stage('Health Check') {
            when { expression { !params.SKIP_TESTS } }
            steps {
                script {
                    try {
                        withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                            sh """
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
                              [ "\$HEALTHY" -ge 2 ] && exit 0
                              sleep 10
                            done
                            exit 1
                            """
                        }
                    } catch (e) {
                        env.ROLLBACK_NEEDED = 'true'
                        throw e
                    }
                }
            }
        }

        /* ========== ROLLBACK ========== */
        stage('Rollback') {
            when { expression { env.ROLLBACK_NEEDED == 'true' } }
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        echo "🔄 ROLLBACK → Blue ${env.PREV_BLUE}% | Green ${env.PREV_GREEN}%"
                        tfUpdateVar(TF_TOKEN, env.TF_WORKSPACE_ID, 'traffic_distribution_blue',  env.PREV_BLUE)
                        tfUpdateVar(TF_TOKEN, env.TF_WORKSPACE_ID, 'traffic_distribution_green', env.PREV_GREEN)
                        def rollbackRunId = tfTriggerRun(
                            TF_TOKEN,
                            env.TF_WORKSPACE_ID,
                            "ROLLBACK (${env.GIT_COMMIT_SHORT})"
                        )
                        tfWaitRun(TF_TOKEN, rollbackRunId, 20)
                    }
                }
            }
        }
    }

    post {
        success { echo "✅ DEPLOYMENT SUCCESSFUL" }
        failure { echo "❌ DEPLOYMENT FAILED (rollback applied if needed)" }
        always  { cleanWs() }
    }
}
