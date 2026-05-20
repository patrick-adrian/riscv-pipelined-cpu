from __future__ import division
from io import TextIOWrapper
import random
from datetime import datetime
from typing import List, Optional
from scipy import stats
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import argparse

REQUEST_MESSAGES = [
    'Route request.',
    'Subscribe request.',
    'Upstream route recieved',
    'Retry route request.',
    'Clear request',
    'Begin mutation. Mutation [ROUTE_SRC]',
    'Begin mutation. Mutation [ROUTE_SUB]'
]

COMPLETE_MESSAGES = [
    'Complete',
    'End mutation. Mutation [ROUTE_SRC]',
    'End mutation. Mutation [ROUTE_SUB]'
]

#argparse is a Python class used to create a CLI for script
#defining arguments and options for your program
#allowing easier user interaction
def parse_commandline():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'log_file',
        help='Log file to read route times from',
    )
    parser.add_argument(
        'threshold',
        help='Threshold time to flag route speeds '
        '(negative number for anything less than)',
    )
    parser.add_argument(
        '--sample-size',
        help='Random sample for route times',
    )
    parser.add_argument(
        '--commands',
        action='store_true',
        help='Use "Sending x commands" as the completion '
        'for a batch of requests',
    )
    parser.add_argument(
        '--rps',
        action='store_true',
        help='Simply print the average number of routes '
        'per second from the logfile',
    )
    return parser.parse_args()


#Type hint: indicates that function returns a list of strings (OPTIONAL)
def get_entries(

    #Concrete class to represent text-mode file object
    #i.e. with open("magrtrsrv.log", "r") as f:
    #f is text-mode file object
    f: TextIOWrapper,

    use_commands=False,
) -> List[str]:
    
    entries = []

    #Dict storing (request, completion line) 
    requests = {}

    last_command_requests = []

    #
    command_requests = {}

    #Current last request line
    last_req = None

    #Current last completion line
    last_comp = None


    lines = f.readlines()

    #For each line at nth index in the log
    for idx, line in enumerate(lines):

        #If any message in REQUEST_MESSAGES are in the current line
        if any([req in line for req in REQUEST_MESSAGES]):
            last_req = line

        #Else if any message in COMPLETE_MESSAGES are in the current line
        elif any([msg in line for msg in COMPLETE_MESSAGES]):

            #If there is no last_req, go to next line of the log
            if not last_req:
                continue

            #If you are not at the end of the log
            if idx < len(lines) - 1:

                #If the next line has a COMPLETE MESSAGE, go to next line
                if any([msg in lines[idx+1] for msg in COMPLETE_MESSAGES]):
                    continue

                last_comp = line

                #Append previous request line to last_command_requests
                last_command_requests.append(last_req)

                #Add to requests dictionary: last_req, last_comp
                requests[last_req] = last_comp
                
            else:

                #If you're at the end, don't check next line just add it to last_command_requests and requests dict
                last_comp = line
                last_command_requests.append(last_req)
                requests[last_req] = last_comp

        elif 'pool(s)' in line:

            #For each request in last_command_requests, add to command_requests dict: request, line
            for request in last_command_requests:
                command_requests[request] = line

            #Clear last_command_requests
            last_command_requests = []

    if not use_commands:
        for r, c in requests.items():
            if r is None or c is None:
                continue
            entries.append(r)
            entries.append(c)
    else:
        for r, c in command_requests.items():
            if r is None or c is None:
                continue
            entries.append(r)
            entries.append(c)
    return entries


def get_route_speeds(
    f1: str,
    threshold: int,
    sample_size: Optional[int] = None,
    use_commands: bool = False,
) -> None:
    
    
    results = {}
    request_time: Optional[datetime] = None
    if use_commands:
        complete = 'pool(s)'
    with open(f1) as fd:
        entries = get_entries(fd, use_commands=use_commands)

    for entry in entries:
        time = entry.split(' ')[0].split('T')[1]
        if '-' in time:
            time_segment = time.split('-')[0]
        elif '+' in time:
            time_segment = time.split('+')[0]
        else:
            raise Exception(f'Unexpected timestamp. [{entry}]')

        if not any([msg in entry for msg in COMPLETE_MESSAGES]):
            request_time = datetime.strptime(time_segment, "%H:%M:%S.%f")
        else:
            complete_time = datetime.strptime(time_segment, "%H:%M:%S.%f")
            if not request_time:
                continue
            total_time = complete_time - request_time
            f_total_time = abs(total_time.total_seconds())
            results[entry] = f_total_time

    route_times: List[float] = []
    high_route_times: List[str] = []
    times: List[str] = []
    routes: List[str] = []
    items = list(results.items())
    if sample_size:
        items = random.sample(results.items(), int(sample_size))
    for route, result in items:
        time = route.split()[0].split('T')[1]
        if '-' in time:
            times.append(
                route.split()[0].split('T')[0] + 'T' + time.split('-')[0]
            )
        elif '+' in time:
            times.append(
                route.split()[0].split('T')[0] + 'T' + time.split('+')[0]
            )
        route_times.append(float(result))
        routes.append(route)
        if float(result) >= float(threshold):
            high_route_times.append(
                'Time exceeded: [%s (s)] at [%s]' % (result, route),
            )

    route_date_and_time = zip(route_times, times, routes)
    data_mean, std = stats.tmean(route_times), stats.tstd(route_times)
    cut_off = std*3
    _, upper = data_mean - cut_off, data_mean + cut_off

    print('Total number of routes: [%s]' % len(items))
    print('Routes above or below threshold: [%s]' % len(high_route_times))
    print('Total Time: [%s (s)]' %
          (sum([float(time) for time in route_times])))
    print('Average time per route request: [%s (s)]' % data_mean)
    print('Route requests per second [%s]' % (1/data_mean))
    print('---')
    print('Percentage of routes below %s (s) threshold: %s' % (
        threshold,
        stats.percentileofscore(route_times, float(threshold), kind='mean'),
    ))
    for percentile in [50, 75, 90, 95, 99, 99.7, 99.9]:
        print('Route time at percentile [%s]: %s (s)' % (
            percentile,
            stats.scoreatpercentile(route_times, percentile),
        ))
    print('\n')

    print('Times above threshold')
    print('---')
    for time in high_route_times:
        print(time)
    print('\n')

    outliers = [(x, y, z)
                for x, y, z in route_date_and_time if x > upper]
    print('Total number of outliers: [%s]' % len(outliers))
    print('---')
    for route_time, time, route in outliers:
        print('Outlier: [%s (s)] at [%s]' % (route_time, route))
    print('\n')

def main():
    options = parse_commandline()
    get_route_speeds(
        options.log_file,
        options.threshold,
        sample_size=options.sample_size,
        use_commands=options.commands,
    )


if __name__ == '__main__':
    main()
