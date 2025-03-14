# check-svn-config-syntax
This shell script is intended to check the syntax of svn access configuration file (svnaccess.conf for example).

# Usage

The script is accepts an svnaccess.conf file (or path to file) as input argument and sends a message to STDOUT whether it is valid or not.
It includes an example exapmle_svn_access.conf file with the typical access configuration structure. So you can check how it works.

```
git clone https://github.com/nekit360/check-svn-config-syntax.git
chmod +x validate_syntax.sh
./validate_syntax.sh exapmle_svn_access.conf
```
