import jenkins.model.*
def result = []

for (item in Jenkins.instance.items) {
  if ( !(item.name =~ /^Run\ .*|^Service\..*|^Matrix\..*/) )
    result += item.name
}

return result  