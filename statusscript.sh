#!/bin/bash
#
#Write shell script that does the following in sequence (on a *nix box)
# 1) checkout code from github into folder /home/testuser/mycode
# 2) Assume there is a config.json file in the source code with a JSON structure {user: , api_key: '1234' , conn_string: , ip_address: }. Also assume that the values for the keys in this JSON come from variables $user,$api_key and so on. Assign these variables to the values of corresponding JSON keys ONLY if the value is empty string. So the config.json should now be populated with values [This step needn.t necessarily be in shell script, assume you have /usr/bin/ruby OR /usr/bin/python OR /usr/bin/java OR /usr/bin/node in PATH]
# 3) Change the ownership for all files on /home/testuser/mycode to username 'testuser'.
# 4) Now archive this folder (.tar.gz), checksum and scp the archive to another machine that has dns 'remote.test.com' (in location /home/testuser/remotecode) . Assume that 'testuser' is part of sshlogin group on remote.test.com
# 5) Stop the service with name 'node'
# 6) Move the archive to /user/node/data and unarchive the contents
# 7) Start the service with name 'node'
# 8) Check that the end point 'http://remote.test.com/status' returns code 200
#

# NOTES:
#   - The remote Github repo is here: https://github.com/kalikikarthik/inmar_test.git
#   - The actual service is a mocked up HTTP server using Python.
#   - The execution server is Ubuntu and the destination server is Ubuntu.
#   - Both servers have a 'testuser' account and the SSH keys are setup from exection --> destination.
#   - Both also have the prereqs installed: curl, python, git.
#   - 'remote.test.com' is added to /etc/hosts on execution server.
#   - There are two files within the repo that must be setup on the destination server for it to work right:
#       + init.d.node --> /etc/init.d/node
#       + sudoers.d.testuser --> /etc/sudoers.d/testuser


REPO=https://github.com/kalikikarthik/mycode.git
DEST=/home/testuser/mycode
OWNER=testuser
TARFILE="${DEST}.tgz"
REMOTE_USER=testuser
REMOTE_HOST=remote.test.com
REMOTE_DEST=/home/testuser/remotecode
REMOTE_EXTRACT_DIR=/user/node/data
ENDPOINT="http://remote.test.com/status"

# On any uncaught errors, die.
set -e

# Prerequisites - git, python and curl
which git >/dev/null 2>&1
which python >/dev/null 2>&1
which curl >/dev/null 2>&1

# Cleanup if the repo already exists.
[[ -d $DEST ]] && /bin/rm -rf $DEST

# checkout code from github into folder /home/testuser/mycode
git clone $REPO $DEST

# Move to the destination and update the config.json file with environment vars as needed.
cd $DEST
python update-config.py

# Change the ownership for all files on /home/testuser/mycode to username 'testuser'
chown -R "${OWNER}:" $DEST

# Now archive this folder (.tar.gz)
# TODO: This archives the .git folder too.  May not be desirable.
tar zcf $TARFILE .

# checksum
# Using ancient 'cksum' following the letter of the "law", but it's easy to replace
# with md5sum, sha1sum, etc.  Also to collect just the checksum and not size/filename.
CKSUM=$(cksum $TARFILE)
echo "Checksum of $TARFILE: $CKSUM"

# Calling individual remote commands via SSH isn't exactly "production quality", but it
# does keep the complexity down!  :)

# Ensure that the destination exists.
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DEST"

# and scp the archive to another machine that has dns .remote.test.com. (in location /home/testuser/remotecode) . Assume that .testuser. is part of sshlogin group on remote.test.com
scp $TARFILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_DEST

# Stop the service with name .node.
ssh $REMOTE_USER@$REMOTE_HOST "sudo /usr/sbin/service node stop"

# Move the archive to /user/node/data
ssh $REMOTE_USER@$REMOTE_HOST "/bin/mv -f ${REMOTE_DEST}/mycode.tgz $REMOTE_EXTRACT_DIR"
# and unarchive the contents
# Note that the 'm' option to tar avoids an ugly 'Cannot utime: Operation not permitted' error.
ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_EXTRACT_DIR && tar zmxf mycode.tgz"
# Start the service with name .node.
ssh $REMOTE_USER@$REMOTE_HOST "sudo /usr/sbin/service node start"

# Check that the end point .http://remote.test.com/status. returns code 200
# TODO: Timeout loop versus quick sleep.
sleep 1
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" $ENDPOINT)
echo "Endpoint status code: $STATUS_CODE"

# And let's give a nice exit code if all is well.
[[ "$STATUS_CODE" == "200" ]] && exit 0 || exit 1
