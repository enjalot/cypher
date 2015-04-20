#!/usr/bin/env python
from fabric.api import task, env, run, local, sudo, put, execute, prompt
from fabric.context_managers import cd, settings
from fabric.contrib.files import exists
from fabric.utils import error
from time import sleep
import sys

env.use_ssh_config = True

lever = {}
lever['repo_cache'] = '~/.deploy_repo_cache'
lever['image'] = 'lever/derbyjs'
lever['repository'] = 'https://github.com/enjalot/cypher.git'
lever['services'] = ['derbyjs/mongo', 'derbyjs/redis', 'derbyjs/cypher']
lever['repo_name'] = 'cypher'



# Build/deploy tasks
@task
def tag(tag=None):
    '''Tag the current HEAD, pushes tags to origin'''
    if tag is None:
        tag = prompt('Enter a tag:')

    # Cleanup tag
    tag.replace(' ', '_')
    tag.replace("'", '')

    lever['deploy_tag'] = tag

    with settings(warn_only=True):
        local('git tag %s' % (tag))
    # TODO don't repush if tag exists
    local('git push origin --tags')


def initctl(action=None, service=None):
    '''Control upstart services'''
    if action not in ['start', 'stop', 'status']:
        print "Must provide a valid action to initctl() (start, stop, status)"
        sys.exit(1)

    if service is None:
        services = lever['services']
    else:
        services = [service]

    for svc in services:
        sudo('%s %s' % (action, svc), warn_only=True)


@task
def start():
    '''Start cypher AND dependent services (redis, mongo)'''
    initctl('start')


@task
def stop():
    '''Stop cypher AND dependent services (redis, mongo)'''
    initctl('stop')


@task
def deploy(tag=None):
    '''Pull latest master from origin, build new docker image, restart cypher services'''
    if tag is None:
        if 'deploy_tag' not in lever:
            error("Must supply a tag to deploy. Use the tag task to build and select a tag, or 'deploy:<tag>'")
        else:
            tag = lever['deploy_tag']
    # TODO Start redis/mongo services if not running
    if not exists('%s/%s' % (lever['repo_cache'], lever['repo_name'])):
        execute(clone)
    with cd('%s/%s' % (lever['repo_cache'], lever['repo_name'])):
        run('git fetch')
        run('git reset --hard %s' % tag)
        run('docker build -t derbyjs/cypher .')
    sleep(2)

    # Ensure dependent services running
    execute(start)

    # Restart app
    sudo('stop derbyjs/cypher', warn_only=True)
    sudo('start derbyjs/cypher')


def clone():
    if not exists(lever['repo_cache']):
        run('mkdir %s' % lever['repo_cache'])
    with cd(lever['repo_cache']):
        run('git clone %s' % lever['repository'])
