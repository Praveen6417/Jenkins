pipeline {
    agent {
        label 'Agent - 1'
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
            }
        }
        stage('Deploy') {
            steps {
                sh 'echo Hello World, from Deploy'
            }
        }
    }
}
