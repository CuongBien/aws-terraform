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

        /* ========== GATE 1: TFSEC FAST FAIL ========== */
        stage('🥇 Gate 1: tfsec (Fast Fail)') {
            steps {
                script {
                    echo "🚨 Running tfsec - CRITICAL/HIGH issues will FAIL pipeline"
                    
                    // Run tfsec WITHOUT soft-fail - will fail pipeline on HIGH/CRITICAL
                    sh """
                    tfsec infrastructure_aws \
                      --config-file .tfsec.yml \
                      --format default
                    """
                    
                    echo "✅ tfsec passed - No CRITICAL/HIGH security issues found"
                }
            }
        }

        /* ========== GATE 2: CHECKOV DEEP SCAN ========== */
        stage('🥈 Gate 2: checkov (Deep Scan)') {
            steps {
                script {
                    echo "🔍 Running checkov - Compliance & secrets scan (warning only)"
                    
                    // Run checkov with soft-fail - only warns, doesn't block
                    try {
                        sh """
                        checkov -d infrastructure_aws \
                          --config-file .checkov.yml \
                          --soft-fail
                        """
                        echo "✅ checkov scan completed"
                    } catch (e) {
                        echo "⚠️ checkov findings - Review recommended but not blocking"
                    }
                }
            }
        }

        /* ========== RESOLVE WORKSPACE ID ========== */
        stage('Resolve Terraform Workspace') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        echo "🔍 Getting Terraform Workspace ID..."
                        echo "Organization: ${TF_ORG}"
                        echo "Workspace: ${TF_WORKSPACE}"
                        
                        // Use Python to avoid Jenkins credential masking - write to file
                        sh(script: '''
                            python3 << 'PYTHON_SCRIPT'
import os
import urllib.request
import json
import sys

try:
    token = os.environ.get('TF_TOKEN', '')
    org = os.environ.get('TF_ORG', '')
    workspace = os.environ.get('TF_WORKSPACE', '')
    
    if not token:
        print('ERROR: TF_TOKEN not found', file=sys.stderr)
        sys.exit(1)
    
    url = f'https://app.terraform.io/api/v2/organizations/{org}/workspaces/{workspace}'
    req = urllib.request.Request(url)
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Content-Type', 'application/vnd.api+json')
    
    response = urllib.request.urlopen(req)
    data = json.loads(response.read().decode('utf-8'))
    
    workspace_id = data.get('data', {}).get('id', '')
    if workspace_id:
        # Write to file to avoid Jenkins masking stdout
        with open('/tmp/workspace_id.txt', 'w') as f:
            f.write(workspace_id)
        print(f'SUCCESS: Workspace ID saved (length: {len(workspace_id)})', file=sys.stderr)
    else:
        print('ERROR: No workspace ID in response', file=sys.stderr)
        print(f'Response: {json.dumps(data, indent=2)}', file=sys.stderr)
        sys.exit(1)
        
except Exception as e:
    print(f'ERROR: {str(e)}', file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
                        ''')
                        
                        env.TF_WORKSPACE_ID = readFile('/tmp/workspace_id.txt').trim()
                        
                        echo "✅ Workspace ID: ${env.TF_WORKSPACE_ID}"
                        
                        if (env.TF_WORKSPACE_ID == null || env.TF_WORKSPACE_ID == 'null' || env.TF_WORKSPACE_ID == '') {
                            error("❌ Failed to get Terraform Workspace ID. Check token permissions and workspace name.")
                        }
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
