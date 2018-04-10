#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Decorador auxiliar"""

import os
import sys

from functools import wraps
from pycallgraph import PyCallGraph
from pycallgraph import Config
from pycallgraph import GlobbingFilter
from pycallgraph.output import GraphvizOutput

# módulo de ejemplo que se quiere analizar
from .. import scrape_datasets


def profile(profiling_result_path):
    """Decorador de una función para que se corra haciendo profiling."""

    def fn_decorator(fn):
        """Decora una función con el análisis de profiling."""

        @wraps(fn)
        def fn_decorated(*args, **kwargs):
            """Crea la función decorada."""

            graphviz = GraphvizOutput()
            graphviz.output_file = profiling_result_path

            with PyCallGraph(output=graphviz, config=None):
                fn(*args, **kwargs)

        return fn_decorated

    return fn_decorator


@profile("data/test_output/profiling_test.png")
def main():
    scrape_datasets.main(
        sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], replace=True)


if __name__ == '__main__':
    main()
