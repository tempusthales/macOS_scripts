#!/bin/sh

# AD_Password_Expire_Date_Check.sh
# This looks up the password expiration date from AD. It's stored # in a numerical format that we have to convert.
# Run in Terminal with 'sudo sh /PathToScript <ADusername>'

# This is a tool, if you want an integrated soludion check out NoMAD at https://nomad.menu

xWin=$(/usr/bin/dscl localhost read /Search/Users/$1 msDS-UserPasswordExpiryTimeComputed 2>/dev/null | /usr/bin/awk '/dsAttrTypeNative/{print $NF}')

# This converts the MS date to a Unix date.
xUnix=$(echo "($xWin/10000000)-11644473600" | /usr/bin/bc)

# This gives us a human-readable expiration date.
xDate=$(/bin/date -r $xUnix)

echo $xDate

exit