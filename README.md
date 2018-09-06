# Palo Alto initial config

## Requirements

Script is using perl Net::OpenSSH module.   
MacOS install:
```
 sudo perl -MCPAN -e 'install Net::OpenSSH'
```
## Usage
```
$ perl PaloAltoInitialConfig.pl --user admin --host localhost.com --config sample-config.txt --checkHost no
```
