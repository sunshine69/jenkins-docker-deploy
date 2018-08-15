pipeline {
  agent {
    dockerfile {
      filename 'Dockerfile'
    }

  }
  stages {
    stage('Build docker image') {
      steps {
        sh 'docker build -t jenkins/xvt-jenkins:${BUILD_NUMBER} .'
      }
    }
  }
}