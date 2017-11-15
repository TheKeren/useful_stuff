#!/usr/bin/python3.5

"""
Tests and fixes tracks on gluster, read the README.md file for more info.
"""

import os
import re
import asyncio
import threading
import argparse
import math
from datetime import datetime
from subprocess import run
from time import sleep
import queue
import paramiko
from aiohttp import ClientSession

class BrokenTrack(object):
    """Defines a broken track object"""

    def __init__(self, track_id, track_path, track_url):
        self.lock = threading.Lock()
        self.id = track_id
        self.path = track_path
        self.url = track_url
        self.tmp_file = False
        self.fixed = ''

    @staticmethod
    def run_root_command(hostname, command):
        """Runs a command via ssh as superuser"""
        ops_user = (os.environ['OPS_USER'])
        ops_password = (os.environ['OPS_PASSWD'])
        ops_ssh = paramiko.SSHClient()
        ops_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ops_ssh.connect(hostname, username=ops_user, password=ops_password)
        stdin = ops_ssh.exec_command("sudo -Sk " + command)
        stdin.write(ops_password + '\n')
        stdin.flush()
        sleep(0.2)
        ops_ssh.close()

    def delete_track(self, sftp, host):
        """Takes a brick node and a list of broken track objects, for each track looks for the track on
        each brick looking for the good file, when good file is found a local tmp file will be created
        and the track.temp_file will be updated, all files (good and bad) are removed from the brick"""
        for brick_id in range(5):
            track_brick_path = '/export/brick00' + str(brick_id) + '/' + self.path
            if self.tmp_file is False:
                try:
                    file_info = sftp.stat(track_brick_path)
                except PermissionError:
                    chown_file = 'chown www-data:www-data ' + track_brick_path
                    BrokenTrack.run_root_command(host, chown_file)
                    file_info = sftp.stat(track_brick_path)
                except FileNotFoundError:
                    continue
                if file_info.st_size == 0:
                    sftp.remove(track_brick_path)
                else:
                    local_path = '/tmp/' + self.id + '.tmp'
                    try:
                        sftp.get(track_brick_path, local_path)
                        sftp.remove(track_brick_path)
                        with self.lock:
                            self.tmp_file = local_path
                    except IOError:
                        sleep(0.5)
                        try:
                            sftp.get(track_brick_path, local_path)
                            sftp.remove(track_brick_path)
                            with self.lock:
                                self.tmp_file = local_path
                        except:
                            raise
                    except:
                        raise
            else:
                try:
                    sftp.remove(track_brick_path)
                except PermissionError:
                    delete_file = 'rm -f ' + track_brick_path
                    BrokenTrack.run_root_command(host, delete_file)
                except FileNotFoundError:
                    continue

    def fix_track(self, sftp, gluster_volume, host):
        """Requires a gluster volume a list of broken track objects and an sftp connection,
        for each track, deletes the track from the volume and recreates it from the temp file"""
        if self.tmp_file is not False:
            track_srv_path = "/srv/" + gluster_volume + "/hms" + self.path.split('hms')[1]
            try:
                sftp.remove(track_srv_path)
            except PermissionError:
                delete_file = 'rm -f ' + track_srv_path
                BrokenTrack.run_root_command(host, delete_file)
            except FileNotFoundError:
                pass
            try:
                sftp.put(self.tmp_file, track_srv_path, confirm=True)
                sftp.chmod(track_srv_path, 0o664)
                sftp.chown(track_srv_path, 33, 33)
                os.remove(self.tmp_file)
                self.fixed = True
            except:
                self.fixed = False

async def test_500(url, session):
    '''async head request testing if the track is broken (return 404 or 500)'''
    async with session.head(url, timeout=None) as response:
        if response.status == 500:
            return [url.split('track/')[1].replace("/format/", "-"), url]
        elif response.status == 404:
            return ['MISSING', url.split('track/')[1].replace("/format/", "-")]
        else:
            return False

async def test_200(url, session):
    '''async head request testing if the the track is ok (return 200)'''
    async with session.head(url, timeout=None) as response:
        if response.status != 200:
            return url.split('track/')[1].replace("/format/", "-")
        else:
            return False

async def create_futures(urls, out_queue, test):
    '''Creates the aiohttp session and calls test_url'''
    tasks = []
    headers = {'from': 'keren.asulin@7digital.com'}
    sema = asyncio.Semaphore(3000)
    async with ClientSession(read_timeout=None, headers=headers) as session:
        async with sema:
            if test == 500:
                for url in urls:
                    task = asyncio.ensure_future(test_500(url, session))
                    tasks.append(task)
            else:
                for url in urls:
                    task = asyncio.ensure_future(test_200(url, session))
                    tasks.append(task)

        responses = await asyncio.gather(*tasks)
        if out_queue is False:
            return [id for id in responses if id is not False]
        else:
            out_queue.put([id for id in responses if id is not False])
            print(out_queue.qsize())

def test_urls(urls, out_queue=False, test=500):
    '''Wrapper function that calls the async functions and runs the io loop '''
    print('started_loop', datetime.now())
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    futures = asyncio.ensure_future(create_futures(urls, out_queue, test))
    if out_queue is False:
        return loop.run_until_complete(futures)
    else:
        loop.run_until_complete(futures)

def cut_down_logfile(server, local_nginx_log, filtered_log):
    '''copy the log file from a read node and greps all relevant lines into a temp file'''
    print('getting log file', datetime.now())
    nginx_log_file = "/var/log/nginx/error.log.1"
    sftp = open_sftp(server)
    sftp.get(nginx_log_file, local_nginx_log)
    sftp.close()
    with open(filtered_log, 'a') as logfile:
        run(["grep", "\[error\].*Permission denied", local_nginx_log], stdout=logfile)

def open_sftp(hostname):
    """Opens sftp connection as www-data user"""
    www_user = (os.environ['WWW_USER'])
    www_password = (os.environ['WWW_PASSWD'])
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=www_user, password=www_password)
    sftp = ssh.open_sftp()
    sftp.sshclient = ssh
    return sftp

def farm_log_file(local_logfile):
    '''Runs over the condensed log file, creates a dictonary of: $TRACK-ID-$TRACK-FORMAT:$TRACKPATH
    and a list of urls, calls create_futures which returns a list of broken tracks IDs then creates
    a list of track objects using the broken tracks IDs and paths from the dictonary and returns it'''
    track_dic = {}
    track_urls = []
    track_object_list = []
    media_deliver = "http://media-deliverfile.prod.svc.7d"
    with open(local_logfile, 'r') as logfile:
        for line in logfile:
            track_path = tuple(filter(None, re.findall(r'/srv/gv01/(.*?)"|/srv/(.*?)"', line)[0]))[0]
            track_url = re.findall(r'/track/[0-9]*/format/[0-9]*', line)[0]
            track_id = track_url.split('track/')[1].replace("/format/", "-")
            track_dic[track_id] = track_path
            track_urls.append(media_deliver + track_url)
    print(len(set(track_urls)))
    broken_tracks = test_urls(set(track_urls))
    print('ended_loop', datetime.now())
    for track_id in broken_tracks:
        if track_id[0] != 'MISSING':
            track_object_list.append(BrokenTrack(track_id[0], track_dic[track_id[0]], track_id[1]))
    return track_object_list

def farm_file(trackFile):
    '''Runs over ID file and returns broken tracks objects for the broken tracks'''
    media_deliver = "http://media-deliverfile.prod.svc.7d"
    result_queue = queue.Queue()
    track_dic = {'gv01':{'brick_path':'hms/track/',
                         'track_urls':[],
                         'object_list':[],
                         'missing_tracks':[]},
                 'gv02':{'brick_path':'gv02/hms/track/',
                         'track_urls':[],
                         'object_list':[],
                         'missing_tracks':[]}
                }
    with open(trackFile, 'r') as trackFile:
        for line in trackFile:
            info = line.rstrip('\n').split('-')
            track_url = media_deliver + '/track/' + info[1] + '/format/' + info[2]
            if info[0] == '888':
                track_dic['gv02']['track_urls'].append(track_url)
            elif info[0] == '777':
                track_dic['gv01']['track_urls'].append(track_url)
    for gv in track_dic:
        urls_num = len(track_dic[gv]['track_urls'])
        print("list len: ", urls_num)
        if urls_num is not 0:
            broken_tracks = []
            split_list = [track_dic[gv]['track_urls'][i:(i+urls_num//5)] for i in range(0, urls_num, urls_num//5)]
            threads = [threading.Thread(target=test_urls, args=(track_list, result_queue)) for track_list in split_list]
            for t in threads:
                t.start()
            for t in threads:
                t.join()
            print('final q length', result_queue.qsize())
            while not result_queue.empty():
                broken_tracks.extend(result_queue.get())
            for track_info in broken_tracks:
                if track_info[0] == 'MISSING':
                    track_dic[gv]['missing_tracks'].append(track_info[1])
                else:
                    split_track_id = track_info[0].split('-')
                    padded_track_id = iter(split_track_id[0].zfill(12))
                    trackID_path_constract = '/'.join(a + b + c for a, b, c
                                                      in zip(padded_track_id, padded_track_id, padded_track_id))
                    track_path = track_dic[gv]['brick_path'] + trackID_path_constract + '/' + split_track_id[1]
                    track_dic[gv]['object_list'].append(BrokenTrack(track_info[0], track_path, track_info[1]))
            print('broken tracks:', len(track_dic[gv]['object_list']))
        del track_dic[gv]['track_urls']
        del track_dic[gv]['brick_path']
    return track_dic

def remove_tracks_from_brick(bad_tracks, host):
    '''wrapper function to be used by threads'''
    print('remove tracks', datetime.now())
    sftp = open_sftp(host)
    for track in bad_tracks:
        track.delete_track(sftp, host)
    sftp.close()

def return_tracks_to_gluster(bad_tracks, gv, host):
    '''wrapper function to be used by threads'''
    print('fix tracks ', host, datetime.now())
    sftp = open_sftp(host)
    try:
        sftp.stat("/srv/" + gv + "/hms/track/")
    except FileNotFoundError:
        BrokenTrack.run_root_command(host, 'mount -a')
        sleep(3)
        try:
            sftp.stat("/srv/" + gv + "/hms/track/")
        except:
            raise
    for track in bad_tracks:
        track.fix_track(sftp, gv, host)
    sftp.close()

def main():
    """Main function, here we supply all gluster info and call other functions"""
    info_by_volume = {'gv01':{'read_nodes':['prod-hms01.nix.sys.7d', 'prod-hms02.nix.sys.7d'],
                              'brick_nodes':['ofc-prod-hms-a00.nix.sys.7d', 'ofc-prod-hms-a01.nix.sys.7d',
                                             'ofc-prod-hms-a02.nix.sys.7d', 'ofc-prod-hms-b00.nix.sys.7d',
                                             'ofc-prod-hms-b01.nix.sys.7d', 'gs2-prod-hms-A00.nix.sys.7d',
                                             'gs2-prod-hms-A01.nix.sys.7d', 'gs2-prod-hms-a02.nix.sys.7d',
                                             'ctr-prod-hms-B00.nix.sys.7d', 'ctr-prod-hms-b01.nix.sys.7d']},
                      'gv02':{'read_nodes':['prod-hms03.nix.sys.7d', 'prod-hms04.nix.sys.7d'],
                              'brick_nodes':['ofc-prod-hms-c00.nix.sys.7d', 'ofc-prod-hms-c01.nix.sys.7d',
                                             'ofc-prod-hms-d00.nix.sys.7d', 'ctr-prod-hms-d01.nix.sys.7d',
                                             'gs2-prod-hms-c00.nix.sys.7d', 'gs2-prod-hms-c01.nix.sys.7d',
                                             'ctr-prod-hms-d00.nix.sys.7d']}
                     }

    parser = argparse.ArgumentParser(description='Tests tracks on gluster for "split brain" issue and fixes them')
    parser.add_argument("-f", "--file", type=str, help="path to a file in format glusterVolume-trackID-trackFormat")
    args = parser.parse_args()

    if args.file is not None:
        broken_tracks_dic = farm_file(args.file)
        for gv in info_by_volume:
            info_by_volume[gv]['broken_tracks'] = broken_tracks_dic[gv]['object_list']
            if broken_tracks_dic[gv]['missing_tracks'] is not 0:
                with open(gv + '_missing_tracks.txt', 'a') as missing_tracks_file:
                    missing_tracks_file.write('\n'.join(broken_tracks_dic[gv]['missing_tracks']) + '\n')
    else:
        for gv in info_by_volume:
            for read_node in info_by_volume[gv]['read_nodes']:
                cut_down_logfile(read_node, '/tmp/read_node_ngnix.log', '/tmp/filtered_log_file.tmp')
            info_by_volume[gv]['broken_tracks'] = farm_log_file('/tmp/filtered_log_file.tmp')
            os.remove('/tmp/filtered_log_file.tmp')
        os.remove('/tmp/read_node_ngnix.log')

    for gv in info_by_volume:
        if len(info_by_volume[gv]['broken_tracks']) is 0:
            print('no broken tracks in ', gv)
        else:
            threads = [threading.Thread(target=remove_tracks_from_brick, args=(info_by_volume[gv]['broken_tracks'],    \
                       brick_node)) for brick_node in info_by_volume[gv]['brick_nodes']]
            for t in threads:
                t.start()
            for t in threads:
                t.join()
            threads_num = len(info_by_volume[gv]['brick_nodes'])
            tracks_num = len(info_by_volume[gv]['broken_tracks'])
            split_list = [info_by_volume[gv]['broken_tracks'][i:(i+math.ceil(tracks_num/threads_num))]
                          for i in range(0, tracks_num, math.ceil((tracks_num/threads_num)))]
            threads = [threading.Thread(target=return_tracks_to_gluster, args=(track_list, gv,    \
                       info_by_volume[gv]['brick_nodes'][index])) for index, track_list in enumerate(split_list)]
            for t in threads:
                t.start()
            for t in threads:
                t.join()

            failed_tracks = test_urls([track.url for track    \
                                      in info_by_volume[gv]['broken_tracks'] if track.fixed is True], test=200)

            with open(gv + '_missing_tracks.txt', 'a') as missing_tracks_file,    \
                 open(gv + '_fixed_tracks.txt', 'a') as fixed_tracks_file,        \
                 open(gv + '_failed_tracks.txt', 'a') as failed_tracks_file:
                for track in info_by_volume[gv]['broken_tracks']:
                    if track.fixed is not True and track.tmp_file is False:
                        missing_tracks_file.write('%s\n' % (track.id))
                    elif track.fixed is not True or track.id in failed_tracks:
                        failed_tracks_file.write('%s, %s, %s\n' % (track.id, track.tmp_file, track.url))
                    elif track.fixed is True:
                        fixed_tracks_file.write('%s, %s\n' % (track.id, track.url))

    if args.file is not None:
        os.rename(args.file, args.file + '.done')

if __name__ == "__main__":
    main()
