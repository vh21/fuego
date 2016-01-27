LANG=en_US
JENKINS_USER_PASS="j3nkins"

JEN_URL=http://localhost:8080$URL_PREFIX
JENKINS_INST=/var/lib/jenkins
JENKINS_WAR_FILE=/usr/share/jenkins/jenkins.war
JENKINS_CORE_NAME=`jar tf $JENKINS_WAR_FILE | grep jenkins-core`

JENKINS_CACHE=/var/cache/jenkins/war
# [ -d $JENKINS_CACHE ] || JENKINS_CACHE=/var/run/jenkins/war

RSYNC_ARGS="-ahq --stats"


# $1 - path to fix recursively
fix_permissions() {
  chown -fRH jenkins "$1" 
}

output_errors_only() {
  set +vx
  exec 3>&1
  exec 1>/dev/null
}

default_output() {
  exec 1>&3
}

sync_fetch_jenkins_cli() {
    until wget -nv ${JEN_URL}/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar
    do
        echo "Retrying wget -nv ${JEN_URL}/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar"
        sleep 1
    done
}
