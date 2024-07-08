pipeline {
    agent {
        label 'Agent - 1'
    }
    options {
        timeout(time: 1, unit: 'SECONDS')
    }
    stages {
        stage('Build') {
            steps {
                sh 'echo Hello World, from Build'
            }
        }
        stage('Test') {
            steps {
                sh 'echo Hello World, from Test'
                sh 'sleep 10'
            }
        }
        stage('Deploy') {
            steps {
                sh 'echo Hello World, from Deploy'
            }
        }
    }
}
