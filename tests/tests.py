from subprocess import check_output, call, CalledProcessError

import os
import re
from pytest import fixture
from pytest import mark
from time   import sleep

@fixture
def outputs():
    outputs = {'irene'       : 'pmaps',
               'dorothea'    : 'kdst',
               'penthesilea' : 'hdst'}
    return outputs

@fixture
def paths():
    data = {'prod': prod(),
            'dev' : dev()}
    return data

def prod():
    ceres     = os.environ['CERESDIR']
    ceres_tag = get_tag(ceres)
    ic        = '/software/IC'
    ic_tag    = get_tag(ic)
    return ceres, ceres_tag, ic, ic_tag

def dev():
    ceres     = os.environ['CERESDEVDIR']
    ceres_tag = get_tag(ceres)
    ic        = '/software/IC-dev'
    ic_tag    = get_tag(ic)
    return ceres, ceres_tag, ic, ic_tag

def get_tag(path):
    cmd = 'cd {}; git describe --tags'.format(path)
    output = check_output(cmd, shell=True, executable='/bin/bash')
    tag = output.strip().split('\n')[0]
    return tag

@mark.parametrize(  'city,       config,   version',
                  (('irene'   , 'kr1300', 'prod'),
                   ('irene'   , 'kr1300', 'dev')))
def test_run_1to1(paths, city, config, version, outputs):
    run_number = 4730
    ceres, ceres_tag, ic, ic_tag = paths[version]
    cmd  = 'cd {}; ./run_ceres -j 50 -c {} -r {} -t {} -m 2'
    cmd  = cmd.format(ceres, city, run_number, config)
    print cmd
    cmd = cmd.format(run_number, config)
    output = check_output(cmd, shell=True, executable='/bin/bash')
    sleep(10)

    #check path
    path = '/analysis/4730/hdf5/{}/{}/{}/{}'
    path = path.format(version, ic_tag, ceres_tag, outputs[city])
    assert os.path.isdir(path)

    #check files
    pattern = '{}_(\d+)_{}_{}_{}_{}.h5'
    pattern = pattern.format(outputs[city], run_number,
                             ic_tag, ceres_tag, config)
    for f in os.listdir(path):
        assert re.match(pattern, f)

@mark.parametrize(  'city,       config,   version',
                  (('dorothea', 'kr'    , 'prod'),
                   ('dorothea', 'kr'    , 'dev')))
def test_run_allto1(paths, city, config, version, outputs):
    run_number = 4730
    ceres, ceres_tag, ic, ic_tag = paths[version]
    cmd  = 'cd {}; ./run_ceres -j 50 -c {} -r {} -t {} -m 2'
    cmd  = cmd.format(ceres, city, run_number, config)
    print cmd
    cmd = cmd.format(run_number, config)
    output = check_output(cmd, shell=True, executable='/bin/bash')
    sleep(10)

    #check path
    path = '/analysis/4730/hdf5/{}/{}/{}/{}'
    path = path.format(version, ic_tag, ceres_tag, outputs[city])
    assert os.path.isdir(path)

    #check files
    pattern = '{}_{}_{}_{}_{}.h5'
    pattern = pattern.format(outputs[city], run_number,
                             ic_tag, ceres_tag, config)
    for f in os.listdir(path):
        assert re.match(pattern, f)
