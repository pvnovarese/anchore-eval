// Anchore Enterprise Distributed Container Scan
// requires anchore enterprise 
//
pipeline {
  environment {
    // set some variables
    //
    // we don't need registry if using docker hub
    // but if you're using a different registry, set this 
    REGISTRY = 'docker.io'
    //
    // you will need a credential with your docker hub user/pass
    // (or whatever registry you're using) and a credential with
    // user/pass for your anchore instance:
    // ...
    // first let's set the docker hub credential and extract user/pass
    // we'll use the USR part for figuring out where are repository is
    HUB_CREDENTIAL = "docker-hub"
    // use credentials to set DOCKER_HUB_USR and DOCKER_HUB_PSW
    DOCKER_HUB = credentials("${HUB_CREDENTIAL}")
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweak REPOSITORY 
    REPOSITORY = "${DOCKER_HUB_USR}/${JOB_BASE_NAME}"
    TAG = "${GIT_BRANCH.split("/")[1]}"
    // TAG = "build-${BUILD_NUMBER}"
    //
    // Variables needed for anchorectl to communicate with anchore enterprise:
    ANCHORECTL_URL = credentials("Anchorectl_Url")
    ANCHORECTL_USERNAME = credentials("Anchorectl_Username")
    ANCHORECTL_PASSWORD = credentials("Anchorectl_Password")
    // change ANCHORECTL_FAIL_BASED_ON_RESULTS to "true" if you want to break on policy violations
    ANCHORECTL_FAIL_BASED_ON_RESULTS = "false"
    //
  } // end environment

  agent any
  
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"    
    
    stage('Build Image') {
      steps {
        script {
          // login to docker hub (or whatever registry)
          // build image and push it to registry
          //
          sh """
            echo "${DOCKER_HUB_PSW}" | docker login ${REGISTRY} -u ${DOCKER_HUB_USR} --password-stdin
            docker build -t ${REGISTRY}/${REPOSITORY}:${TAG} --pull -f ./Dockerfile .
            docker push ${REGISTRY}/${REPOSITORY}:${TAG}
          """
        } // end script
      } // end steps
    } // end stage "Build Image"
    
    stage('Analyze Image w/ anchorectl') {
      steps {
        script {
          sh """
            ### install latest anchorectl 
            curl -sSfL  https://anchorectl-releases.anchore.io/anchorectl/install.sh  | sh -s -- -b $HOME/.local/bin 
            export PATH="$HOME/.local/bin/:$PATH"          
            #
            ### actually add the image to the queue to be scanned
            #
            ### --wait tells anchorectl to block until the scan is complete (this isn't always necessary but if you want to pull 
            ### the vulnerability list and/or policy report, you probably want to wait
            #
            ### --no-auto-subscribe tells the policy engine to just pull the image and scan it once.  if you don't pass this 
            ### option, anchore enterprise will continually poll the tag to see if any new version has been pushed and if 
            ### it detects a new image, it automatically pulls it and scans it.
            #
            ### --force tells Anchore Enterprise to build a new SBOM even if one already exists in the catalog
            #
            ### --dockerfile is optional but if you want to test Dockerfile instructions this is recommended
            #
            anchorectl image add --wait --no-auto-subscribe --force --dockerfile ./Dockerfile --from registry ${REGISTRY}/${REPOSITORY}:${TAG}
            #
            ### pull vulnerability list (optional)
            anchorectl image vulnerabilities ${REGISTRY}/${REPOSITORY}:${TAG}
            #
            ### check policy evaluation
            anchorectl image check --detail ${REGISTRY}/${REPOSITORY}:${TAG}
            # 
            ### if you want to break the pipeline on a policy violation, add "--fail-based-on-results"
            ### or change the ANCHORECTL_FAIL_BASE_ON_RESULTS variable above to "true"
          """
        } // end script 
      } // end steps
    } // end stage "analyze image with anchorectl"
    
    // optional stage, this just deletes the image locally so I don't end up with 300 old images
    //
    stage('Clean Up') {
      // delete the images locally
      steps {
        sh 'docker rmi ${REGISTRY}/${REPOSITORY}:${TAG} || failure=1' 
        //
        // the "|| failure=1" at the end of this line just catches problems with the :prod
        // tag not existing if we didn't uncomment the optional "re-tag as prod" stage
        //
      } // end steps
    } // end stage "clean up"
    
  } // end stages
} // end pipeline
