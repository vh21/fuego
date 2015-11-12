import jenkins.model.*
import groovy.io.FileType

def list = []
last_used = new File("JTA_ENGINE_PATH_PLACEHOLDER/logs/"+test_name+"/last_used_testplan")
if (last_used.exists()) {
  list += last_used.getText().replaceAll("\n","")
}
  
  
def dir = new File("JTA_ENGINE_PATH_PLACEHOLDER/overlays/testplans/")
dir.eachFileRecurse (FileType.FILES) { file ->
  list += file.getName().split("\\.")[0]
}

list = list.unique()

return list