import jenkins.model.*

def result = []

for(slave in Jenkins.instance.slaves) {
  result += slave.name
}

return result