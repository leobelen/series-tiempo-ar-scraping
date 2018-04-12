# Makefile para Ubuntu 16.04
SHELL = bash
SERIES_TIEMPO_PIP ?= pip
SERIES_TIEMPO_PYTHON ?= python
VIRTUALENV = series
#CONDA_ENV = series

.PHONY: all \
		clean \
		extract_catalogs \
		send_extraction_report \
		generate_urls \
		download_sources \
		scrape_datasets \
		send_transformation_report \
		install_anaconda \
		create_dir \
		setup_anaconda \
		setup_virtualenv \
		custom_steps

setup_server: install_cron install_nginx start_nginx

# recetas para correr el ETL
all: extraction transformation custom_steps
extraction: extract_catalogs send_extraction_report generate_urls download_sources
transformation: scrape_datasets send_transformation_report

install_anaconda:
	wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
	bash Miniconda2-latest-Linux-x86_64.sh
	rm Miniconda2-latest-Linux-x86_64.sh

# para esto es necesario frenar cualquier otro servicio web en el puerto 80
# también conviene instalar el monitoreo con amplify
install_nginx:
	# sudo service apache2 stop
	sudo apt-get update && sudo apt-get install nginx && sudo apt-get install nginx-extras
	sudo ufw allow 'Nginx HTTP'
	sudo cp config/nginx.conf /etc/nginx/nginx.conf
	# sudo service nginx restart

test_nginx_conf:
	# TODO: hacer que no levante nginx si falla el test
	sudo /etc/init.d/nginx configtest -c scripts/config/nginx.conf
	sudo /etc/init.d/nginx configtest

# FILE SERVER
start_python_server:
	cd data/output && python -m SimpleHTTPServer 8080

start_nginx:
	# sudo nginx -p . -c scripts/config/nginx.conf
	# /etc/init.d/nginx configtest
	sudo cp config/nginx.conf /etc/nginx/nginx.conf
	sudo systemctl start nginx

stop_nginx:
	# Usar en casos extremos
	# killall nginx
	# sudo nginx -s stop
	sudo systemctl stop nginx

restart_nginx: stop_nginx start_nginx

setup_virtualenv: create_dir
	$(SERIES_TIEMPO_PIP) install virtualenv --upgrade
	test -d $(VIRTUALENV)/bin/activate || virtualenv $(VIRTUALENV)
	source $(VIRTUALENV)/bin/activate; \
	$(SERIES_TIEMPO_PIP) install -r requirements.txt

setup_anaconda: create_dir
	conda create -n $(CONDA_ENV) --no-default-packages
	source activate $(CONDA_ENV); \
	$(SERIES_TIEMPO_PIP) install -r requirements.txt

update_environment: create_dir
	git pull origin master
	$(SERIES_TIEMPO_PIP) install -r requirements.txt --upgrade

create_dir:
	mkdir -p logs
	mkdir -p docs
	mkdir -p scripts
	mkdir -p data
	mkdir -p data/input
	mkdir -p data/input/catalog
	mkdir -p data/output
	mkdir -p data/output/catalog
	mkdir -p data/test_output
	mkdir -p data/test_output/catalog
	mkdir -p data/reports
	mkdir -p data/backup
	mkdir -p data/backup/catalog

install_cron: config/cron_jobs
	@echo "LANG=en_US.UTF-8" >> .cronfile
	@echo "LANGUAGE=en" >> .cronfile
	@echo "LC_CTYPE=en_US.UTF-8" >> .cronfile
	@echo "PYTHONIOENCODING=utf8" >> .cronfile
	@echo "PATH=$(PATH)" >> .cronfile
	@echo "SERIES_TIEMPO_DIR=$$PWD" >> .cronfile
	@echo "SERIES_TIEMPO_PYTHON=`which python`" >> .cronfile
	@echo "SERIES_TIEMPO_PIP=`which pip`" >> .cronfile
	cat config/cron_jobs >> .cronfile
	crontab .cronfile
	rm .cronfile
	touch config/cron_jobs

# EXTRACTION
extract_catalogs:
	$(SERIES_TIEMPO_PYTHON) scripts/extract_catalogs.py

send_extraction_report:
	$(SERIES_TIEMPO_PYTHON) scripts/send_email.py extraccion

generate_urls:
	$(SERIES_TIEMPO_PYTHON) scripts/generate_urls.py scraping
	$(SERIES_TIEMPO_PYTHON) scripts/generate_urls.py distribution

download_sources:
	$(SERIES_TIEMPO_PYTHON) scripts/download_urls.py scraping
	$(SERIES_TIEMPO_PYTHON) scripts/download_urls.py distribution

# TRANSFORMATION
scrape_datasets:
	$(SERIES_TIEMPO_PYTHON) scripts/scrape_datasets.py replace

send_transformation_report:
	$(SERIES_TIEMPO_PYTHON) scripts/send_email.py scraping

# CLEAN
clean:
	rm -rf data/input/
	rm -rf data/output/
	rm -rf data/test_output/
	rm -rf data/reports
	make create_dir

custom_steps:
	bash config/custom_steps.sh `$(SERIES_TIEMPO_PYTHON) scripts/paths.py`

# TEST
profiling_test: data/output/catalog/$(PROFILING_CATALOG_ID)/data.json
	$(SERIES_TIEMPO_PYTHON) -m scripts.tests.profiling $^ \
		data/input/catalog/$(PROFILING_CATALOG_ID)/sources/ \
		data/test_output/catalog/$(PROFILING_CATALOG_ID)/dataset/ \
		$(PROFILING_CATALOG_ID)

# DOCUMENTACIÓN Y RELEASE
release: clean ## package and upload a release
	python setup.py sdist upload
	python setup.py bdist_wheel upload

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	python setup.py install

pypi: ## register the package to PyPi get travis ready to deploy to pip
	make dist
	twine upload dist/*
	python travis_pypi_setup.py

doctoc: ## generate table of contents, doctoc command line tool required
        ## https://github.com/thlorenz/doctoc
	doctoc --title "## Indice" README.md
	bash fix_github_links.sh README.md
