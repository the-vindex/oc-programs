#!/bin/bash
/usr/bin/find . -type f | grep -v .git | grep -v luassert |grep -v ".sh" | grep -v contents | grep -v ".bat" | grep -v testlibs | grep -v say.lua |\
sed 's_.*_os.execute\(\"wget -f -q http://192.168.0.101:8000/oc2/&\"\)_' > contents