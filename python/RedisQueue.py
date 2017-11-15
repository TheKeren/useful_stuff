#!/usr/bin/python

from subprocess import Popen, check_output, PIPE
import argparse, time, pickle

class Service:

    def __init__(self, name):
        self.name = name

    def check_pid(self):
        cmd = ["""ps aux | grep """ + self.name + """ | grep -v grep | awk '{print $2}'"""]
        pid = check_output(cmd,shell=True).strip()
        if not pid:
            return False
        else:
            return pid

    def restart(self):
        pid = (Service.check_pid(self))
        restart = Popen(["service", self.name, "restart"], stdout=PIPE)
        restart.communicate()
        new_pid = (Service.check_pid(self))
        if pid == new_pid or new_pid == False:
            return False
        else:
            return True

    def kill_process(self):
        pid = (Service.check_pid(self))
        kill = Popen(["kill", pid], stdout=PIPE)
        kill.communicate()
        if (Service.check_pid(self)) != False:
            print "kill failed, trying kill -9"
            kill9 = Popen(["kill", "-9", pid], stdout=PIPE)
            kill9.communicate()
            time.sleep(0.3)
            if (Service.check_pid(self)) != False:
                return False
            else:
                return True

class Redis_queue:

    def __init__(self, name, threshold):
        self.name = name
        self.threshold = int(threshold)

    def is_queue_sad(self):
        try:
            out = Popen(["redis-cli", "llen", self.name], stdout=PIPE)
            self.length = int(out.stdout.read().strip()) 
        except:
            raise
        if self.length > self.threshold:
            return self.length
        else:
            return False

def main():
    parser = argparse.ArgumentParser(description='Checks the status of a redis queue')
    parser.add_argument("-qn", "--queueName", type=str, help="name of a redis queue")
    parser.add_argument("-qt", "--queueThreshold", type=int, help="test threshold for the redis queue")
    parser.add_argument("-rl", "--restartLogstash", action="store_true", help="will trigger a logstash restart")
    args = parser.parse_args()

    if args.queueName is not None:
        if len([x for x in (args.queueName, args.queueThreshold) if x is not None]) == 1:
            parser.error('--queueName and --queueThreshold must be given together')
        queue = Redis_queue(args.queueName, args.queueThreshold)
        if (queue.is_queue_sad()) is not False:
            elapsed_time = elapsed_time()
            if elapsed_time is False or elapsed_time >= 43200:
                timestamp()
                if restart_logstash() is False:
                    print "Redis queue is %d, Failed to restart logstash" % (queue.length)
            else:
                print "Redis queue is %d, already restarted logstash" % (queue.length)
        else:
            print "OK"

    if args.restartLogstash:
        restart_logstash()

def restart_logstash():
    logstash = Service('logstash')
    if (logstash.restart_service()) == False:
        print "Failed restarting logstash, will attempt to kill process and restart"
        if (logstash.kill_process()) == True:
            logstash.restart()
        else:
            return False

def timestamp():
    with open("timestamp.txt", 'w') as timestamp:
        pickle.dump(time.time(),timestamp)

def elapsed_time():
    try:
        with open("timestamp.txt", 'r') as timestamp:
            last_timestamp = pickle.load(timestamp)
        elapsed_time = time.time() - last_timestamp 
        return elapsed_time
    except IOError:
        return False
        
if __name__ == "__main__":
    main()

