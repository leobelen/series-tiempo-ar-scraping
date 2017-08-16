#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Actualiza las series en un servidor webdav
"""

from __future__ import unicode_literals
from __future__ import print_function
from __future__ import with_statement
import os
import sys
import arrow
import pydatajson
import json
import easywebdav
import yaml
import os
import glob

from helpers import get_logger
from data import get_time_series_dict, generate_time_series_jsons

sys.path.insert(0, os.path.abspath(".."))


def get_webdav_connection(config_webdav_path):

    with open(config_webdav_path, 'r') as f:
        params = yaml.load(f)["webdav"]

    webdav = easywebdav.connect(
        params["host"], username=params["user"],
        password=params["pass"], protocol='https',
        port=params["port"],
        verify_ssl=os.path.join(
            os.path.dirname(config_webdav_path),
            params["pem"]
        )
    )

    return webdav