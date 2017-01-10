if [ "$(id -u)" == "0" ]; then
	JENKINS_UID=$(id -u $SUDO_USER)
else
	JENKINS_UID=$(id -u $USER)
fi

sudo docker build -t fuego --build-arg HTTP_PROXY=$http_proxy --build-arg uid=$JENKINS_UID .
