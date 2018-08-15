pipeline {
  agent {
    node {
      label 'docker'
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