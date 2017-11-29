def mvnCmd = "mvn"
// def mvnCmd = "mvn -s configuration/cicd-settings.xml"
def gitUrl = 'http://gogs:3000/heewon1.kim/spring-petclinic'
def gitBranch = 'master'
def ecrRepo = '031852407939.dkr.ecr.us-east-1.amazonaws.com/devops-demo'
def ecrUrl = "https://${ecrRepo}"
def region = 'us-east-1'
def tag = 'latest'
def credential = 'ecr-credential'
def kubeconfig = '/home/jenkins/.kube/config'
def feSvcName = 'petclinic-service'
def userInput = null
def branch = null

node('mvn') {
    stage ('Jar Build') {
	// this will not work until we use multibranch pipeline
	checkout scm

	// git branch: gitBranch, url: gitUrl
	// branch = env.BRANCH_NAME
	// env.BRANCH_NAME =~ "PR-*"
	// if (branch =~ /QA_([a-z_]+)/) {
	//     def flavor = flavor(branch)
	//     echo "Building flavor ${flavor}"
	//     // do some custom build here
	// }

	// figure out either tag or hash id for building and creating images
	// GIT_VERSION = sh (
      	// 	script: 'git describe --tags',
      	// 	returnStdout: true
    	// ).trim()

	sh "git rev-parse --short HEAD > commit-id"
    	tag = readFile('commit-id').replace("\n", "").replace("\r", "")

	sh "${mvnCmd} clean install -DskipTests=true"
    }

    stage ('Test and Analysis') {
        parallel (
            'Test': {
                sh "${mvnCmd} test"
                step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
            },
            'Static Analysis': {
                sh "${mvnCmd} sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -DskipTests=true"
            },
	    // 'Analysis (Security, Bugs, etc)': {
	    //     sh "${mvnCmd} site -DskipTests=true"
	    //     step([$class: 'CheckStylePublisher', unstableTotalAll:'20'])
	    //     step([$class: 'PmdPublisher', unstableTotalAll:'20'])
	    //     step([$class: 'FindBugsPublisher', pattern: '**/findbugsXml.xml', unstableTotalAll:'20'])
	    //     step([$class: 'JacocoPublisher'])
	    //     publishHTML (target: [keepAll: true, reportDir: 'target/site', reportFiles: 'project-info.html', reportName: "Site Report"])
	    // }
        )
    }

    // stage ('Push to Nexus') {
    //    sh "${mvnCmd} deploy -DskipTests=true"
    // }
    
    stage ('Docker Build') {
        def app = docker.build(ecrRepo)
        println(app)
    }
    
    stage ('Docker Push') {
        try {
            println("Docker push using ${credential}")
            docker.withRegistry(ecrUrl, credential) {
                docker.image(ecrRepo).push(tag)
            }
        } catch (exec) {
            def ecr_credential = ['ecr', region, credential].join(':')
            println("Trying the credential ${ecr_credential}")
            docker.withRegistry(ecrUrl, ecr_credential) {
                docker.image(ecrRepo).push(tag)
            }
        }

	// TODO, do some docker image inside test
	// docker.image(imageName).inside {
	//   run something inside of running docker instance
	// }
    }
    
    stage ('Deploy to Stage') {
        // TODO heewon1.kim, do some sanity check before deploying such as deploy configs and cluster status and others
        // TODO heewon1.kim, notify people that we are updating stage environment with detail from commit and url to github
	switch (branch) {
	    // Roll out to canary environment
	    case "canary":
		echo "doing a canary push"
		sh "kubectl --kubeconfig=${kubeconfig} config get-contexts"
		sh "kubectl --kubeconfig=${kubeconfig} -n default apply -f configuration/k8s/"
		sh "kubectl --kubeconfig=${kubeconfig} -n default get service/${feSvcName} --output=json | jq -r '.status.loadBalancer.ingress[0].hostname'"

	    // Roll out to Stage
	    case "master":
		echo "doing a stage push"
		sh "kubectl --kubeconfig=${kubeconfig} config get-contexts"
		sh "kubectl --kubeconfig=${kubeconfig} -n default apply -f configuration/k8s/"
		sh "kubectl --kubeconfig=${kubeconfig} -n default get service/${feSvcName} --output=json | jq -r '.status.loadBalancer.ingress[0].hostname'"

            // Roll out a dev environment
	    default:
		// 031852407939.dkr.ecr.us-east-1.amazonaws.com/devops-demo:latest
		sh "sed -i.bak \'s#ecr-image#${ecrRepo}:${tag}#\' configuration/k8s/pet-clinic-deploy.yml"
		sh "kubectl --kubeconfig=${kubeconfig} config get-contexts"
		sh "kubectl --kubeconfig=${kubeconfig} apply -f configuration/k8s/ -n default"
		sh "kubectl --kubeconfig=${kubeconfig} rollout status deployment/petclinic -n default"
		sh "kubectl --kubeconfig=${kubeconfig} -n default get service/${feSvcName} --output=json | jq -r '.status.loadBalancer.ingress[0].hostname'"
	}
    }

    stage ('Wait for an input') {
        userInput = input(
            id: 'userInput', message: 'Let\'s promote?', parameters: [
            [$class: 'TextParameterDefinition', defaultValue: 'Stage', description: 'Environment', name: 'env'],
            [$class: 'TextParameterDefinition', defaultValue: 'Canary', description: 'Target', name: 'target']
        ])
    }

    stage ('Deploy to Production') {
        echo ("Env: "+userInput['env'])
        echo ("Target: "+userInput['target'])
        // git branch: 'master', url: 'http://gogs:3000/heewon1.kim/spring-petclinic'
        // sh "kubectl --kubeconfig=${kubeconfig} -n default apply -f deploy/"
        // sh "kubectl --kubeconfig=${kubeconfig} -n default get service/${feSvcName} --output=json | jq -r '.status.loadBalancer.ingress[0].hostname"
    }
}

@NonCPS
def flavor(branchName) {
  def matcher = (branchName =~ /QA_([a-z_]+)/)
  assert matcher.matches()
  matcher[0][1]
}
