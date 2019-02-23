#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
from distutils.dir_util import copy_tree
copy_tree("../../library/python/gslab_make", "./gslab_make") # Copy from gslab tools stored locally
from gslab_make.dir_mod import *
from gslab_make.get_externals import *
from gslab_make.make_log import *
from gslab_make.make_links import *
from gslab_make.make_link_logs import *
from gslab_make.run_program import *

stata_exe = os.environ.get('STATAEXE')
if stata_exe:
    import copy
    default_run_stata = copy.copy(run_stata)
    def run_stata(**kwargs):
        kwargs['executable'] = stata_exe
        default_run_stata(**kwargs)

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = '../output/', output_dir = '../output/', temp_dir = '../temp/')
clear_dirs('../output', '../temp/')
start_make_logging()

run_stata(program = 'example.do')

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')
#raw_input??

