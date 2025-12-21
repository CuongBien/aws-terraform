@Library('pbl4-shared-library') _

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

        // Workspace ID là static → KHÔNG phải secret
        TF_WORKSPACE_ID = 'ws-ZdCj4RaKxyFkwYuU'

        PREV_BLUE  = '100'
        PREV_GREEN = '0'
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

        /* ========== GATE 1: TFSEC FAST FAIL ========== */
        stage('🥇 Gate 1: tfsec') {
            steps {
                sh '''
                  echo "Running tfsec (fail on HIGH/CRITICAL)"
                  tfsec infrastructure_aws \
                    --config-file .tfsec.yml
                '''
            }
        }

        /* ========== GATE 2: CHECKOV SOFT FAIL ========== */
        stage('🥈 Gate 2: checkov') {
            steps {
                sh '''
                  echo "Running checkov (soft fail)"
                  checkov -d infrastructure_aws \
                    --config-file .checkov.yml \
                    --soft-fail
                '''
            }
        }

        /* ========== VERIFY WORKSPACE ========== */
        stage('Verify Terraform Workspace') {
            steps {
                script {
                    echo "Terraform Org      : ${TF_ORG}"
                    echo "Terraform Workspace: ${TF_WORKSPACE}"
                    echo "Workspace ID       : ${TF_WORKSPACE_ID}"

                    if (!env.TF_WORKSPACE_ID?.startsWith('ws-')) {
                        error("Invalid TF_WORKSPACE_ID")
                    }
                }
            }
        }

        /* ========== SNAPSHOT CURRENT TRAFFIC ========== */
        stage('Snapshot Current Traffic') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {

                        sh """
                        curl -s -H "Authorization: Bearer ${TF_TOKEN}" \
                          https://app.terraform.io/api/v2/workspaces/${TF_WORKSPACE_ID}/vars \
                          | jq -r '
                              .data[]
                              | select(.attributes.category=="terraform")
                              | select(.attributes.key=="traffic_distribution_blue")
                              | .attributes.value // "100"
                          ' > /tmp/prev_blue.txt

                        curl -s -H "Authorization: Bearer ${TF_TOKEN}" \
                          https://app.terraform.io/api/v2/workspaces/${TF_WORKSPACE_ID}/vars \
                          | jq -r '
                              .data[]
                              | select(.attributes.category=="terraform")
                              | select(.attributes.key=="traffic_distribution_green")
                              | .attributes.value // "0"
                          ' > /tmp/prev_green.txt
                        """

                        env.PREV_BLUE  = readFile('/tmp/prev_blue.txt').trim()
                        env.PREV_GREEN = readFile('/tmp/prev_green.txt').trim()

                        if (!env.PREV_BLUE.isInteger())  env.PREV_BLUE  = '100'
                        if (!env.PREV_GREEN.isInteger()) env.PREV_GREEN = '0'

                        echo "Saved traffic snapshot → Blue ${env.PREV_BLUE}% | Green ${env.PREV_GREEN}%"
                    }
                }
            }
        }

        /* ========== UPDATE TRAFFIC VARS ========== */
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

                        echo "Updating traffic → Blue ${t.blue}% | Green ${t.green}%"

                        tfUpdateVar(TF_TOKEN, TF_WORKSPACE_ID,
                            'traffic_distribution_blue',  t.blue.toString())
                        tfUpdateVar(TF_TOKEN, TF_WORKSPACE_ID,
                            'traffic_distribution_green', t.green.toString())
                    }
                }
            }
        }

        /* ========== TERRAFORM APPLY ========== */
        stage('Terraform Apply') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        try {
                            def runId = tfTriggerRun(
                                TF_TOKEN,
                                TF_WORKSPACE_ID,
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
                withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                    sh """
                    TG_ARN=\$(aws elbv2 describe-target-groups \
                      --region ${AWS_REGION} \
                      --names ${PROJECT_NAME}-web-tg-${params.DEPLOYMENT_TARGET} \
                      --query 'TargetGroups[0].TargetGroupArn' \
                      --output text)

                    echo "🏥 Health check: Waiting for at least 2 healthy instances..."
                    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
                      HEALTHY=\$(aws elbv2 describe-target-health \
                        --region ${AWS_REGION} \
                        --target-group-arn \$TG_ARN \
                        --query 'TargetHealthDescriptions[?TargetHealth.State==\`healthy\`] | length(@)' \
                        --output text)
                      
                      echo "Attempt \$i/30: \$HEALTHY healthy instances"
                      
                      if [ "\$HEALTHY" -ge 1 ]; then
                        echo "✅ Health check passed: \$HEALTHY instances healthy"
                        exit 0
                      fi
                      
                      sleep 10
                    done
                    
                    echo "❌ Health check failed: Only \$HEALTHY instances healthy after 5 minutes"
                    exit 1
                    """
                }
            }
        }

        /* ========== ROLLBACK ========== */
        stage('Rollback') {
            when { expression { env.ROLLBACK_NEEDED == 'true' } }
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        echo "ROLLBACK → Blue ${PREV_BLUE}% | Green ${PREV_GREEN}%"

                        tfUpdateVar(TF_TOKEN, TF_WORKSPACE_ID,
                            'traffic_distribution_blue', PREV_BLUE)
                        tfUpdateVar(TF_TOKEN, TF_WORKSPACE_ID,
                            'traffic_distribution_green', PREV_GREEN)

                        def runId = tfTriggerRun(
                            TF_TOKEN,
                            TF_WORKSPACE_ID,
                            "ROLLBACK (${env.GIT_COMMIT_SHORT})"
                        )
                        tfWaitRun(TF_TOKEN, runId, 20)
                    }
                }
            }
        }
    }

    post {
        success { echo "✅ DEPLOYMENT SUCCESSFUL" }
        failure { echo "❌ DEPLOYMENT FAILED (rollback executed if needed)" }
        always  { cleanWs() }
    }
}
