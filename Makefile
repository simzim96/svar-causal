AWS_REGION=eu-central-1
INSTANCE_TYPE=t2.medium
AMI_ID=ami-0c4c4bd6cf0c5fe52  # This is an example AMI for Amazon Linux 2. Change accordingly.
KEY_NAME=depl-utd
VPC=vpc-05f6e8f4526f24397
DEPLOYMENT_NAME=gitlabprod



# disable command echoing, will be done by makeshell
.SILENT:


# virtual env creation, package updates, db migration

# determine the right python binary
.PYTHON3:=$(shell PATH='$(subst $(CURDIR)/.venv/bin:,,$(PATH))' which python3)


setup:
	make install-packages
	echo -e "done. Get started with\n   $$ source .venv/bin/activate\n"


# install exact package versions from requirements.txt.freeze
install-packages: .venv/bin/python
	.venv/bin/python -m pip install --upgrade pip wheel requests setuptools pipdeptree
	.venv/bin/python -m pip install --requirement=requirements.txt.freeze --upgrade --exists-action=w


# update packages from requirements.txt and create requirements.txt.freeze
update-packages: .venv/bin/python
	.venv/bin/python -m pip install --upgrade pip wheel requests setuptools pipdeptree
	PYTHONWARNINGS="ignore" .venv/bin/python -m pip install --requirement=requirements.txt --upgrade --exists-action=w
	make check-for-inconsistent-package-dependencies

# write freeze file
# pkg-ressources is automatically added on ubuntu, but breaks the install.
# https://stackoverflow.com/a/40167445/1380673
	.venv/bin/python -m pip freeze | grep -v "pkg-resources" > requirements.txt.freeze

	echo -e "\033[32msucceeded, please check output above for warnings\033[0m"


# create or update virtualenv
.venv/bin/python:
# if .venv is already a symlink, don't overwrite it
	mkdir -p .venv

# go into the new dir and build it there as venv doesn't work if the target is a symlink
	cd .venv && $(.PYTHON3) -m venv --copies --prompt='[$(shell basename `pwd`)/.venv]' .

# set environment variables
	echo export FLASK_DEBUG=1 >> .venv/bin/activate

# add the project directory to path
	echo $(shell pwd) > `echo .venv/lib/*/site-packages`/project.pth

# install minimum set of required packages
# wheel needs to be early to be able to build wheels
	.venv/bin/python -m pip install --upgrade pip wheel requests setuptools pipdeptree



# run https://github.com/naiquevin/pipdeptree to check whether the currently installed packages have
# incompatible dependencies
check-for-inconsistent-package-dependencies:
	.venv/bin/pipdeptree --warn=fail


# run local jupyter server
run-jupyter:
	.venv/bin/jupyter notebook

# remove virtual env
.cleanup-vitualenv:
	rm -rf .venv

cleanup:
	make -j .cleanup-vitualenv

create-deployment-dir:
	@mkdir -p deployment


