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
    stage('push') {
      steps {
        withAWSParameterStore(credentialsId: 'idwhat', regionName: 'ap-southeast-2', path: 'path1/path2', naming: 'whatisnaming', recursive: true)
      }
    }
  }
}