#!/usr/bin/python

import argparse
from subprocess import Popen

parser = argparse.ArgumentParser(description='Deletes tracks from google cloud. How to run: pipe output into "gsutil -m rm -I" i.e "gc_del_track.py /tmp/delete-test-mqa.txt | gsutil -m rm -I"')
parser.add_argument('file', type=str, help='path to a file in format trackID-trackFormat')
args = parser.parse_args()

with open(args.file, 'r') as inputfile:
    for line in inputfile:
        split_id = line.rstrip('\n').split('-')
        padded_track_id = iter(split_id[0].zfill(12))
        p_track_path = '/'.join(a + b + c for a, b, c in zip(padded_track_id, padded_track_id, padded_track_id))
        final_path = 'gs://eu_standard_mediapool2000/track/' + p_track_path + '/' + split_id[1]
        print(final_path)
#        p1 = Popen(["/home/keren/workspace/google-cloud-sdk/bin/gsutil", "rm", final_path])
#        output = p1.communicate()
