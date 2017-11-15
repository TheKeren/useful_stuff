#!/usr/bin/python

import argparse
import textwrap

parser = argparse.ArgumentParser(description='generate env settings blocks for terraform')
parser.add_argument('file', type=str, help='a list of env variables for the EBS env')
args = parser.parse_args()

list1 = []
with open(args.file, 'r') as inputfile:
    for line in inputfile:
        list1.append(line.rstrip('\n'))

for var in list1:
    print textwrap.dedent("""\
        setting {
          namespace = "aws:elasticbeanstalk:application:environment"
          name      = "%s"
          value     = "${var.%s}"
        }
    """ % (var, var.lower()) )

