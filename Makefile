all: check_postinstall

check_postinstall: postinstall_sage.sh
	cp postinstall_sage.sh sagemath/postinstall_sage.sh
	cp postinstall_sage.sh sagemath-develop/postinstall_sage.sh

sagemath: sagemath/Dockerfile sagemath/install_sage.sh check_postinstall
	docker build --tag="sagemath/sagemath" sagemath

sagemath-develop: sagemath-develop/Dockerfile sagemath-develop/install_sage.sh check_postinstall
	docker build --tag="sagemath/sagemath-develop" sagemath-develop

sagemath-jupyter: sagemath sagemath-jupyter/Dockerfile
	docker build --tag="sagemath/sagemath-jupyter" sagemath-jupyter

sagemath-patchbot: sagemath-develop sagemath-patchbot/Dockerfile
	docker build --tag="sagemath/sagemath-patchbot" sagemath-patchbot