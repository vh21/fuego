import jenkins.model.*
import groovy.io.FileType

def list = []
last_used = new File("/home/jenkins/logs/"+test_name+"/last_used_testplan")
if (last_used.exists()) {
  list += last_used.getText().replaceAll("\n","")
}
  
  
def dir = new File("/home/jenkins/overlays/testplans/")
dir.eachFileRecurse (FileType.FILES) { file ->
  list += file.getName().split("\\.")[0]
}

list = list.unique()

return list