pipeline {
  agent {
    node {
      label 'docker'
    }

  }
  stages {
    stage('Build docker image') {
      steps {
        sh './build.sh'
      }
    }
  }
}