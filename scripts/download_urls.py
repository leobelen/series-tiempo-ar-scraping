#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import codecs
import sys
from urllib import parse as urlparse

from paths import CATALOGS_DIR_INPUT, DIST_URLS_PATH, SCRAP_URLS_PATH
from paths import get_distribution_download_dir
from paths import get_catalog_scraping_sources_dir
from helpers import get_logger, ensure_dir_exists, print_log_separator
from helpers import download_with_config, get_catalog_download_config

logger = get_logger(os.path.basename(__file__))


def download_scraping_sources(urls):
    for entry in urls:
        catalog_id, scraping_url = entry.split()

        config = get_catalog_download_config(catalog_id)["sources"]

        logger.info("Descargando archivo de scraping para catalogo: {}".format(
            str(catalog_id)))

        logger.info("URL: {}".format(str(scraping_url)))
        logger.info("Comenzando...")

        catalog_scraping_sources_dir = get_catalog_scraping_sources_dir(
            catalog_id)

        ensure_dir_exists(catalog_scraping_sources_dir)
        url = urlparse.urlparse(scraping_url)
        file = os.path.basename(url.path)
        file_path = os.path.join(str(catalog_scraping_sources_dir), str(file))

        try:
            download_with_config(str(scraping_url), str(file_path), config)
            logger.info("Archivo descargado")
        except Exception as e:
            logger.error("Error al descargar el archivo")
            logger.error(e)


def download_distributions(urls):
    for entry in urls:
        parts = entry.split()
        catalog_id, dataset_id, distribution_id, filename, url = parts

        config = get_catalog_download_config(catalog_id)["sources"]

        logger.info(
            "Descargando archivo de distribucion: {} (catálogo {})".format(
                distribution_id, catalog_id))

        logger.info("URL: {}".format(url))
        logger.info("Comenzando...")

        distribution_download_dir = get_distribution_download_dir(
            CATALOGS_DIR_INPUT, str(catalog_id), str(dataset_id),
            str(distribution_id))

        ensure_dir_exists(distribution_download_dir)
        file_path = os.path.join(str(distribution_download_dir), str(filename))

        try:
            download_with_config(url, file_path, config)
            logger.info("Archivo descargado")
        except Exception as e:
            logger.error("Error al descargar el archivo")
            logger.error(e)


def main(sources_type):
    if sources_type == "scraping":
        sources_urls_path = SCRAP_URLS_PATH
    elif sources_type == "distribution":
        sources_urls_path = DIST_URLS_PATH

    try:
        with codecs.open(sources_urls_path, "rb") as f:
            urls = f.readlines()
    except IOError as e:
        logger.error("No se pudo abrir el archivo de URLS.")
        logger.error(e)
        return

    print_log_separator(logger, "Descarga de fuentes: {}".format(sources_type))
    logger.info("# URLS: {}".format(len(urls)))

    if sources_type == "scraping":
        download_scraping_sources(urls)
    elif sources_type == "distribution":
        download_distributions(urls)

    logger.info("Descargas finalizadas para {}.".format(sources_type))


if __name__ == '__main__':
    main(sys.argv[1])
