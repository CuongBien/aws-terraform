// Jenkinsfile - CI/CD Pipeline for Blue/Green Deployment
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'DEPLOYMENT_TARGET',
            choices: ['green', 'blue'],
            description: 'Deploy to which environment? (Green = new version, Blue = current)'
        )
        choice(
            name: 'TRAFFIC_SPLIT',
            choices: ['canary-10', 'half-50', 'full-100'],
            description: 'Traffic distribution after deployment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip health checks and validation'
        )
    }
    
    environment {
        AWS_REGION = 'us-east-1'
        PROJECT_NAME = 'pbl4'
        TF_WORKSPACE = 'pbl4-three-tier-dev'
        PACKER_DIR = 'packer'
        TF_DIR = 'infrastructure_aws'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.BUILD_TIMESTAMP = sh(
                        script: "date +%Y%m%d-%H%M%S",
                        returnStdout: true
                    ).trim()
                }
                echo "Building commit: ${env.GIT_COMMIT_SHORT} at ${env.BUILD_TIMESTAMP}"
            }
        }
        
        stage('Build AMIs with Packer') {
            parallel {
                stage('Build Web Tier AMI') {
                    steps {
                        withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                            dir("${PACKER_DIR}") {
                                sh """
                                    packer init web-tier.pkr.hcl
                                    packer build \
                                        -var 'aws_region=${AWS_REGION}' \
                                        -var 'project_name=${PROJECT_NAME}' \
                                        -var 'environment=${params.DEPLOYMENT_TARGET}' \
                                        -var 'git_commit=${env.GIT_COMMIT_SHORT}' \
                                        web-tier.pkr.hcl | tee web-build.log
                                """
                                script {
                                    env.WEB_AMI_ID = sh(
                                        script: "grep 'AMI:' web-build.log | awk '{print \$2}'",
                                        returnStdout: true
                                    ).trim()
                                }
                                echo "Web AMI created: ${env.WEB_AMI_ID}"
                            }
                        }
                    }
                }
                
                stage('Build App Tier AMI') {
                    steps {
                        withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                            dir("${PACKER_DIR}") {
                                sh """
                                    packer init app-tier.pkr.hcl
                                    packer build \
                                        -var 'aws_region=${AWS_REGION}' \
                                        -var 'project_name=${PROJECT_NAME}' \
                                        -var 'environment=${params.DEPLOYMENT_TARGET}' \
                                        -var 'git_commit=${env.GIT_COMMIT_SHORT}' \
                                        app-tier.pkr.hcl | tee app-build.log
                                """
                                script {
                                    env.APP_AMI_ID = sh(
                                        script: "grep 'AMI:' app-build.log | awk '{print \$2}'",
                                        returnStdout: true
                                    ).trim()
                                }
                                echo "App AMI created: ${env.APP_AMI_ID}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Update Terraform Variables') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        def targetEnv = params.DEPLOYMENT_TARGET
                        sh """
                            # Update AMI IDs for target environment
                            curl -X PATCH \
                              -H "Authorization: Bearer \$TF_TOKEN" \
                              -H "Content-Type: application/vnd.api+json" \
                              -d '{
                                "data": {
                                  "type": "vars",
                                  "attributes": {
                                    "key": "ami_web_${targetEnv}",
                                    "value": "${env.WEB_AMI_ID}",
                                    "category": "terraform"
                                  }
                                }
                              }' \
                              https://app.terraform.io/api/v2/workspaces/${TF_WORKSPACE}/vars/ami_web_${targetEnv}
                            
                            curl -X PATCH \
                              -H "Authorization: Bearer \$TF_TOKEN" \
                              -H "Content-Type: application/vnd.api+json" \
                              -d '{
                                "data": {
                                  "type": "vars",
                                  "attributes": {
                                    "key": "ami_app_${targetEnv}",
                                    "value": "${env.APP_AMI_ID}",
                                    "category": "terraform"
                                  }
                                }
                              }' \
                              https://app.terraform.io/api/v2/workspaces/${TF_WORKSPACE}/vars/ami_app_${targetEnv}
                        """
                    }
                }
                echo "Terraform variables updated for ${params.DEPLOYMENT_TARGET} environment"
            }
        }
        
        stage('Deploy Infrastructure') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    sh """
                        # Trigger Terraform Cloud run
                        curl -X POST \
                          -H "Authorization: Bearer \$TF_TOKEN" \
                          -H "Content-Type: application/vnd.api+json" \
                          -d '{
                            "data": {
                              "attributes": {
                                "message": "Deploy ${params.DEPLOYMENT_TARGET} - Commit ${env.GIT_COMMIT_SHORT}"
                              },
                              "type": "runs",
                              "relationships": {
                                "workspace": {
                                  "data": {
                                    "type": "workspaces",
                                    "id": "${TF_WORKSPACE}"
                                  }
                                }
                              }
                            }
                          }' \
                          https://app.terraform.io/api/v2/runs | tee tf-run.json
                        
                        # Extract run ID
                        RUN_ID=\$(cat tf-run.json | grep -o '"id":"run-[^"]*' | head -1 | cut -d'"' -f4)
                        echo "Terraform Run ID: \$RUN_ID"
                        
                        # Wait for plan to complete
                        echo "Waiting for Terraform plan..."
                        sleep 60
                    """
                }
                echo "Infrastructure deployment initiated"
            }
        }
        
        stage('Health Check') {
            when {
                expression { params.SKIP_TESTS == false }
            }
            steps {
                withCredentials([aws(credentialsId: 'aws-deployment-credentials')]) {
                    script {
                        def targetEnv = params.DEPLOYMENT_TARGET
                        sh """
                            # Get target group ARN
                            TG_ARN=\$(aws elbv2 describe-target-groups \
                                --region ${AWS_REGION} \
                                --names ${PROJECT_NAME}-web-tg-${targetEnv} \
                                --query 'TargetGroups[0].TargetGroupArn' \
                                --output text)
                            
                            # Wait for healthy targets
                            echo "Checking health of ${targetEnv} instances..."
                            for i in {1..30}; do
                                HEALTHY=\$(aws elbv2 describe-target-health \
                                    --region ${AWS_REGION} \
                                    --target-group-arn \$TG_ARN \
                                    --query 'TargetHealthDescriptions[?TargetHealth.State==\`healthy\`] | length(@)' \
                                    --output text)
                                
                                if [ "\$HEALTHY" -ge 2 ]; then
                                    echo "✓ ${targetEnv} environment healthy (\$HEALTHY instances)"
                                    exit 0
                                fi
                                
                                echo "Waiting... (\$HEALTHY/2 healthy, attempt \$i/30)"
                                sleep 10
                            done
                            
                            echo "✗ Health check failed after 5 minutes"
                            exit 1
                        """
                    }
                }
            }
        }
        
        stage('Canary Testing') {
            when {
                expression { params.TRAFFIC_SPLIT == 'canary-10' && params.SKIP_TESTS == false }
            }
            steps {
                echo "Running canary tests with 10% traffic..."
                // Add your test scripts here
                sleep 30
            }
        }
        
        stage('Update Traffic Distribution') {
            steps {
                withCredentials([string(credentialsId: 'terraform-cloud-token', variable: 'TF_TOKEN')]) {
                    script {
                        def trafficMap = [
                            'canary-10': [blue: 90, green: 10],
                            'half-50': [blue: 50, green: 50],
                            'full-100': [blue: 0, green: 100]
                        ]
                        def traffic = trafficMap[params.TRAFFIC_SPLIT]
                        
                        if (params.DEPLOYMENT_TARGET == 'blue') {
                            traffic = [blue: traffic.green, green: traffic.blue]
                        }
                        
                        sh """
                            # Update traffic weights
                            curl -X PATCH \
                              -H "Authorization: Bearer \$TF_TOKEN" \
                              -H "Content-Type: application/vnd.api+json" \
                              -d '{
                                "data": {
                                  "type": "vars",
                                  "attributes": {
                                    "key": "traffic_weight_blue",
                                    "value": "${traffic.blue}",
                                    "category": "terraform"
                                  }
                                }
                              }' \
                              https://app.terraform.io/api/v2/workspaces/${TF_WORKSPACE}/vars/traffic_weight_blue
                            
                            curl -X PATCH \
                              -H "Authorization: Bearer \$TF_TOKEN" \
                              -H "Content-Type: application/vnd.api+json" \
                              -d '{
                                "data": {
                                  "type": "vars",
                                  "attributes": {
                                    "key": "traffic_weight_green",
                                    "value": "${traffic.green}",
                                    "category": "terraform"
                                  }
                                }
                              }' \
                              https://app.terraform.io/api/v2/workspaces/${TF_WORKSPACE}/vars/traffic_weight_green
                        """
                        
                        echo "Traffic updated: Blue ${traffic.blue}%, Green ${traffic.green}%"
                    }
                }
            }
        }
        
        stage('Final Approval') {
            when {
                expression { params.TRAFFIC_SPLIT == 'full-100' }
            }
            steps {
                input message: 'Complete cutover to new version?', ok: 'Confirm'
                echo 'Deployment confirmed by operator'
            }
        }
    }
    
    post {
        success {
            echo "✓ Deployment successful!"
            echo "Web AMI: ${env.WEB_AMI_ID}"
            echo "App AMI: ${env.APP_AMI_ID}"
            echo "Target: ${params.DEPLOYMENT_TARGET}"
            echo "Traffic: ${params.TRAFFIC_SPLIT}"
        }
        failure {
            echo "✗ Deployment failed. Check logs above."
        }
        always {
            cleanWs()
        }
    }
}