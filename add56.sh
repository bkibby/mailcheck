#!/bin/sh

#
# Parses through files in the current directory named "acctnew.*" 
# and builds an account from the data within.  If your new users
# name is frank, then the file should be named  "acctnew.frank"
# 
# This script will rename the file to ADDED.acctnew.frank so it can't
# be run twice on the same user.
#

clear

PATH=/sbin:/etc:/bin:/usr/bin:/usr/sbin:/usr/local/bin
umask 077

# Let's start out fresh
if [ -f acct_new_pass  ]; then
  rm acct_new_pass
fi
if [ -f acct_new_uname  ]; then
  rm acct_new_uname
fi
if [ -f acct_new_shadow  ]; then
  rm acct_new_shadow
fi
if [ -f acct_new_users  ]; then
  rm acct_new_users
fi
if [ -f acct_new_aliases  ]; then
  rm acct_new_aliases
fi
if [ -f acct_new_homedir  ]; then
  rm acct_new_homedir
fi
if [ -f acct_new_forward ]; then
  rm acct_new_forward
fi

# have to have this guy installed on server!!!
if [ -x /usr/local/bin/nextuid ]; then
  nextid=`/usr/local/bin/nextuid`
else
  echo "ABORTING!!! /usr/local/bin/nextuid not found"
  exit 2
fi

# First, we parse through the acctnew.* file(s) and act according to
# each line of each file.
for LSFILE in `ls -t1 acctnew.*`; do
  awk '
  BEGIN { FS=":" }
  {
    split($0, f, ":")

    if (f[1] == "PASSWD")
	{
	# build a new passwd file entry this user.
	print f[2]":x:NEWUID:"f[5]":"f[6]":/home/CAPITOL/"f[2]":"f[8] > "acct_new_pass"
	print "/home/CAPITOL/"f[2] > "acct_new_homedir_tmp"
	print f[2] > "acct_new_uname"
	print "--------------------------------------------------"
	print "Establishing account for: " f[2]
        UNAME = f[2]
	}

    if (f[1] == "SHADOW")
	{
	# build a shadow file entry for this user.
	print f[2]":"f[3]":::::::" > "acct_new_shadow"
	}

    if (f[1] == "USERS")
	{
	# build a RADIUS users entry for this user.
        print "#" > "acct_new_users"
        print f[2]"\tPassword = "f[3] >> "acct_new_users"
        print "\tService-Type = Framed-User," >> "acct_new_users"
        print "\tFramed-Protocol = PPP," >> "acct_new_users"
        print "\tFramed-Routing = Listen," >> "acct_new_users"
        print "\tFramed-Compression = Stac-LZS," >> "acct_new_users"
        print "\tFramed-MTU = 552" >> "acct_new_users"
	}

    if (f[1] == "FORWARD")
	{
	# This user had mail forwarded to somewhere!
	print "MAIL  FORWARD  -> " f[2]
	print f[2] >> "acct_new_forward"
	}

    if (f[1] == "ALIASES")
	{
	# This user had an email alias!
	print "MAIL ALIASING  -> "f[3]
	print f[3] > "acct_new_aliases"
	}

  # end of this user
  }' < $LSFILE

  new_dir=`cat acct_new_uname`
  FOO=`echo $new_dir | tr a-z A-Z`

  # Build home directory string.
  CAPITOL=`echo $FOO | awk ' { printf "%s\n", substr($1,1,1) }'`

  sed s/CAPITOL/"$CAPITOL"/ acct_new_pass > acct_new_pass_tmp
  sed s/CAPITOL/"$CAPITOL"/ acct_new_homedir_tmp > acct_new_homedir
  sed s/NEWUID/"$nextid"/ acct_new_pass_tmp > acct_new_pass
  rm acct_new_pass_tmp
  rm acct_new_homedir_tmp

  # Now we are done building strings, lets put them to work.
  UNAME=`cat acct_new_uname`

  if [ -f /var/spool/mail/$UNAME ]; then
    # We already found this user, let's not screw up someone else's day!
    echo $UNAME already on this machine - process manually!
    rm acct_new_*
    echo "--------------------------------------------------"
  else
    # Create the account entries
    # First, a passwd/shadow entry
    cat acct_new_pass >> /etc/passwd
    cat acct_new_shadow >> /etc/shadow

    # Giv'em a mail file
    touch /var/spool/mail/"$UNAME"
    chown "$UNAME" /var/spool/mail/"$UNAME"

    # now for their home...
    homedir=`cat acct_new_homedir`
    mkdir "$homedir"
    cp /etc/skel/.* "$homedir"

    # maybe let them dial in?
    cp acct_new_users /etc/raddb/users_buildacct
    cat /etc/raddb/users >> /etc/raddb/users_buildacct
    cp /etc/raddb/users /etc/raddb/users-bak-buildacct
    mv /etc/raddb/users_buildacct /etc/raddb/users

    # If they have an alias, see if they want to keep it
    if [ -f acct_new_aliases ]; then
      ALIASNAME=`cat acct_new_aliases`
      echo -n "Do you want to ALIAS $UNAME to $ALIASNAME? (y/N):"
      read FOO
      case "$FOO" in
        y|Y)
	  echo "$UNAME:		$ALIASNAME" >> /etc/mail/aliases
          newaliases
          ;;
          *)
          ;;
      esac
    fi

    # If they have a FORWARD, see if they want to keep it
    if [ -f acct_new_forward ]; then
      FORWARD=`cat acct_new_forward`
      echo -n "Do you want to FORWARD $UNAME to $FORWARD? (y/N):"
      read FOO
      case "$FOO" in
        y|Y)
	  echo "$FORWARD" > "$homedir"/.forward
          chmod 744 "$homedir"/.forward
          ;;
          *)
          ;;
      esac
    fi

    # Give all in homedir to original user
    chown -R "$UNAME" "$homedir"
    echo "--------------------------------------------------"

    # Let's clean up after ourselves
    if [ -f acct_new_pass  ]; then
      rm acct_new_pass
    fi
    if [ -f acct_new_uname  ]; then
      rm acct_new_uname
    fi
    if [ -f acct_new_shadow  ]; then
      rm acct_new_shadow
    fi
    if [ -f acct_new_users  ]; then
      rm acct_new_users
    fi
    if [ -f acct_new_aliases  ]; then
      rm acct_new_aliases
    fi
    if [ -f acct_new_homedir  ]; then
      rm acct_new_homedir
    fi
    if [ -f acct_new_forward ]; then
      rm acct_new_forward
    fi

  # end of not screwing up someone else's day :)
  fi
mv $LSFILE ADDED.$LSFILE
# end of file reached.
done


